import Foundation

/// A protocol here earns its place: the view model can be tested and previewed without a network.
protocol DrugService: Sendable {
    func search(_ query: DrugQuery, page: Int, limit: Int) async throws -> DrugPage
    func meta() async throws -> RegisterMeta
    /// One drug by its register ID. Used to show fresh data for a saved medicine.
    func drug(id: String) async throws -> Drug
    /// The bytes of a PDF from `Drug.documents`.
    func document(at url: URL) async throws -> Data
}

struct LiveDrugService: DrugService {
    let apiClient: any APIClient

    func search(_ query: DrugQuery, page: Int, limit: Int) async throws -> DrugPage {
        try await apiClient.send(SearchDrugsRequest(query: query, page: page, limit: limit))
    }

    func meta() async throws -> RegisterMeta {
        try await apiClient.send(GetMetaRequest())
    }

    func drug(id: String) async throws -> Drug {
        guard let request = GetDrugRequest(id: id) else { throw APIError.invalidURL }
        return try await apiClient.send(request)
    }

    func document(at url: URL) async throws -> Data {
        try await apiClient.data(from: url)
    }
}

// MARK: - Endpoints

struct SearchDrugsRequest: APIRequest {
    typealias Response = DrugPage

    let query: DrugQuery
    let page: Int
    let limit: Int

    var path: String { "/api/v1/drugs" }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []

        // `q` must be 1 to 100 characters, so leave it out when empty.
        let text = query.searchText
        if !text.isEmpty {
            items.append(URLQueryItem(name: "q", value: text))
        }
        if let ean = query.ean {
            items.append(URLQueryItem(name: "ean", value: ean))
        }

        let filters = query.filters
        if let atcGroup = filters.atcGroup {
            items.append(URLQueryItem(name: "atc", value: atcGroup.code))
        }
        // Lists are comma-separated, sorted so the URL is always the same for the same filter.
        if !filters.dispensing.isEmpty {
            let value = filters.dispensing.map(\.rawValue).sorted().joined(separator: ",")
            items.append(URLQueryItem(name: "dispensing", value: value))
        }
        if !filters.productTypes.isEmpty {
            let value = filters.productTypes.map(\.rawValue).sorted().joined(separator: ",")
            items.append(URLQueryItem(name: "productType", value: value))
        }
        if filters.positiveListOnly {
            items.append(URLQueryItem(name: "positiveList", value: "true"))
        }
        items.append(URLQueryItem(name: "page", value: String(page)))
        items.append(URLQueryItem(name: "limit", value: String(limit)))
        return items
    }
}

struct GetDrugRequest: APIRequest {
    typealias Response = Drug

    let id: String

    /// The API only accepts 1 to 12 digits. Anything else would be a 400, or a different path.
    init?(id: String) {
        guard (1...12).contains(id.count), id.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        self.id = id
    }

    var path: String { "/api/v1/drugs/\(id)" }
}

struct GetMetaRequest: APIRequest {
    typealias Response = RegisterMeta

    var path: String { "/api/v1/meta" }
}
