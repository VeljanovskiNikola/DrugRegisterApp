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
