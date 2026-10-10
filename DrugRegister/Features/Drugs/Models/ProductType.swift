import Foundation

/// Г/О/БС. Г = generic, О = original, БС = biosimilar.
enum ProductType: String, Codable, CaseIterable, Hashable, Sendable {
    case generic
    case original
    case biosimilar
    case unknown

    init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ProductType(rawValue: raw) ?? .unknown
    }

    /// The values the user can filter by.
    static let filterOptions: [ProductType] = [.generic, .original, .biosimilar]

    var title: String {
        switch self {
        case .generic: String(localized: "Generic")
        case .original: String(localized: "Original")
        case .biosimilar: String(localized: "Biosimilar")
        case .unknown: String(localized: "Other")
        }
    }
}
