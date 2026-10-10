import Foundation

/// The expiry date printed on a package. Not the register's `authorization.expiryDate`,
/// which is the validity of the authorization decision and says nothing about a package.
struct ExpiryDate: Hashable, Comparable, Codable, Sendable {
    /// The last day the package can be used.
    let day: CalendarDay
    /// False when the user only entered month and year. Then `day` is the last day of that month.
    let isExactDay: Bool

    /// "EXP 05/2027" means the end of May 2027.
    init(month: Int, year: Int, calendar: Calendar) {
        self.day = .lastDay(ofMonth: month, year: year, calendar: calendar)
        self.isExactDay = false
    }

    init(exactDay: CalendarDay) {
        self.day = exactDay
        self.isExactDay = true
    }

    /// A month-only date read back from storage, where it is kept as the month's last day.
    init(lastDayOfMonth day: CalendarDay) {
        self.day = day
        self.isExactDay = false
    }

    static func < (lhs: ExpiryDate, rhs: ExpiryDate) -> Bool {
        lhs.day < rhs.day
    }

    /// "мај 2027" for month and year, "31 мај 2027" for an exact day.
    func formatted(calendar: Calendar) -> String {
        guard let date = day.date(in: calendar) else { return "" }
        var style = Date.FormatStyle(locale: .app, calendar: calendar, timeZone: calendar.timeZone)
        style = isExactDay ? style.day().month(.wide).year() : style.month(.wide).year()
        return date.formatted(style)
    }
}
