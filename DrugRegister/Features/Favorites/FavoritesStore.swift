import Foundation
import Observation

/// The drugs the user saved, kept as a JSON file on the device.
///
/// It stores the full drug, not only the ID, so Favorites works offline and needs no
/// request per drug. The copy is refreshed whenever the user opens that drug from search.
/// Add `DrugRepository` when the app keeps the whole register offline.
@MainActor
@Observable
final class FavoritesStore {
    /// Newest first.
    private(set) var drugs: [Drug]

    /// `nil` keeps favorites in memory only (previews and tests).
    private let fileURL: URL?

    init(fileURL: URL?) {
        self.fileURL = fileURL
        self.drugs = fileURL.flatMap(Self.load) ?? []
    }

    func contains(_ drug: Drug) -> Bool {
        drugs.contains { $0.id == drug.id }
    }

    func toggle(_ drug: Drug) {
        if contains(drug) {
            remove(drug)
        } else {
            drugs.insert(drug, at: 0)
            save()
        }
    }

    func remove(_ drug: Drug) {
        drugs.removeAll { $0.id == drug.id }
        save()
    }

    /// Replaces the saved copy with newer data from the API. Does nothing for drugs that are not saved.
    func update(_ drug: Drug) {
        guard let index = drugs.firstIndex(where: { $0.id == drug.id }), drugs[index] != drug else { return }
        drugs[index] = drug
        save()
    }

    // MARK: - File

    static func defaultFileURL() -> URL {
        URL.applicationSupportDirectory.appending(path: "favorites.json")
    }

    /// A missing or unreadable file means "no favorites yet". It is not worth an error screen.
    private static func load(from url: URL) -> [Drug]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([Drug].self, from: data)
    }

    /// The file is small (a few KB per drug), so writing it on the main actor is fine.
    /// If writing fails, the list still works for this session, so the error is not shown.
    private func save() {
        guard let fileURL else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? JSONEncoder().encode(drugs).write(to: fileURL, options: .atomic)
    }
}
