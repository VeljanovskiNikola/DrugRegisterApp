import Foundation

/// What the user asked for. Paging is not part of it: a new query always starts at page 1.
/// It is Hashable so the view can use it as the id of `.task(id:)`.
struct DrugQuery: Hashable, Sendable {
    var text = ""
    var filters = DrugFilters()
    /// Set by the barcode scanner. Always a valid value (see `EAN.normalized`).
    var ean: String?

    /// The text as the API accepts it: trimmed and at most 100 characters.
    var searchText: String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
    }

    /// Nothing typed, scanned or filtered. The home screen shows instead of results.
    var isEmpty: Bool {
        searchText.isEmpty && !filters.isActive && ean == nil
    }
}

/// Everything in the filter sheet. Kept apart from the text so the sheet can edit a copy.
struct DrugFilters: Hashable, Sendable {
    var dispensing: Set<Dispensing> = []
    var productTypes: Set<ProductType> = []
    var atcGroup: ATCGroup?
    var positiveListOnly = false

    var isActive: Bool {
        self != DrugFilters()
    }
}
