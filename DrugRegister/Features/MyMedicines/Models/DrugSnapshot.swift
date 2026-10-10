import Foundation

/// The few drug fields a saved medicine keeps. The list works offline with them,
/// and still works if the drug is later removed from the register.
struct DrugSnapshot: Hashable, Codable, Sendable {
    let id: String
    let nameLatin: String
    let nameCyrillic: String
    let strength: String?
    let pharmaceuticalForm: String
    let detailUrl: URL

    init(id: String, nameLatin: String, nameCyrillic: String, strength: String?, pharmaceuticalForm: String, detailUrl: URL) {
        self.id = id
        self.nameLatin = nameLatin
        self.nameCyrillic = nameCyrillic
        self.strength = strength
        self.pharmaceuticalForm = pharmaceuticalForm
        self.detailUrl = detailUrl
    }

    init(_ drug: Drug) {
        self.init(
            id: drug.id,
            nameLatin: drug.nameLatin,
            nameCyrillic: drug.nameCyrillic,
            strength: drug.strength,
            pharmaceuticalForm: drug.pharmaceuticalForm,
            detailUrl: drug.detailUrl
        )
    }

    /// For example "5 mg · таблета".
    var strengthAndForm: String {
        [strength, pharmaceuticalForm].compactMap { $0 }.joined(separator: " · ")
    }
}
