import Foundation

/// Where saved medicines live. View models only know this protocol, so tests and
/// previews use `InMemoryMedicineRepository` and never touch SwiftData.
protocol MedicineRepository: Sendable {
    func all() async throws -> [Medicine]
    /// Inserts a new medicine or replaces the one with the same `id`.
    func save(_ medicine: Medicine) async throws
    func delete(id: UUID) async throws
}
