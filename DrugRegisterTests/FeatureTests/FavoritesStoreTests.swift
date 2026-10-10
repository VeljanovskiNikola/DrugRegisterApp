import Foundation
import Testing
@testable import DrugRegister

@MainActor
struct FavoritesStoreTests {

    private func temporaryFileURL() -> URL {
        URL.temporaryDirectory.appending(path: "favorites-\(UUID().uuidString).json")
    }

    @Test
    func toggleAddsNewestFirstAndRemoves() {
        let store = FavoritesStore(fileURL: nil)
        let first = Drug.make(id: "1")
        let second = Drug.make(id: "2")

        store.toggle(first)
        store.toggle(second)
        #expect(store.drugs.map(\.id) == ["2", "1"])
        #expect(store.contains(first))

        store.toggle(first)
        #expect(store.drugs.map(\.id) == ["2"])
        #expect(store.contains(first) == false)
    }

    @Test
    func favoritesAreKeptBetweenLaunches() {
        let url = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let store = FavoritesStore(fileURL: url)
        store.toggle(.sample)

        let relaunched = FavoritesStore(fileURL: url)
        #expect(relaunched.drugs == [.sample])
        // Dates must survive the round trip, so the detail screen shows the same day.
        #expect(relaunched.drugs.first?.authorization.issuedDate == Date(dateOnly: "2019-10-17"))
    }

    @Test
    func swipeToDeleteIsSaved() {
        let url = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = FavoritesStore(fileURL: url)
        store.toggle(Drug.make(id: "1"))
        store.toggle(Drug.make(id: "2"))

        store.remove(Drug.make(id: "2"))   // swipe to delete

        #expect(FavoritesStore(fileURL: url).drugs.map(\.id) == ["1"])
    }

    @Test
    func updateReplacesOnlySavedDrugs() {
        let store = FavoritesStore(fileURL: nil)
        store.toggle(Drug.make(id: "1", name: "OLD NAME"))

        store.update(Drug.make(id: "1", name: "NEW NAME"))
        store.update(Drug.make(id: "2"))

        #expect(store.drugs.map(\.nameLatin) == ["NEW NAME"])
    }

    @Test
    func unreadableFileMeansNoFavorites() throws {
        let url = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("not json".utf8).write(to: url)

        #expect(FavoritesStore(fileURL: url).drugs.isEmpty)
    }
}
