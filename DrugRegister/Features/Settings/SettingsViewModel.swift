import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private(set) var meta: RegisterMeta?
    /// True when loading the dataset info failed. The screen then shows "Not available".
    private(set) var metaFailed = false

    /// The switch. Bound by the view, then applied with `applyReminderChoice()`.
    var remindersEnabled: Bool
    /// The time picker, as a `Date` because `DatePicker` needs one. Only hour and minute count.
    /// Bound by the view, then applied with `applyReminderTime()`.
    var reminderTime: Date
    /// What iOS allows. `nil` until checked.
    private(set) var permission: ReminderPermission?

    private let service: any DrugService
    private let medicines: MedicineServices

    init(service: any DrugService, medicines: MedicineServices) {
        self.service = service
        self.medicines = medicines
        remindersEnabled = medicines.settings.isEnabled
        let time = medicines.settings.time
        reminderTime = medicines.calendar.date(
            bySettingHour: time.hour,
            minute: time.minute,
            second: 0,
            of: medicines.now()
        ) ?? medicines.now()
    }

    /// "09:00", in the app's language, for the footer.
    var reminderTimeText: String {
        let calendar = medicines.calendar
        let style = Date.FormatStyle(date: .omitted, time: .shortened, locale: .app, calendar: calendar, timeZone: calendar.timeZone)
        return reminderTime.formatted(style)
    }

    /// On here, but iOS blocks notifications. The screen points to iOS Settings.
    var remindersBlocked: Bool {
        remindersEnabled && permission == .denied
    }

    func loadMeta() async {
        guard meta == nil else { return }
        metaFailed = false
        do {
            meta = try await service.meta()
        } catch {
            // Leaving the tab cancels the load. That is not a failure.
            guard !error.isCancellation else { return }
            metaFailed = true
        }
    }

    /// Checked again when the app becomes active, because the user may have changed it in iOS Settings.
    func refreshPermission() async {
        permission = await medicines.scheduler.permission()
    }

    /// Saves the switch and schedules or removes the reminders to match.
    func applyReminderChoice() async {
        medicines.settings.isEnabled = remindersEnabled
        if remindersEnabled, await medicines.scheduler.permission() == .notDetermined {
            _ = await medicines.scheduler.requestPermission()
        }
        await refreshPermission()
        await medicines.syncReminders()
    }

    /// Saves the picked time and moves every pending reminder to it.
    func applyReminderTime() async {
        let components = medicines.calendar.dateComponents([.hour, .minute], from: reminderTime)
        let time = ReminderTime(hour: components.hour ?? 0, minute: components.minute ?? 0)
        guard time != medicines.settings.time else { return }
        medicines.settings.time = time
        await medicines.syncReminders()
    }
}
