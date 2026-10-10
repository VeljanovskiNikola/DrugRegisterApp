import Foundation
import Testing
@testable import DrugRegister

/// These tests check how requests are built and how errors are read. They never touch the network.
struct APIClientTests {

    private let baseURL = URL(string: "https://example.com")!

    private func queryItems(of request: URLRequest) -> [URLQueryItem]? {
        request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?.queryItems
    }

    // MARK: - Request building

    @Test
    func searchRequestHasPathQueryAndHeaders() throws {
        let client = LiveAPIClient(baseURL: baseURL, apiToken: "abc123")

        let request = try client.makeURLRequest(
            for: SearchDrugsRequest(query: DrugQuery(text: "amlodipin"), page: 2, limit: 20)
        )

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/api/v1/drugs")
        #expect(queryItems(of: request) == [
            URLQueryItem(name: "q", value: "amlodipin"),
            URLQueryItem(name: "page", value: "2"),
            URLQueryItem(name: "limit", value: "20"),
        ])
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test
    func noAuthHeaderWithoutToken() throws {
        let missing = LiveAPIClient(baseURL: baseURL, apiToken: nil)
        let empty = LiveAPIClient(baseURL: baseURL, apiToken: "")

        #expect(try missing.makeURLRequest(for: GetMetaRequest()).value(forHTTPHeaderField: "Authorization") == nil)
        #expect(try empty.makeURLRequest(for: GetMetaRequest()).value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test
    func requestWithoutQueryItemsHasNoQuestionMark() throws {
        let client = LiveAPIClient(baseURL: baseURL, apiToken: "abc123")

        let request = try client.makeURLRequest(for: GetMetaRequest())

        #expect(request.url?.absoluteString == "https://example.com/api/v1/meta")
    }

    @Test
    func documentRequestNeverCarriesTheToken() {
        let client = LiveAPIClient(baseURL: baseURL, apiToken: "abc123")
        let pdfURL = URL(string: "https://lekovi.zdravstvo.gov.mk/drugsregister.detaileddrugsregistercomponent:downloadguide/51071?t:ac=detailview/51071")!

        let request = client.makeDocumentRequest(for: pdfURL)

        #expect(request.url == pdfURL)
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/pdf")
    }

    // MARK: - Error reading

    private func response(status: Int, headers: [String: String] = [:]) -> HTTPURLResponse {
        HTTPURLResponse(url: baseURL, statusCode: status, httpVersion: nil, headerFields: headers)!
    }

    @Test
    func rateLimitUsesRetryAfterHeader() {
        let error = LiveAPIClient.error(for: response(status: 429, headers: ["Retry-After": "12"]), data: Data())

        #expect(error.errorDescription == String(localized: "Too many requests. Try again in \(12) seconds."))
    }

    @Test
    func rateLimitUsesTheSingularForOneSecond() {
        let error = LiveAPIClient.error(for: response(status: 429, headers: ["Retry-After": "1"]), data: Data())

        #expect(error.errorDescription == String(localized: "Too many requests. Try again in \(1) seconds."))
    }

    @Test
    func errorBodyMessageIsUsed() {
        let body = Data(#"{"error":{"code":"invalidParameter","message":"limit must be 100 or less.","parameter":"limit"}}"#.utf8)

        let error = LiveAPIClient.error(for: response(status: 400), data: body)

        #expect(error.errorDescription == "limit must be 100 or less.")
    }

    @Test
    func unreadableErrorBodyFallsBackToStatus() {
        let error = LiveAPIClient.error(for: response(status: 500), data: Data("<html>".utf8))

        #expect(error.errorDescription == String(localized: "Something went wrong (error \(500))."))
    }
}
