import Foundation
import UserNotifications

/// Opens My medicines when the user taps one of our reminders.
/// A tap can arrive before the UI exists (cold start), so it waits until `connect` is called.
@MainActor
final class ReminderTapHandler: NSObject, UNUserNotificationCenterDelegate {
    private var onOpen: (() -> Void)?
    private var hasPendingTap = false

    func connect(_ onOpen: @escaping () -> Void) {
        self.onOpen = onOpen
        if hasPendingTap {
            hasPendingTap = false
            onOpen()
        }
    }

    /// Other notifications the app may send one day are not ours, so they are ignored.
    func handleTap(identifier: String) {
        guard identifier.hasPrefix(ReminderPlanner.idPrefix) else { return }
        if let onOpen {
            onOpen()
        } else {
            hasPendingTap = true
        }
    }

    // The completion handler version, not the async one. The response cannot be sent to the main
    // actor, so only its identifier (a String) is read here and passed on.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        let identifier = response.notification.request.identifier
        DispatchQueue.main.async {
            MainActor.assumeIsolated { self.handleTap(identifier: identifier) }
        }
    }
}
