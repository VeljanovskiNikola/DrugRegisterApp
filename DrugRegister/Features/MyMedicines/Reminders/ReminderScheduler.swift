import Foundation

enum ReminderPermission: Sendable {
    case notDetermined
    case allowed
    case denied
}

/// Local notifications behind a protocol, so tests never schedule real ones.
protocol ReminderScheduler: Sendable {
    func permission() async -> ReminderPermission
    /// Shows the system prompt the first time. Returns whether reminders are allowed.
    func requestPermission() async -> Bool
    /// Removes every pending reminder of this feature and schedules `reminders` instead.
    /// Edits reschedule and deletes cancel, because the new list simply no longer has them.
    func replaceAll(with reminders: [Reminder]) async
}
