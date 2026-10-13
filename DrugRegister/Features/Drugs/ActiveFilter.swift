import Foundation

/// One filter that is on, shown as a chip above the results so the user can turn it off.
enum ActiveFilter: Hashable, Sendable {
    case dispensing(Dispensing)
    case productType(ProductType)
    case atcGroup(ATCGroup)
    case positiveList

    var title: String {
        switch self {
        case .dispensing(let dispensing): dispensing.title
        case .productType(let productType): productType.title
        case .atcGroup(let group): group.title
        case .positiveList: String(localized: "Positive list")
        }
    }
}

extension DrugFilters {
    /// The filters that are on, in the same order as the filter sheet.
    var active: [ActiveFilter] {
        var filters: [ActiveFilter] = []
        filters += Dispensing.filterOptions.filter(dispensing.contains).map(ActiveFilter.dispensing)
        filters += ProductType.filterOptions.filter(productTypes.contains).map(ActiveFilter.productType)
        if let atcGroup {
            filters.append(.atcGroup(atcGroup))
        }
        if positiveListOnly {
            filters.append(.positiveList)
        }
        return filters
    }

    mutating func remove(_ filter: ActiveFilter) {
        switch filter {
        case .dispensing(let value): dispensing.remove(value)
        case .productType(let value): productTypes.remove(value)
        case .atcGroup: atcGroup = nil
        case .positiveList: positiveListOnly = false
        }
    }
}
