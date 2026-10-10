import Foundation

/// What the My medicines screens need, created once in `AppEnvironment`.
/// `now` and `calendar` are values, so tests choose the date and time zone.
struct MedicineServices: Sendable {
    let repository: any MedicineRepository
    let scheduler: any ReminderScheduler
    let settings: ReminderSettings
    let now: @Sendable () -> Date
    let calendar: Calendar

    init(
        repository: any MedicineRepository,
        scheduler: any ReminderScheduler,
        settings: ReminderSettings = ReminderSettings(),
        now: @escaping @Sendable () -> Date = { .now },
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.scheduler = scheduler
        self.settings = settings
        self.now = now
        self.calendar = calendar
    }

    var today: CalendarDay {
        CalendarDay(now(), calendar: calendar)
    }

    /// Plans reminders from what is saved now and hands them to the scheduler.
    /// Called after every change and when the app becomes active.
    /// If reading fails, the old reminders stay. That is better than removing them all.
    /// Turned off in Settings: the plan is empty, so every pending reminder is removed.
    func syncReminders() async {
        guard settings.isEnabled else {
            await scheduler.replaceAll(with: [])
            return
        }
        guard let medicines = try? await repository.all() else { return }
        let reminders = ReminderPlanner.reminders(for: medicines, now: now(), calendar: calendar)
        await scheduler.replaceAll(with: reminders)
    }
}
