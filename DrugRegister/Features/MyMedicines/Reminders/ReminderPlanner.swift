import Foundation

/// Decides which reminders exist. Pure logic: the same medicines and `now` always give the same list.
enum ReminderPlanner {
    /// iOS keeps at most 64 pending notifications per app.
    static let limit = 64
    /// Days before the expiry day. 0 is the expiry day itself.
    static let daysBefore = [30, 7, 0]
    /// Local time. Early enough to see it, late enough not to wake anyone.
    static let hour = 9
    static let idPrefix = "medicine-"

    /// Future reminders only, soonest first, at most `limit`.
    /// Reminders past the limit are scheduled later, when earlier ones have fired.
    static func reminders(for medicines: [Medicine], now: Date, calendar: Calendar) -> [Reminder] {
        medicines
            .flatMap { medicine in
                daysBefore.compactMap { offset in reminder(for: medicine, daysBefore: offset, calendar: calendar) }
            }
            .filter { $0.fireDate > now }
            .sorted { ($0.fireDate, $0.id) < ($1.fireDate, $1.id) }
            .prefix(limit)
            .map { $0 }
    }

    private static func reminder(for medicine: Medicine, daysBefore offset: Int, calendar: Calendar) -> Reminder? {
        let day = medicine.expiry.day.adding(days: -offset, calendar: calendar)
        var components = day.components
        components.hour = hour
        components.minute = 0
        guard let fireDate = calendar.date(from: components) else { return nil }

        return Reminder(
            id: "\(idPrefix)\(medicine.id.uuidString)-\(offset)",
            medicineID: medicine.id,
            fireDate: fireDate,
            components: components,
            title: medicine.drug.nameLatin,
            body: String(localized: "Expiry date: \(medicine.expiry.formatted(calendar: calendar))")
        )
    }
}
