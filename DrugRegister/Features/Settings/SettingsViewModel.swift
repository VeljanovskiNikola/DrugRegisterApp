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
    /// What iOS allows. `nil` until checked.
    private(set) var permission: ReminderPermission?

    private let service: any DrugService
    private let medicines: MedicineServices

    init(service: any DrugService, medicines: MedicineServices) {
        self.service = service
        self.medicines = medicines
        remindersEnabled = medicines.settings.isEnabled
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
}
