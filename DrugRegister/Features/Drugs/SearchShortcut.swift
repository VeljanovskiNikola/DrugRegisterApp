import Foundation

/// The quick filters on the home screen. Each one replaces the current filters.
enum SearchShortcut: CaseIterable, Hashable {
    case prescription
    case overTheCounter
    case generics

    var title: String {
        switch self {
        case .prescription: String(localized: "On prescription")
        case .overTheCounter: String(localized: "Over the counter")
        case .generics: String(localized: "Generics")
        }
    }

    var systemImage: String {
        switch self {
        case .prescription: "doc.text"
        case .overTheCounter: "bag"
        case .generics: "pills"
        }
    }

    var filters: DrugFilters {
        switch self {
        case .prescription: DrugFilters(dispensing: [.prescription])
        case .overTheCounter: DrugFilters(dispensing: [.otcPharmacy, .otcGeneralSale])
        case .generics: DrugFilters(productTypes: [.generic])
        }
    }
}
