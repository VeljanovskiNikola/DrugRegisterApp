import Foundation
import Testing
@testable import DrugRegister

/// A real SwiftData stack, kept in memory only.
struct MedicineRepositoryTests {

    private func makeMedicine(note: String = "", exact: Bool = true) -> Medicine {
        var medicine = Medicine.make(expiry: day(2027, 5, 31), isExactDay: exact, packCount: 2, note: note)
        medicine.openedOn = day(2026, 9, 1)
        return medicine
    }

    @Test
    func savedMedicineIsReadBackUnchanged() async throws {
        let repository = try SwiftDataMedicineRepository.inMemory()
        let exact = makeMedicine(note: "кутија во кујната")
        let monthOnly = makeMedicine(exact: false)

        try await repository.save(exact)
        try await repository.save(monthOnly)

        let all = try await repository.all()
        #expect(Set(all) == [exact, monthOnly])
    }

    @Test
    func savingTheSameIDUpdatesInsteadOfAddingACopy() async throws {
        let repository = try SwiftDataMedicineRepository.inMemory()
        var medicine = makeMedicine()
        try await repository.save(medicine)

        medicine.expiry = ExpiryDate(month: 8, year: 2028, calendar: .test)
        medicine.note = "edited"
        medicine.openedOn = nil
        try await repository.save(medicine)

        #expect(try await repository.all() == [medicine])
    }

    @Test
    func theSameDrugCanBeSavedTwice() async throws {
        let repository = try SwiftDataMedicineRepository.inMemory()

        try await repository.save(Medicine.make(expiry: day(2027, 1, 31)))
        try await repository.save(Medicine.make(expiry: day(2028, 1, 31)))

        let all = try await repository.all()
        #expect(all.count == 2)
        #expect(Set(all.map(\.drug.id)).count == 1)
    }

    @Test
    func deleteRemovesOnlyThatMedicine() async throws {
        let repository = try SwiftDataMedicineRepository.inMemory()
        let keep = makeMedicine()
        let remove = makeMedicine()
        try await repository.save(keep)
        try await repository.save(remove)

        try await repository.delete(id: remove.id)
        try await repository.delete(id: UUID())   // unknown id: nothing happens

        #expect(try await repository.all() == [keep])
    }
}
