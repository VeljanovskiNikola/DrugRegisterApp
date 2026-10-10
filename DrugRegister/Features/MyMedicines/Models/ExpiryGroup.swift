import Foundation

enum ExpiryGroup: Int, CaseIterable, Hashable, Sendable {
    case expired
    case within30Days
    case within3Months
    case later

    var title: String {
        switch self {
        case .expired: String(localized: "Expired")
        case .within30Days: String(localized: "Expires within 30 days")
        case .within3Months: String(localized: "Within 3 months")
        case .later: String(localized: "Later")
        }
    }
}

/// One row of the list, with everything the view needs already worked out.
struct ExpiryEntry: Identifiable, Hashable, Sendable {
    let medicine: Medicine
    let group: ExpiryGroup
    /// 0 on the expiry day, negative once expired.
    let daysLeft: Int

    var id: UUID { medicine.id }
}

struct ExpirySection: Identifiable, Hashable, Sendable {
    let group: ExpiryGroup
    let entries: [ExpiryEntry]

    var id: ExpiryGroup { group }
}

struct ExpirySummary: Hashable, Sendable {
    let expired: Int
    let within30Days: Int
}

/// The rules for groups, sorting and labels. `today` is always passed in, so tests never
/// depend on the real date.
enum ExpiryRules {
    static let soonDays = 30
    static let laterMonths = 3

    /// A pack can be used until the end of its expiry day, so "today" is not expired yet.
    static func group(for expiry: CalendarDay, today: CalendarDay, calendar: Calendar) -> ExpiryGroup {
        let daysLeft = today.days(until: expiry, calendar: calendar)
        if daysLeft < 0 { return .expired }
        if daysLeft <= soonDays { return .within30Days }
        if expiry <= today.adding(months: laterMonths, calendar: calendar) { return .within3Months }
        return .later
    }

    /// Groups in a fixed order, soonest expiry first inside each group. Empty groups are left out.
    static func sections(for medicines: [Medicine], today: CalendarDay, calendar: Calendar) -> [ExpirySection] {
        let entries = medicines
            .map { medicine in
                ExpiryEntry(
                    medicine: medicine,
                    group: group(for: medicine.expiry.day, today: today, calendar: calendar),
                    daysLeft: today.days(until: medicine.expiry.day, calendar: calendar)
                )
            }
            .sorted { lhs, rhs in
                if lhs.medicine.expiry != rhs.medicine.expiry { return lhs.medicine.expiry < rhs.medicine.expiry }
                if lhs.medicine.drug.nameLatin != rhs.medicine.drug.nameLatin {
                    return lhs.medicine.drug.nameLatin < rhs.medicine.drug.nameLatin
                }
                return lhs.medicine.createdAt < rhs.medicine.createdAt
            }

        return ExpiryGroup.allCases.compactMap { group in
            let inGroup = entries.filter { $0.group == group }
            return inGroup.isEmpty ? nil : ExpirySection(group: group, entries: inGroup)
        }
    }

    static func summary(for sections: [ExpirySection]) -> ExpirySummary {
        func count(_ group: ExpiryGroup) -> Int {
            sections.first { $0.group == group }?.entries.count ?? 0
        }
        return ExpirySummary(expired: count(.expired), within30Days: count(.within30Days))
    }

    /// "Истекува денес", "За 12 дена", "Истечен пред 3 недели".
    /// Days under two weeks, weeks under 60 days, months (of 30 days) after that.
    static func label(daysLeft: Int) -> String {
        let distance = abs(daysLeft)
        if daysLeft == 0 {
            return String(localized: "Expires today")
        }
        if daysLeft > 0 {
            if distance < 14 { return String(localized: "In \(distance) days") }
            if distance < 60 { return String(localized: "In \(distance / 7) weeks") }
            return String(localized: "In \(distance / 30) months")
        }
        if distance < 14 { return String(localized: "Expired \(distance) days ago") }
        if distance < 60 { return String(localized: "Expired \(distance / 7) weeks ago") }
        return String(localized: "Expired \(distance / 30) months ago")
    }
}
