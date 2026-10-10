import Foundation

/// Начин на издавање. Rp = prescription, H = hospital only, BRp = OTC pharmacy, BR* = OTC general sale.
enum Dispensing: String, Codable, CaseIterable, Hashable, Sendable {
    case prescription
    case hospitalOnly
    case otcPharmacy
    case otcGeneralSale
    /// A value this app version does not know. One new value on the server must not break a whole page.
    case unknown

    init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Dispensing(rawValue: raw) ?? .unknown
    }

    /// The values the user can filter by.
    static let filterOptions: [Dispensing] = [.prescription, .hospitalOnly, .otcPharmacy, .otcGeneralSale]

    var title: String {
        switch self {
        case .prescription: String(localized: "Prescription")
        case .hospitalOnly: String(localized: "Hospital only")
        case .otcPharmacy: String(localized: "Over the counter, pharmacy")
        case .otcGeneralSale: String(localized: "Over the counter, general sale")
        case .unknown: String(localized: "Other")
        }
    }

    /// The short status shown on list cards. Both OTC kinds are simply "OTC" there.
    var badge: String? {
        switch self {
        case .prescription: String(localized: "Prescription")
        case .hospitalOnly: String(localized: "Hospital")
        case .otcPharmacy, .otcGeneralSale: String(localized: "OTC")
        case .unknown: nil
        }
    }
}
