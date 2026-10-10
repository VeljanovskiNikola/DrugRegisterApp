import Foundation
import SwiftData

/// The SwiftData shape of a `Medicine`. It never leaves `SwiftDataMedicineRepository`:
/// SwiftData models are not `Sendable`, so the rest of the app works with the `Medicine` struct.
///
/// Dates are stored as year, month and day numbers, so a time zone can never move them.
@Model
final class MedicineRecord {
    @Attribute(.unique) var id: UUID

    var drugID: String
    var nameLatin: String
    var nameCyrillic: String
    var strength: String?
    var pharmaceuticalForm: String
    var detailUrl: URL

    var expiryYear: Int
    var expiryMonth: Int
    var expiryDay: Int
    var isExactDay: Bool

    var packCount: Int
    var openedYear: Int?
    var openedMonth: Int?
    var openedDay: Int?
    var note: String
    var createdAt: Date

    init(_ medicine: Medicine) {
        id = medicine.id
        drugID = medicine.drug.id
        nameLatin = medicine.drug.nameLatin
        nameCyrillic = medicine.drug.nameCyrillic
        strength = medicine.drug.strength
        pharmaceuticalForm = medicine.drug.pharmaceuticalForm
        detailUrl = medicine.drug.detailUrl
        expiryYear = medicine.expiry.day.year
        expiryMonth = medicine.expiry.day.month
        expiryDay = medicine.expiry.day.day
        isExactDay = medicine.expiry.isExactDay
        packCount = medicine.packCount
        openedYear = medicine.openedOn?.year
        openedMonth = medicine.openedOn?.month
        openedDay = medicine.openedOn?.day
        note = medicine.note
        createdAt = medicine.createdAt
    }

    /// The snapshot does not change after saving. Only what the edit form offers is updated.
    func update(from medicine: Medicine) {
        expiryYear = medicine.expiry.day.year
        expiryMonth = medicine.expiry.day.month
        expiryDay = medicine.expiry.day.day
        isExactDay = medicine.expiry.isExactDay
        packCount = medicine.packCount
        openedYear = medicine.openedOn?.year
        openedMonth = medicine.openedOn?.month
        openedDay = medicine.openedOn?.day
        note = medicine.note
    }

    var medicine: Medicine {
        let expiry = CalendarDay(year: expiryYear, month: expiryMonth, day: expiryDay)
        var openedOn: CalendarDay?
        if let openedYear, let openedMonth, let openedDay {
            openedOn = CalendarDay(year: openedYear, month: openedMonth, day: openedDay)
        }
        return Medicine(
            id: id,
            drug: DrugSnapshot(
                id: drugID,
                nameLatin: nameLatin,
                nameCyrillic: nameCyrillic,
                strength: strength,
                pharmaceuticalForm: pharmaceuticalForm,
                detailUrl: detailUrl
            ),
            expiry: ExpiryDate(stored: expiry, isExactDay: isExactDay),
            packCount: packCount,
            openedOn: openedOn,
            note: note,
            createdAt: createdAt
        )
    }
}

extension ExpiryDate {
    /// Rebuilds a saved value as it was. A month-only date is already stored as its last day.
    init(stored day: CalendarDay, isExactDay: Bool) {
        self = isExactDay ? ExpiryDate(exactDay: day) : ExpiryDate(lastDayOfMonth: day)
    }
}
