import Foundation

/// The user's choices in Settings: expiry reminders on or off, and the time they fire.
/// On, at 09:00, until the user changes it.
/// Separate from the iOS permission: the user can turn reminders off here without going to iOS Settings.
struct ReminderSettings: Sendable {
    /// A name, not a `UserDefaults`, because `UserDefaults` is not `Sendable`.
    /// `nil` is the app's standard defaults. Previews and tests use their own suite.
    var suiteName: String?
    var key = "remindersEnabled"
    var timeKey = "reminderTime"

    var isEnabled: Bool {
        get { defaults.object(forKey: key) as? Bool ?? true }
        nonmutating set { defaults.set(newValue, forKey: key) }
    }

    /// Stored as minutes after midnight.
    var time: ReminderTime {
        get {
            (defaults.object(forKey: timeKey) as? Int).flatMap(ReminderTime.init(minutesAfterMidnight:)) ?? .standard
        }
        nonmutating set { defaults.set(newValue.minutesAfterMidnight, forKey: timeKey) }
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
}
