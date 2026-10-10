import Foundation
import Testing
@testable import DrugRegister

/// JSON in the same shape as the examples in the API spec.
struct DecodingTests {

    /// This is a raw string, so `\n` stays a JSON escape and is not turned into a real new line.
    private func drugJSON(dispensing: String = "prescription", productType: String = "generic") -> String {
        #"""
        {
          "id": "51071",
          "detailUrl": "https://lekovi.zdravstvo.gov.mk/drugsregister/detailview/51071",
          "nameLatin": "AMLODIPIN",
          "nameCyrillic": "АМЛОДИПИН",
          "genericName": "amlodipine",
          "atcCode": "C08CA01",
          "extendedAtcCode": "C08CA01001",
          "ean": "5310090003085",
          "pharmaceuticalForm": "таблета",
          "strength": "5 mg",
          "packaging": "20 таблети (блистер 2 х 10)/кутија",
          "composition": "1 таблета содржи:\nамлодипин бесилат . . . 7 mg",
          "dosage": "1 х 5-10 mg на ден (max.10 mg на ден).",
          "dispensing": "\#(dispensing)",
          "productType": "\#(productType)",
          "specialWarning": null,
          "specialistRecommendation": "R",
          "manufacturers": "РЕПЛЕК ФАРМ ДООЕЛ СКОПЈЕ, Скопје, Р. Северна Македонија",
          "manufacturingSites": null,
          "marketingAuthorizationHolder": "РЕПЛЕК ФАРМ ДООЕЛ СКОПЈЕ",
          "authorization": {
            "number": "11-6470/2",
            "issuedDate": "2019-10-17",
            "expiryDate": null,
            "renewalDate": null
          },
          "prices": { "wholesaleExVat": 34, "retailWithVat": 44.1, "reference": 17.74 },
          "isOnPositiveList": true,
          "fundCode": "976423",
          "hasBraille": true,
          "hasVariations": false,
          "documents": {
            "smpcUrl": "https://lekovi.zdravstvo.gov.mk/drugsregister.detaileddrugsregistercomponent:downloadguide/51071?t:ac=detailview/51071",
            "patientLeafletUrl": "https://lekovi.zdravstvo.gov.mk/drugsregister.detaileddrugsregistercomponent:downloadreport/51071?t:ac=detailview/51071",
            "labelUrl": null
          }
        }
        """#
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        try JSONDecoder.api().decode(type, from: Data(json.utf8))
    }

    @Test
    func drugDecodesTextNumbersAndNulls() throws {
        let drug = try decode(Drug.self, from: drugJSON())

        #expect(drug.id == "51071")
        #expect(drug.nameCyrillic == "АМЛОДИПИН")
        #expect(drug.dispensing == .prescription)
        #expect(drug.productType == .generic)
        #expect(drug.prices.retailWithVat == 44.1)
        #expect(drug.prices.wholesaleExVat == 34)
        #expect(drug.specialWarning == nil)
        #expect(drug.manufacturingSites == nil)
        #expect(drug.documents.labelUrl == nil)
        #expect(drug.documents.smpcUrl != nil)
        #expect(drug.composition?.contains("\n") == true)
    }

    @Test
    func datesAreReadAsDateOnly() throws {
        let drug = try decode(Drug.self, from: drugJSON())

        #expect(drug.authorization.issuedDate == Date(dateOnly: "2019-10-17"))
        #expect(drug.authorization.expiryDate == nil)
    }

    @Test
    func badDateStringIsRejected() {
        #expect(Date(dateOnly: "17.10.2019") == nil)
        #expect(Date(dateOnly: "nope") == nil)
    }

    @Test
    func unknownDispensingValueDoesNotBreakDecoding() throws {
        let drug = try decode(Drug.self, from: drugJSON(dispensing: "somethingNew"))

        #expect(drug.dispensing == .unknown)
    }

    @Test
    func unknownProductTypeDoesNotBreakDecoding() throws {
        let drug = try decode(Drug.self, from: drugJSON(productType: "somethingNew"))

        #expect(drug.productType == .unknown)
    }

    @Test
    func pageDecodesDrugsAndPagination() throws {
        let json = #"{"data":[\#(drugJSON())],"pagination":{"page":1,"limit":1,"total":78,"totalPages":78}}"#

        let page = try decode(DrugPage.self, from: json)

        #expect(page.data.count == 1)
        #expect(page.pagination == DrugPage.Pagination(page: 1, limit: 1, total: 78, totalPages: 78))
    }

    @Test
    func metaDecodes() throws {
        let json = #"""
        {"source":"https://lekovi.zdravstvo.gov.mk/drugsregister","scrapedDate":"2026-09-27",
         "currency":"MKD","count":4119,"apiVersion":"v1","fullDatasetPath":"/data/drug-register.json"}
        """#

        let meta = try decode(RegisterMeta.self, from: json)

        #expect(meta.count == 4119)
        #expect(meta.scrapedDate == Date(dateOnly: "2026-09-27"))
    }
}
