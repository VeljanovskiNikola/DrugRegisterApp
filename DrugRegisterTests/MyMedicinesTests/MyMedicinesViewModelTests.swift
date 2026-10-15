import Foundation
import Testing
@testable import DrugRegister

/// Loads and deletes, but every save fails. For an undo that cannot be saved.
private actor SaveFailingRepository: MedicineRepository {
    private var medicines: [Medicine]

    init(medicines: [Medicine]) {
        self.medicines = medicines
    }

    func all() -> [Medicine] { medicines }
    func save(_ medicine: Medicine) throws { throw RepositoryError() }
    func delete(id: UUID) { medicines.removeAll { $0.id == id } }
}

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
        #expect(viewModel.recentlyDeleted == nil)
    }

    // MARK: - Undo

    @Test
    func deleteOffersUndo() async {
        let viewModel = MyMedicinesViewModel(services: makeServices(medicines: [soon, later]))
        await viewModel.load()

        await viewModel.delete(later)

        #expect(viewModel.recentlyDeleted == later)
    }

    @Test
    func undoBringsThePackAndItsRemindersBack() async throws {
        let repository = InMemoryMedicineRepository(medicines: [soon, later])
        let scheduler = StubReminderScheduler()
        let viewModel = MyMedicinesViewModel(services: makeServices(repository: repository, scheduler: scheduler))
        await viewModel.load()
        await viewModel.delete(soon)

        await viewModel.undoDelete()

        #expect(viewModel.recentlyDeleted == nil)
        #expect(Set(viewModel.medicines) == [soon, later])
        // Same id and dates, so it is the same pack, not a new one.
        #expect(Set(try await repository.all()) == [soon, later])
        let scheduled = await scheduler.scheduled
        #expect(scheduled.contains { $0.medicineID == soon.id })
    }

    @Test
    func newerDeleteReplacesThePendingUndo() async throws {
        let repository = InMemoryMedicineRepository(medicines: [expired, soon, later])
        let viewModel = MyMedicinesViewModel(services: makeServices(repository: repository))
        await viewModel.load()

        await viewModel.delete(soon)
        await viewModel.delete(later)
        await viewModel.undoDelete()

        #expect(viewModel.medicines.map(\.id).sorted() == [expired.id, later.id].sorted())
        #expect(try await repository.all().contains(soon) == false)
    }

    @Test
    func dismissingUndoKeepsTheDelete() async throws {
        let repository = InMemoryMedicineRepository(medicines: [soon])
        let viewModel = MyMedicinesViewModel(services: makeServices(repository: repository))
        await viewModel.load()
        await viewModel.delete(soon)

        viewModel.dismissUndo()
        await viewModel.undoDelete()   // nothing left to undo

        #expect(viewModel.recentlyDeleted == nil)
        #expect(viewModel.medicines.isEmpty)
        #expect(try await repository.all().isEmpty)
    }

    @Test
    func failedUndoShowsAnError() async {
        let viewModel = MyMedicinesViewModel(services: makeServices(repository: SaveFailingRepository(medicines: [soon])))
        await viewModel.load()
        await viewModel.delete(soon)

        await viewModel.undoDelete()

        #expect(viewModel.errorMessage == String(localized: "The medicine could not be saved."))
        #expect(viewModel.medicines.isEmpty)
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
