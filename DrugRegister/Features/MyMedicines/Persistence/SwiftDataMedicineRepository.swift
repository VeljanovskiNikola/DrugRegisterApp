import Foundation
import SwiftData

/// SwiftData behind an actor. `@ModelActor` gives the actor its own `ModelContext`,
/// so saving never blocks the main thread and no model object crosses actors.
@ModelActor
actor SwiftDataMedicineRepository: MedicineRepository {
    func all() throws -> [Medicine] {
        try modelContext.fetch(FetchDescriptor<MedicineRecord>()).map(\.medicine)
    }

    func save(_ medicine: Medicine) throws {
        if let record = try record(id: medicine.id) {
            record.update(from: medicine)
        } else {
            modelContext.insert(MedicineRecord(medicine))
        }
        try modelContext.save()
    }

    func delete(id: UUID) throws {
        if let record = try record(id: id) {
            modelContext.delete(record)
            try modelContext.save()
        }
    }

    private func record(id: UUID) throws -> MedicineRecord? {
        var descriptor = FetchDescriptor<MedicineRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

extension SwiftDataMedicineRepository {
    /// The store on disk. Falls back to memory only if the store cannot be opened,
    /// so the app still starts. Medicines are then lost when the app quits.
    static func live() -> any MedicineRepository {
        if let container = try? ModelContainer(for: MedicineRecord.self) {
            return SwiftDataMedicineRepository(modelContainer: container)
        }
        return InMemoryMedicineRepository()
    }

    /// For tests: a real SwiftData stack that keeps nothing on disk.
    static func inMemory() throws -> SwiftDataMedicineRepository {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: MedicineRecord.self, configurations: configuration)
        return SwiftDataMedicineRepository(modelContainer: container)
    }
}
