import Foundation
import Testing
@testable import DrugRegister

@MainActor
struct ReminderSettingsTests {

    @Test
    func onUntilTheUserTurnsThemOff() {
        let settings = ReminderSettings.test()

        #expect(settings.isEnabled)

        settings.isEnabled = false
        #expect(settings.isEnabled == false)
    }

    @Test
    func timeIsNineUntilTheUserChangesIt() {
        let settings = ReminderSettings.test()

        #expect(settings.time == .standard)
        #expect(settings.time == ReminderTime(hour: 9, minute: 0))

        settings.time = ReminderTime(hour: 7, minute: 45)
        #expect(settings.time == ReminderTime(hour: 7, minute: 45))
    }

    @Test
    func badStoredTimeFallsBackToNine() {
        let settings = ReminderSettings.test()
        UserDefaults(suiteName: settings.suiteName)?.set(5000, forKey: settings.timeKey)

        #expect(settings.time == .standard)
    }

    @Test
    func minutesAfterMidnightRoundTrip() {
        #expect(ReminderTime(hour: 18, minute: 30).minutesAfterMidnight == 1110)
        #expect(ReminderTime(minutesAfterMidnight: 1110) == ReminderTime(hour: 18, minute: 30))
        #expect(ReminderTime(minutesAfterMidnight: -1) == nil)
        #expect(ReminderTime(minutesAfterMidnight: 1440) == nil)
    }

    @Test
    func syncUsesTheSavedTime() async {
        let scheduler = StubReminderScheduler()
        let settings = ReminderSettings.test()
        settings.time = ReminderTime(hour: 18, minute: 30)
        let services = makeServices(medicines: [.make(expiry: day(2027, 1, 31))], scheduler: scheduler, settings: settings)

        await services.syncReminders()

        let scheduled = await scheduler.scheduled
        #expect(scheduled.count == 3)
        #expect(scheduled.allSatisfy { $0.components.hour == 18 && $0.components.minute == 30 })
    }

    @Test
    func turnedOffSyncRemovesEveryReminder() async {
        let scheduler = StubReminderScheduler()
        let services = makeServices(
            medicines: [.make(expiry: day(2027, 1, 31))],
            scheduler: scheduler,
            settings: .test(enabled: false)
        )

        await services.syncReminders()

        #expect(await scheduler.scheduled.isEmpty)
        #expect(await scheduler.replaceCount == 1)
    }

    @Test
    func turnedOffSaveDoesNotAskForPermission() async {
        let scheduler = StubReminderScheduler(permission: .notDetermined)
        let form = MedicineFormViewModel(
            mode: .add(DrugSnapshot(.sample)),
            services: makeServices(scheduler: scheduler, settings: .test(enabled: false))
        )
        form.expiryMonth = 1
        form.expiryYear = 2027

        #expect(await form.save())

        #expect(await scheduler.permissionRequests == 0)
        #expect(await scheduler.scheduled.isEmpty)
    }
}
