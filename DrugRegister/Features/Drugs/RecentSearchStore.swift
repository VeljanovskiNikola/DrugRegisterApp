import Foundation

/// Keeps the last searches on this device. They never leave it.
struct RecentSearchStore {
    var defaults: UserDefaults = .standard
    var key = "recentSearches"

    func load() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    func save(_ searches: [String]) {
        defaults.set(searches, forKey: key)
    }
}
