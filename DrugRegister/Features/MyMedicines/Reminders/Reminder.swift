import Foundation

/// One local notification to schedule.
struct Reminder: Hashable, Sendable {
    /// Stable, so scheduling the same reminder twice replaces it instead of adding a copy.
    let id: String
    let medicineID: UUID
    /// When it fires, in the calendar's time zone. Used for sorting and tests.
    let fireDate: Date
    /// What the system trigger matches: the day and the hour, local time.
    let components: DateComponents
    /// Only the drug name. No note, no advice.
    let title: String
    /// Only the expiry date.
    let body: String
}
