import Foundation

/// A day on the calendar, with no time and no time zone.
/// Expiry dates are stored like this, so travelling or a time zone change can never move the day.
struct CalendarDay: Hashable, Comparable, Codable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The day `date` falls on in `calendar` (and its time zone).
    init(_ date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 1, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    /// The last day of a month, for packages that only print "EXP 05/2027".
    /// Handles February in leap years.
    static func lastDay(ofMonth month: Int, year: Int, calendar: Calendar) -> CalendarDay {
        let first = calendar.date(from: DateComponents(year: year, month: month, day: 1))
        let days = first.flatMap { calendar.range(of: .day, in: .month, for: $0)?.count } ?? 28
        return CalendarDay(year: year, month: month, day: days)
    }

    static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    var components: DateComponents {
        DateComponents(year: year, month: month, day: day)
    }

    /// Midnight at the start of this day in `calendar`.
    func date(in calendar: Calendar) -> Date? {
        calendar.date(from: components)
    }

    func adding(days: Int, calendar: Calendar) -> CalendarDay {
        shifted(by: DateComponents(day: days), calendar: calendar)
    }

    /// Calendar months, so Jan 31 + 3 months is Apr 30, not May 1.
    func adding(months: Int, calendar: Calendar) -> CalendarDay {
        shifted(by: DateComponents(month: months), calendar: calendar)
    }

    /// Whole days from `self` to `other`. Negative when `other` is earlier.
    func days(until other: CalendarDay, calendar: Calendar) -> Int {
        guard let start = date(in: calendar), let end = other.date(in: calendar) else { return 0 }
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    private func shifted(by delta: DateComponents, calendar: Calendar) -> CalendarDay {
        guard let start = date(in: calendar), let end = calendar.date(byAdding: delta, to: start) else { return self }
        return CalendarDay(end, calendar: calendar)
    }
}
