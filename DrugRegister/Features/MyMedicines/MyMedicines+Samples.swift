#if DEBUG
import Foundation

// Sample data for previews and tests. Not part of the release build.

extension Medicine {
    static func make(
        id: UUID = UUID(),
        drug: DrugSnapshot = DrugSnapshot(.sample),
        expiry: CalendarDay,
        isExactDay: Bool = true,
        packCount: Int = 1,
        note: String = "",
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) -> Medicine {
        Medicine(
            id: id,
            drug: drug,
            expiry: ExpiryDate(stored: expiry, isExactDay: isExactDay),
            packCount: packCount,
            openedOn: nil,
            note: note,
            createdAt: createdAt
        )
    }

    /// Relative to today, so previews always show every group.
    static var previewList: [Medicine] {
        let calendar = Calendar.current
        let today = CalendarDay(.now, calendar: calendar)
        let drugs = Drug.previewList.map(DrugSnapshot.init)
        return [
            make(drug: drugs[0], expiry: today.adding(days: 12, calendar: calendar), packCount: 2),
            make(drug: drugs[1], expiry: today.adding(days: 50, calendar: calendar)),
            make(drug: drugs[2], expiry: today.adding(months: 14, calendar: calendar), isExactDay: false,
                 note: "Во кутијата во бањата"),
            make(drug: drugs[0], expiry: today.adding(months: 20, calendar: calendar), isExactDay: false),
        ]
    }

    static var previewExpired: [Medicine] {
        let calendar = Calendar.current
        let today = CalendarDay(.now, calendar: calendar)
        let drugs = Drug.previewList.map(DrugSnapshot.init)
        return previewList + [
            make(drug: drugs[3], expiry: today.adding(days: -21, calendar: calendar)),
            make(drug: drugs[4], expiry: today.adding(days: -3, calendar: calendar)),
        ]
    }
}

/// Records what would be scheduled. Never touches real notifications.
actor StubReminderScheduler: ReminderScheduler {
    private(set) var currentPermission: ReminderPermission
    private(set) var permissionRequests = 0
    private(set) var scheduled: [Reminder] = []
    private(set) var replaceCount = 0
    private let grantsPermission: Bool

    init(permission: ReminderPermission = .allowed, grantsPermission: Bool = true) {
        self.currentPermission = permission
        self.grantsPermission = grantsPermission
    }

    func permission() -> ReminderPermission {
        currentPermission
    }

    func requestPermission() -> Bool {
        permissionRequests += 1
        currentPermission = grantsPermission ? .allowed : .denied
        return grantsPermission
    }

    func replaceAll(with reminders: [Reminder]) {
        scheduled = reminders
        replaceCount += 1
    }
}

extension MedicineServices {
    /// In memory, no notifications, real clock. For previews.
    static func preview(medicines: [Medicine], permission: ReminderPermission = .allowed) -> MedicineServices {
        MedicineServices(
            repository: InMemoryMedicineRepository(medicines: medicines),
            scheduler: StubReminderScheduler(permission: permission),
            settings: .preview
        )
    }
}

extension ReminderSettings {
    /// Separate defaults, so previews never change the real choice.
    static var preview: ReminderSettings {
        ReminderSettings(suiteName: "preview")
    }
}
#endif
