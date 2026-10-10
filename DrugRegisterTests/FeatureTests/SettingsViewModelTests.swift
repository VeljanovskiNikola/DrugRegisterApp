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
