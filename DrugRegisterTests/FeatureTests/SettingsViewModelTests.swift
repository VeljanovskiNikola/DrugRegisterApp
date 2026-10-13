import Foundation
import Testing
@testable import DrugRegister

@MainActor
struct SettingsViewModelTests {

    @Test
    func loadsDatasetInfo() async {
        let viewModel = SettingsViewModel(service: StubDrugService(), medicines: makeServices())

        await viewModel.loadMeta()

        #expect(viewModel.meta == .sample)
        #expect(viewModel.metaFailed == false)
    }

    @Test
    func failureIsShownAsNotAvailable() async {
        let viewModel = SettingsViewModel(
            service: StubDrugService(metaResult: .failure(URLError(.notConnectedToInternet))),
            medicines: makeServices()
        )

        await viewModel.loadMeta()

        #expect(viewModel.meta == nil)
        #expect(viewModel.metaFailed)
    }

    @Test
    func cancellationIsNotAFailure() async {
        let viewModel = SettingsViewModel(
            service: StubDrugService(metaResult: .failure(CancellationError())),
            medicines: makeServices()
        )

        await viewModel.loadMeta()

        #expect(viewModel.metaFailed == false)
    }

    // MARK: - Reminders

    @Test
    func switchStartsFromTheSavedChoice() {
        let on = SettingsViewModel(service: StubDrugService(), medicines: makeServices())
        let off = SettingsViewModel(
            service: StubDrugService(),
            medicines: makeServices(settings: .test(enabled: false))
        )

        #expect(on.remindersEnabled)
        #expect(off.remindersEnabled == false)
    }

    @Test
    func turningOffSavesTheChoiceAndRemovesReminders() async {
        let scheduler = StubReminderScheduler()
        let settings = ReminderSettings.test()
        let services = makeServices(
            medicines: [.make(expiry: day(2027, 1, 31))],
            scheduler: scheduler,
            settings: settings
        )
        await services.syncReminders()
        #expect(await scheduler.scheduled.count == 3)

        let viewModel = SettingsViewModel(service: StubDrugService(), medicines: services)
        viewModel.remindersEnabled = false
        await viewModel.applyReminderChoice()

        #expect(settings.isEnabled == false)
        #expect(await scheduler.scheduled.isEmpty)
    }

    @Test
    func timePickerStartsFromTheSavedTime() {
        let settings = ReminderSettings.test()
        settings.time = ReminderTime(hour: 7, minute: 45)
        let viewModel = SettingsViewModel(service: StubDrugService(), medicines: makeServices(settings: settings))

        let components = Calendar.test.dateComponents([.hour, .minute], from: viewModel.reminderTime)
        #expect(components.hour == 7)
        #expect(components.minute == 45)
    }

    @Test
    func changingTheTimeSavesItAndMovesTheReminders() async {
        let scheduler = StubReminderScheduler()
        let settings = ReminderSettings.test()
        let services = makeServices(
            medicines: [.make(expiry: day(2027, 1, 31))],
            scheduler: scheduler,
            settings: settings
        )
        let viewModel = SettingsViewModel(service: StubDrugService(), medicines: services)

        viewModel.reminderTime = Calendar.test.date(
            from: DateComponents(year: 2026, month: 10, day: 10, hour: 18, minute: 30)
        ) ?? .distantPast
        await viewModel.applyReminderTime()

        #expect(settings.time == ReminderTime(hour: 18, minute: 30))
        let scheduled = await scheduler.scheduled
        #expect(scheduled.count == 3)
        #expect(scheduled.allSatisfy { $0.components.hour == 18 && $0.components.minute == 30 })
    }

    @Test
    func sameTimeDoesNotReschedule() async {
        let scheduler = StubReminderScheduler()
        let viewModel = SettingsViewModel(
            service: StubDrugService(),
            medicines: makeServices(medicines: [.make(expiry: day(2027, 1, 31))], scheduler: scheduler)
        )

        await viewModel.applyReminderTime()   // still 09:00

        #expect(await scheduler.replaceCount == 0)
    }

    @Test
    func footerShowsTheChosenTime() {
        let settings = ReminderSettings.test()
        settings.time = ReminderTime(hour: 18, minute: 30)
        let viewModel = SettingsViewModel(service: StubDrugService(), medicines: makeServices(settings: settings))

        #expect(viewModel.reminderTimeText.contains("18"))
        #expect(viewModel.reminderTimeText.contains("30"))
    }

    @Test
    func turningOnAsksForPermissionAndSchedules() async {
        let scheduler = StubReminderScheduler(permission: .notDetermined)
        let settings = ReminderSettings.test(enabled: false)
        let services = makeServices(
            medicines: [.make(expiry: day(2027, 1, 31))],
            scheduler: scheduler,
            settings: settings
        )

        let viewModel = SettingsViewModel(service: StubDrugService(), medicines: services)
        viewModel.remindersEnabled = true
        await viewModel.applyReminderChoice()

        #expect(settings.isEnabled)
        #expect(await scheduler.permissionRequests == 1)
        #expect(viewModel.permission == .allowed)
        #expect(await scheduler.scheduled.count == 3)
    }

    @Test
    func turningOffNeverAsksForPermission() async {
        let scheduler = StubReminderScheduler(permission: .notDetermined)
        let viewModel = SettingsViewModel(
            service: StubDrugService(),
            medicines: makeServices(scheduler: scheduler)
        )

        viewModel.remindersEnabled = false
        await viewModel.applyReminderChoice()

        #expect(await scheduler.permissionRequests == 0)
    }

    @Test
    func blockedWhenOnButDeniedInIOS() async {
        let viewModel = SettingsViewModel(
            service: StubDrugService(),
            medicines: makeServices(scheduler: StubReminderScheduler(permission: .denied))
        )

        await viewModel.refreshPermission()
        #expect(viewModel.remindersBlocked)

        viewModel.remindersEnabled = false
        await viewModel.applyReminderChoice()
        #expect(viewModel.remindersBlocked == false)
    }
}
