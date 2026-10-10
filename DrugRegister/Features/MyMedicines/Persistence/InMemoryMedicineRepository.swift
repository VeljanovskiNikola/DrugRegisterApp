import Foundation

/// Keeps medicines in memory only. Used by previews and tests, and as a fallback
/// when the SwiftData store cannot be opened.
actor InMemoryMedicineRepository: MedicineRepository {
    private var medicines: [UUID: Medicine]

    init(medicines: [Medicine] = []) {
        self.medicines = Dictionary(uniqueKeysWithValues: medicines.map { ($0.id, $0) })
    }

    func all() -> [Medicine] {
        medicines.values.sorted { $0.createdAt < $1.createdAt }
    }

    func save(_ medicine: Medicine) {
        medicines[medicine.id] = medicine
    }

    func delete(id: UUID) {
        medicines[id] = nil
    }
}
