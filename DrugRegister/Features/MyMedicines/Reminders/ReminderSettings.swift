import Foundation

/// The user's choice in Settings: expiry reminders on or off. On until the user turns them off.
/// Separate from the iOS permission: the user can turn reminders off here without going to iOS Settings.
struct ReminderSettings: Sendable {
    /// A name, not a `UserDefaults`, because `UserDefaults` is not `Sendable`.
    /// `nil` is the app's standard defaults. Previews and tests use their own suite.
    var suiteName: String?
    var key = "remindersEnabled"

    var isEnabled: Bool {
        get { defaults.object(forKey: key) as? Bool ?? true }
        nonmutating set { defaults.set(newValue, forKey: key) }
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
}
