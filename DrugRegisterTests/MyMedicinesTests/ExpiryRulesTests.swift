import Foundation
import Testing
@testable import DrugRegister

struct ExpiryRulesTests {

    private let calendar = Calendar.test
    private let today = day(2026, 10, 10)

    private func group(_ expiry: CalendarDay, today: CalendarDay? = nil) -> ExpiryGroup {
        ExpiryRules.group(for: expiry, today: today ?? self.today, calendar: calendar)
    }

    // MARK: - Groups and borders

    @Test
    func yesterdayIsExpired() {
        #expect(group(day(2026, 10, 9)) == .expired)
    }

    @Test
    func expiryDayItselfIsNotExpiredYet() {
        #expect(group(today) == .within30Days)
    }

    @Test
    func exactly30DaysIsStillWithin30Days() {
        #expect(group(day(2026, 11, 9)) == .within30Days)
        #expect(group(day(2026, 11, 10)) == .within3Months)
    }

    @Test
    func exactlyThreeMonthsIsStillWithinThreeMonths() {
        #expect(group(day(2027, 1, 10)) == .within3Months)
        #expect(group(day(2027, 1, 11)) == .later)
    }

    @Test
    func threeMonthsFromTheEndOfAMonthStopsAtTheShorterMonth() {
        let endOfJanuary = day(2027, 1, 31)

        #expect(group(day(2027, 4, 30), today: endOfJanuary) == .within3Months)
        #expect(group(day(2027, 5, 1), today: endOfJanuary) == .later)
    }

    @Test
    func decemberToJanuaryCountsAcrossTheYear() {
        let newYearsEve = day(2026, 12, 31)

        #expect(newYearsEve.days(until: day(2027, 1, 1), calendar: calendar) == 1)
        #expect(group(day(2027, 1, 1), today: newYearsEve) == .within30Days)

        let januaryOnly = ExpiryDate(month: 1, year: 2027, calendar: calendar)
        #expect(group(januaryOnly.day, today: newYearsEve) == .within3Months)
    }

    // MARK: - Month and year

    @Test(arguments: [(5, 2027, 31), (4, 2027, 30), (12, 2026, 31), (2, 2027, 28), (2, 2028, 29), (2, 2100, 28), (2, 2000, 29)])
    func monthAndYearMeanTheLastDayOfTheMonth(month: Int, year: Int, lastDay: Int) {
        let expiry = ExpiryDate(month: month, year: year, calendar: calendar)

        #expect(expiry.day == day(year, month, lastDay))
        #expect(expiry.isExactDay == false)
    }

    @Test
    func monthOnlyIsShownWithoutTheDay() {
        let monthOnly = ExpiryDate(month: 5, year: 2027, calendar: calendar).formatted(calendar: calendar)
        let exact = ExpiryDate(exactDay: day(2027, 5, 31)).formatted(calendar: calendar)

        #expect(monthOnly.contains("2027"))
        #expect(monthOnly.contains("31") == false)
        #expect(exact.contains("31"))
    }

    // MARK: - Sorting and summary

    @Test
    func sectionsAreInGroupOrderAndSoonestFirst() {
        let medicines = [
            Medicine.make(drug: snapshot("LATER"), expiry: day(2028, 1, 1)),
            Medicine.make(drug: snapshot("SOON B"), expiry: day(2026, 10, 20)),
            Medicine.make(drug: snapshot("OLD"), expiry: day(2026, 9, 1)),
            Medicine.make(drug: snapshot("SOON A"), expiry: day(2026, 10, 20)),
            Medicine.make(drug: snapshot("FIRST"), expiry: day(2026, 10, 11)),
        ]

        let sections = ExpiryRules.sections(for: medicines, today: today, calendar: calendar)

        #expect(sections.map(\.group) == [.expired, .within30Days, .later])
        #expect(sections[1].entries.map(\.medicine.drug.nameLatin) == ["FIRST", "SOON A", "SOON B"])
        #expect(sections[0].entries.first?.daysLeft == -39)
    }

    @Test
    func summaryCountsExpiredAndSoon() {
        let medicines = [
            Medicine.make(expiry: day(2026, 1, 1)),
            Medicine.make(expiry: day(2026, 10, 1)),
            Medicine.make(expiry: day(2026, 10, 30)),
            Medicine.make(expiry: day(2030, 1, 1)),
        ]

        let sections = ExpiryRules.sections(for: medicines, today: today, calendar: calendar)

        #expect(ExpiryRules.summary(for: sections) == ExpirySummary(expired: 2, within30Days: 1))
    }

    // MARK: - Labels

    // Expected text comes from the same catalog keys, so changing a translation does not break
    // the test. What is checked is the choice of days, weeks or months and the number.
    @Test(arguments: [
        (0, String(localized: "Expires today")),
        (1, String(localized: "In \(1) days")),
        (11, String(localized: "In \(11) days")),
        (12, String(localized: "In \(12) days")),
        (21, String(localized: "In \(3) weeks")),
        (45, String(localized: "In \(6) weeks")),
        (90, String(localized: "In \(3) months")),
        (-1, String(localized: "Expired \(1) days ago")),
        (-21, String(localized: "Expired \(3) weeks ago")),
        (-400, String(localized: "Expired \(13) months ago")),
    ])
    func labelUsesDaysWeeksOrMonths(daysLeft: Int, expected: String) {
        #expect(ExpiryRules.label(daysLeft: daysLeft) == expected)
    }

    private func snapshot(_ name: String) -> DrugSnapshot {
        DrugSnapshot(
            id: "1",
            nameLatin: name,
            nameCyrillic: name,
            strength: nil,
            pharmaceuticalForm: "таблета",
            detailUrl: URL(string: "https://example.com")!
        )
    }
}
