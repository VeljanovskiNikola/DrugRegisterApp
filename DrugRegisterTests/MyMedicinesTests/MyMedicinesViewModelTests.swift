import Foundation
import Testing
@testable import DrugRegister

@MainActor
struct MyMedicinesViewModelTests {

    /// Today is 10 Oct 2026 in every test.
    private let expired = Medicine.make(expiry: day(2026, 9, 19))
    private let soon = Medicine.make(expiry: day(2026, 10, 22))
    private let later = Medicine.make(expiry: day(2028, 1, 31), isExactDay: false)

    @Test
    func loadGroupsBySoonestExpiry() async {
        let viewModel = MyMedicinesViewModel(services: makeServices(medicines: [later, soon, expired]))

        await viewModel.load()

        #expect(viewModel.hasLoaded)
        #expect(viewModel.sections.map(\.group) == [.expired, .within30Days, .later])
        #expect(viewModel.sections[0].entries.first?.daysLeft == -21)
        #expect(viewModel.summary == ExpirySummary(expired: 1, within30Days: 1))
    }

    @Test
    func groupsFollowTheInjectedClock() async {
        // Same medicine, a month later: it has expired.
        let viewModel = MyMedicinesViewModel(services: makeServices(medicines: [soon], now: moment(2026, 11, 10)))

        await viewModel.load()

        #expect(viewModel.sections.map(\.group) == [.expired])
    }

    @Test
    func deleteRemovesTheMedicineAndCancelsItsReminders() async throws {
        let repository = InMemoryMedicineRepository(medicines: [soon, later])
        let scheduler = StubReminderScheduler()
        let viewModel = MyMedicinesViewModel(services: makeServices(repository: repository, scheduler: scheduler))
        await viewModel.load()

        await viewModel.delete(later)

        #expect(viewModel.medicines == [soon])
        #expect(try await repository.all() == [soon])
        let scheduled = await scheduler.scheduled
        #expect(scheduled.isEmpty == false)
        #expect(scheduled.allSatisfy { $0.medicineID == soon.id })
    }

    @Test
    func failedDeleteKeepsTheMedicine() async {
        let viewModel = MyMedicinesViewModel(services: makeServices(repository: FailingMedicineRepository()))

        await viewModel.delete(soon)

        #expect(viewModel.errorMessage == String(localized: "The medicine could not be deleted."))
    }

    @Test
    func failedLoadShowsAnError() async {
        let viewModel = MyMedicinesViewModel(services: makeServices(repository: FailingMedicineRepository()))

        await viewModel.load()

        #expect(viewModel.errorMessage == String(localized: "Your medicines could not be loaded."))
        #expect(viewModel.medicines.isEmpty)
    }

    @Test
    func permissionWarningOnlyWhenDeniedAndThereIsSomethingToRemind() async {
        let denied = StubReminderScheduler(permission: .denied)

        let empty = MyMedicinesViewModel(services: makeServices(scheduler: denied))
        await empty.load()
        #expect(empty.showsPermissionWarning == false)

        let withMedicines = MyMedicinesViewModel(services: makeServices(medicines: [soon], scheduler: denied))
        await withMedicines.load()
        #expect(withMedicines.showsPermissionWarning)

        let allowed = MyMedicinesViewModel(services: makeServices(medicines: [soon]))
        await allowed.load()
        #expect(allowed.showsPermissionWarning == false)
    }
}
