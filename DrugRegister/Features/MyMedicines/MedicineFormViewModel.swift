import Foundation
import Observation

/// Adds a new medicine or edits a saved one.
@MainActor
@Observable
final class MedicineFormViewModel {
    enum Mode: Hashable {
        case add(DrugSnapshot)
        case edit(Medicine)
    }

    // Expiry. Month and year are required, so they start empty and Save stays off until both are set.
    var expiryMonth: Int?
    var expiryYear: Int?
    /// Switching keeps the date the user already chose: month and year become that month's
    /// last day, and an exact day becomes its month and year.
    var knowsExactDay = false {
        didSet {
            guard knowsExactDay != oldValue else { return }
            let calendar = services.calendar
            if knowsExactDay {
                if let expiryMonth, let expiryYear,
                   let date = CalendarDay.lastDay(ofMonth: expiryMonth, year: expiryYear, calendar: calendar).date(in: calendar) {
                    exactExpiryDate = date
                }
            } else {
                let day = CalendarDay(exactExpiryDate, calendar: calendar)
                expiryMonth = day.month
                expiryYear = day.year
            }
        }
    }
    var exactExpiryDate: Date

    var packCount = 1
    var isOpened = false
    var openedDate: Date
    var note = ""

    private(set) var isSaving = false
    private(set) var errorMessage: String?

    static let noteLimit = 200
    static let packRange = 1...99

    let mode: Mode
    private let services: MedicineServices

    init(mode: Mode, services: MedicineServices) {
        self.mode = mode
        self.services = services

        let calendar = services.calendar
        let now = services.now()
        exactExpiryDate = now
        openedDate = now

        if case .edit(let medicine) = mode {
            let expiry = medicine.expiry.day
            expiryMonth = expiry.month
            expiryYear = expiry.year
            knowsExactDay = medicine.expiry.isExactDay
            exactExpiryDate = expiry.date(in: calendar) ?? now
            packCount = medicine.packCount
            if let opened = medicine.openedOn?.date(in: calendar) {
                isOpened = true
                openedDate = opened
            }
            note = medicine.note
        }
    }

    /// An opened date cannot be in the future.
    var latestOpenedDate: Date {
        services.now()
    }

    var drug: DrugSnapshot {
        switch mode {
        case .add(let drug): drug
        case .edit(let medicine): medicine.drug
        }
    }

    var isEditing: Bool {
        if case .edit = mode { true } else { false }
    }

    /// Packages print years a few years ahead. Earlier years let the user log expired packs too.
    var yearOptions: [Int] {
        let year = services.today.year
        return Array((year - 5)...(year + 10))
    }

    var monthNames: [String] {
        var calendar = services.calendar
        calendar.locale = .app
        return calendar.standaloneMonthSymbols
    }

    /// The expiry as it will be saved, or `nil` while month or year is missing.
    var expiry: ExpiryDate? {
        let calendar = services.calendar
        if knowsExactDay {
            return ExpiryDate(exactDay: CalendarDay(exactExpiryDate, calendar: calendar))
        }
        guard let expiryMonth, let expiryYear else { return nil }
        return ExpiryDate(month: expiryMonth, year: expiryYear, calendar: calendar)
    }

    var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        expiry != nil
            && Self.packRange.contains(packCount)
            && trimmedNote.count <= Self.noteLimit
            && !isSaving
    }

    /// Returns true when saved, so the view can close the form.
    func save() async -> Bool {
        guard canSave, let expiry else { return false }
        isSaving = true
        defer { isSaving = false }

        let calendar = services.calendar
        let openedOn = isOpened ? CalendarDay(openedDate, calendar: calendar) : nil
        let medicine: Medicine
        switch mode {
        case .add(let drug):
            // Always a new id: the same drug can be saved many times, one entry per pack or date.
            medicine = Medicine(
                id: UUID(),
                drug: drug,
                expiry: expiry,
                packCount: packCount,
                openedOn: openedOn,
                note: trimmedNote,
                createdAt: services.now()
            )
        case .edit(var existing):
            existing.expiry = expiry
            existing.packCount = packCount
            existing.openedOn = openedOn
            existing.note = trimmedNote
            medicine = existing
        }

        do {
            try await services.repository.save(medicine)
        } catch {
            errorMessage = String(localized: "The medicine could not be saved.")
            return false
        }

        // Asked here, on the first save, not at launch: now the user knows what reminders are for.
        // Not asked when the user turned reminders off in Settings.
        if services.settings.isEnabled, await services.scheduler.permission() == .notDetermined {
            _ = await services.scheduler.requestPermission()
        }
        await services.syncReminders()
        return true
    }
}
