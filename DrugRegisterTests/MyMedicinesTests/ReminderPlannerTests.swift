import Foundation
import Testing
@testable import DrugRegister

struct ReminderPlannerTests {

    private let calendar = Calendar.test

    private func reminders(
        _ medicines: [Medicine],
        at time: ReminderTime = .standard,
        now: Date = moment(2026, 10, 10)
    ) -> [Reminder] {
        ReminderPlanner.reminders(for: medicines, at: time, now: now, calendar: calendar)
    }

    @Test
    func thirtyDaysSevenDaysAndTheDayItself() {
        let result = reminders([Medicine.make(expiry: day(2027, 1, 31))])

        #expect(result.map(\.fireDate) == [
            moment(2027, 1, 1, hour: 9),
            moment(2027, 1, 24, hour: 9),
            moment(2027, 1, 31, hour: 9),
        ])
        #expect(result.allSatisfy { $0.components.hour == 9 && $0.components.minute == 0 })
    }

    @Test
    func remindersFireAtTheChosenTime() {
        let result = reminders([Medicine.make(expiry: day(2027, 1, 31))], at: ReminderTime(hour: 18, minute: 30))

        #expect(result.allSatisfy { $0.components.hour == 18 && $0.components.minute == 30 })
        #expect(result.last?.fireDate == Calendar.test.date(
            from: DateComponents(year: 2027, month: 1, day: 31, hour: 18, minute: 30)
        ))
    }

    /// A later time keeps the expiry-day reminder alive for longer that day.
    @Test
    func expiryDayReminderFollowsTheChosenTime() {
        let medicine = Medicine.make(expiry: day(2026, 10, 10))
        let evening = ReminderTime(hour: 20, minute: 0)

        #expect(reminders([medicine], at: evening, now: moment(2026, 10, 10, hour: 12)).count == 1)
    }

    @Test
    func nothingIsScheduledInThePast() {
        // 5 days left: the 30 and 7 day reminders are already past.
        let soon = reminders([Medicine.make(expiry: day(2026, 10, 15))])
        #expect(soon.map(\.fireDate) == [moment(2026, 10, 15, hour: 9)])

        #expect(reminders([Medicine.make(expiry: day(2026, 9, 1))]).isEmpty)
    }

    @Test
    func expiryDayReminderIsSkippedOnceNineOClockHasPassed() {
        let medicine = Medicine.make(expiry: day(2026, 10, 10))

        #expect(reminders([medicine], now: moment(2026, 10, 10, hour: 8)).count == 1)
        #expect(reminders([medicine], now: moment(2026, 10, 10, hour: 12)).isEmpty)
    }

    @Test
    func onlyTheSoonest64AreKept() {
        // 30 medicines × 3 reminders = 90. A year apart, so no two reminders share a date.
        let medicines = (0..<30).map { index in
            Medicine.make(expiry: day(2027, 1, 1).adding(months: index * 12, calendar: calendar))
        }

        let result = reminders(medicines)

        #expect(result.count == ReminderPlanner.limit)
        #expect(result.map(\.fireDate) == result.map(\.fireDate).sorted())
        // Everything left out is later than everything kept.
        let latestKept = result.last?.fireDate ?? .distantPast
        let dropped = reminders(medicines, now: latestKept)
        #expect(dropped.count == 90 - 64)
        #expect(dropped.allSatisfy { $0.fireDate > latestKept })
    }

    @Test
    func textHasOnlyTheNameAndTheDate() {
        let medicine = Medicine.make(expiry: day(2027, 5, 31), isExactDay: false, note: "private note")

        let result = reminders([medicine])

        #expect(result.allSatisfy { $0.title == medicine.drug.nameLatin })
        let date = medicine.expiry.formatted(calendar: calendar)
        #expect(result.allSatisfy { $0.body == String(localized: "Expiry date: \(date)") })
        #expect(result.allSatisfy { $0.body.contains("2027") })
        #expect(result.allSatisfy { !$0.body.contains("private note") && !$0.title.contains("private note") })
    }

    @Test
    func idsAreUniqueAndStable() {
        let medicines = [
            Medicine.make(expiry: day(2027, 3, 1)),
            Medicine.make(expiry: day(2027, 3, 1)),
        ]

        let first = reminders(medicines)
        let second = reminders(medicines)

        #expect(Set(first.map(\.id)).count == 6)
        #expect(first.map(\.id) == second.map(\.id))
        #expect(first.allSatisfy { $0.id.hasPrefix(ReminderPlanner.idPrefix) })
    }
}
