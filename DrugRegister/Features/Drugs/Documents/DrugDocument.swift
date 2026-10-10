import Foundation

/// One PDF from the register: the patient leaflet, the SmPC or the label.
struct DrugDocument: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case patientLeaflet
        case smpc
        case label
    }

    let kind: Kind
    let url: URL

    var title: String {
        switch kind {
        case .patientLeaflet: String(localized: "Patient leaflet")
        case .smpc: String(localized: "Summary of product characteristics")
        case .label: String(localized: "Label and packaging")
        }
    }
}

extension Drug.Documents {
    func url(for kind: DrugDocument.Kind) -> URL? {
        switch kind {
        case .patientLeaflet: patientLeafletUrl
        case .smpc: smpcUrl
        case .label: labelUrl
        }
    }
}
