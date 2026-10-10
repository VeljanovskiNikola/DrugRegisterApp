import Foundation
import Testing
@testable import DrugRegister

/// The API answers 400 to repeated or unknown parameters and to a bad `q`.
/// These tests make sure we only send what the spec allows.
struct SearchRequestTests {

    private func items(_ query: DrugQuery, page: Int = 1, limit: Int = 20) -> [URLQueryItem] {
        SearchDrugsRequest(query: query, page: page, limit: limit).queryItems
    }

    @Test
    func emptyQueryOnlySendsPagingValues() {
        #expect(items(DrugQuery()) == [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "limit", value: "20"),
        ])
    }

    @Test
    func blankTextIsLeftOut() {
        let result = items(DrugQuery(text: "   \n "))

        #expect(result.contains { $0.name == "q" } == false)
    }

    @Test
    func textIsTrimmed() {
        let result = items(DrugQuery(text: "  амлодипин "))

        #expect(result.first == URLQueryItem(name: "q", value: "амлодипин"))
    }

    @Test
    func textIsCutAt100Characters() {
        let result = items(DrugQuery(text: String(repeating: "a", count: 150)))

        #expect(result.first?.value?.count == 100)
    }

    @Test
    func dispensingIsCommaSeparatedAndSorted() {
        let query = DrugQuery(filters: DrugFilters(dispensing: [.prescription, .otcPharmacy]))

        let result = items(query)

        #expect(result.contains(URLQueryItem(name: "dispensing", value: "otcPharmacy,prescription")))
    }

    @Test
    func positiveListIsOnlySentWhenOn() {
        let off = DrugQuery(filters: DrugFilters(positiveListOnly: false))
        let on = DrugQuery(filters: DrugFilters(positiveListOnly: true))

        #expect(items(off).contains { $0.name == "positiveList" } == false)
        #expect(items(on).contains(URLQueryItem(name: "positiveList", value: "true")))
    }

    @Test
    func productTypeIsCommaSeparatedAndSorted() {
        let query = DrugQuery(filters: DrugFilters(productTypes: [.original, .biosimilar]))

        #expect(items(query).contains(URLQueryItem(name: "productType", value: "biosimilar,original")))
    }

    @Test
    func atcGroupIsSentAsPrefix() {
        let query = DrugQuery(filters: DrugFilters(atcGroup: .c))

        #expect(items(query).contains(URLQueryItem(name: "atc", value: "C")))
    }

    @Test
    func eanIsSentOnlyWhenSet() {
        #expect(items(DrugQuery(ean: "5310090003085")).contains(URLQueryItem(name: "ean", value: "5310090003085")))
        #expect(items(DrugQuery(text: "a")).contains { $0.name == "ean" } == false)
    }

    @Test
    func emptyFiltersSendNoFilterParameters() {
        let names = Set(items(DrugQuery(text: "a")).map(\.name))

        #expect(names == ["q", "page", "limit"])
    }

    @Test
    func noParameterAppearsTwice() {
        let query = DrugQuery(
            text: "a",
            filters: DrugFilters(
                dispensing: [.prescription],
                productTypes: [.generic],
                atcGroup: .n,
                positiveListOnly: true
            ),
            ean: "5310090003085"
        )

        let names = items(query).map(\.name)

        #expect(Set(names).count == names.count)
    }
}
