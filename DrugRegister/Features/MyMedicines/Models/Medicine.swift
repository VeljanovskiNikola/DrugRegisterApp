import Foundation

/// One pack (or several identical packs) the user keeps at home.
/// The same drug can appear many times, with different expiry dates.
struct Medicine: Identifiable, Hashable, Sendable {
    let id: UUID
    var drug: DrugSnapshot
    var expiry: ExpiryDate
    var packCount: Int
    var openedOn: CalendarDay?
    /// Private. Never logged, never put in a notification.
    var note: String
    let createdAt: Date
}
