import Foundation
import Observation

@MainActor
@Observable
final class MyMedicinesViewModel {
    private(set) var medicines: [Medicine] = []
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?
    private(set) var permission = ReminderPermission.notDetermined

    private let services: MedicineServices

    init(services: MedicineServices) {
        self.services = services
    }

    /// Worked out on every read from `services.now()`, so a list left open over midnight is still right.
    var sections: [ExpirySection] {
        ExpiryRules.sections(for: medicines, today: services.today, calendar: services.calendar)
    }

    var summary: ExpirySummary {
        ExpiryRules.summary(for: sections)
    }

    /// Only worth showing when there is something to remind about.
    var showsPermissionWarning: Bool {
        permission == .denied && !medicines.isEmpty
    }

    func expiryText(for medicine: Medicine) -> String {
        medicine.expiry.formatted(calendar: services.calendar)
    }

    /// Called from `.task` each time the tab appears, so items added from a detail screen show up.
    func load() async {
        do {
            medicines = try await services.repository.all()
            errorMessage = nil
        } catch {
            errorMessage = String(localized: "Your medicines could not be loaded.")
        }
        hasLoaded = true
        permission = await services.scheduler.permission()
    }

    func delete(_ medicine: Medicine) async {
        do {
            try await services.repository.delete(id: medicine.id)
            medicines.removeAll { $0.id == medicine.id }
            errorMessage = nil
        } catch {
            errorMessage = String(localized: "The medicine could not be deleted.")
            return
        }
        // Cancels its reminders: the new plan no longer has them.
        await services.syncReminders()
    }
}
