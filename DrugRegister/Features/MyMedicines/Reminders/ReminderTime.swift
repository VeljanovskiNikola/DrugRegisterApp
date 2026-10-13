import Foundation

/// The time of day reminders fire, in local time. Hour and minute only, so no time zone can move it.
struct ReminderTime: Hashable, Sendable {
    let hour: Int
    let minute: Int

    /// Early enough to see it, late enough not to wake anyone.
    static let standard = ReminderTime(hour: 9, minute: 0)

    init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    /// How it is stored. `nil` for a value no clock has, so a bad stored value falls back to `standard`.
    init?(minutesAfterMidnight minutes: Int) {
        guard (0..<24 * 60).contains(minutes) else { return nil }
        self.init(hour: minutes / 60, minute: minutes % 60)
    }

    var minutesAfterMidnight: Int {
        hour * 60 + minute
    }
}
