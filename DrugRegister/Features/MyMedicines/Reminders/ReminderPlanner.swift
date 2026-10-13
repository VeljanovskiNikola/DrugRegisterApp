import Foundation

/// Decides which reminders exist. Pure logic: the same medicines and `now` always give the same list.
enum ReminderPlanner {
    /// iOS keeps at most 64 pending notifications per app.
    static let limit = 64
    /// Days before the expiry day. 0 is the expiry day itself.
    static let daysBefore = [30, 7, 0]
    static let idPrefix = "medicine-"

    /// Future reminders only, soonest first, at most `limit`.
    /// Reminders past the limit are scheduled later, when earlier ones have fired.
    /// `time` is the user's choice in Settings, `ReminderTime.standard` (09:00) unless changed.
    static func reminders(for medicines: [Medicine], at time: ReminderTime, now: Date, calendar: Calendar) -> [Reminder] {
        medicines
            .flatMap { medicine in
                daysBefore.compactMap { offset in
                    reminder(for: medicine, daysBefore: offset, at: time, calendar: calendar)
                }
            }
            .filter { $0.fireDate > now }
            .sorted { ($0.fireDate, $0.id) < ($1.fireDate, $1.id) }
            .prefix(limit)
            .map { $0 }
    }

    private static func reminder(
        for medicine: Medicine,
        daysBefore offset: Int,
        at time: ReminderTime,
        calendar: Calendar
    ) -> Reminder? {
        let day = medicine.expiry.day.adding(days: -offset, calendar: calendar)
        var components = day.components
        components.hour = time.hour
        components.minute = time.minute
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
