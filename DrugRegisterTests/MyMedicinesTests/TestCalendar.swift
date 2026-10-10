import Foundation
@testable import DrugRegister

/// A fixed calendar and time zone, so no test depends on the machine's settings or today's date.
extension Calendar {
    static let test: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Skopje") ?? .gmt
        return calendar
    }()
}

func day(_ year: Int, _ month: Int, _ day: Int) -> CalendarDay {
    CalendarDay(year: year, month: month, day: day)
}

/// A moment in the test calendar's time zone.
func moment(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
    Calendar.test.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? .distantPast
}

/// Not a failure: a thrown error is how the "could not save" paths are tested.
struct RepositoryError: Error {}

actor FailingMedicineRepository: MedicineRepository {
    func all() throws -> [Medicine] { throw RepositoryError() }
    func save(_ medicine: Medicine) throws { throw RepositoryError() }
    func delete(id: UUID) throws { throw RepositoryError() }
}

func makeServices(
    medicines: [Medicine] = [],
    repository: (any MedicineRepository)? = nil,
    scheduler: StubReminderScheduler = StubReminderScheduler(),
    settings: ReminderSettings = .test(),
    now: Date = moment(2026, 10, 10)
) -> MedicineServices {
    MedicineServices(
        repository: repository ?? InMemoryMedicineRepository(medicines: medicines),
        scheduler: scheduler,
        settings: settings,
        now: { now },
        calendar: .test
    )
}

extension ReminderSettings {
    /// Fresh, empty defaults for each test, so tests never share or change the real choice.
    static func test(enabled: Bool? = nil) -> ReminderSettings {
        let settings = ReminderSettings(suiteName: "test-\(UUID().uuidString)")
        if let enabled {
            settings.isEnabled = enabled
        }
        return settings
    }
}
