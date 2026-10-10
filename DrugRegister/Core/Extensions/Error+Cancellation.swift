import Foundation

extension Error {
    /// The user left the screen or started a new request. This is normal, not an error to show.
    var isCancellation: Bool {
        self is CancellationError || (self as? URLError)?.code == .cancelled
    }
}
