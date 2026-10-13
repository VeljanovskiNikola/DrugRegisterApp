import Foundation

/// One drug from the register. Matches the `Drug` schema in the API spec.
/// Macedonian text is kept exactly as the API sends it. Empty values are `nil`.
struct Drug: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let detailUrl: URL
    let nameLatin: String
    let nameCyrillic: String
    let genericName: String
    let atcCode: String?
    let extendedAtcCode: String?
    let ean: String?
    let pharmaceuticalForm: String
    let strength: String?
    let packaging: String
    let composition: String?
    let dosage: String?
    let dispensing: Dispensing
    let productType: ProductType
    let specialWarning: String?
    /// Raw code from the register: R, RS, RSS, RS/RSS, R/RS or R,D.
    let specialistRecommendation: String?
    let manufacturers: String
    let manufacturingSites: String?
    let marketingAuthorizationHolder: String
    let authorization: Authorization
    let prices: Prices
    let isOnPositiveList: Bool
    let fundCode: String?
    let hasBraille: Bool
    let hasVariations: Bool
    let documents: Documents

    struct Authorization: Codable, Hashable, Sendable {
        let number: String?
        let issuedDate: Date?
        let expiryDate: Date?
        let renewalDate: Date?
    }

    /// In MKD. `nil` when the site shows no price.
    struct Prices: Codable, Hashable, Sendable {
        let wholesaleExVat: Double?
        let retailWithVat: Double?
        let reference: Double?

        /// No price at all. The detail screen then leaves the card out instead of three "no price" rows.
        var isEmpty: Bool {
            wholesaleExVat == nil && retailWithVat == nil && reference == nil
        }
    }

    /// PDF links. They point to the site's own URLs. `nil` when the drug has no such PDF.
    struct Documents: Codable, Hashable, Sendable {
        let smpcUrl: URL?
        let patientLeafletUrl: URL?
        let labelUrl: URL?
    }
}
