import Foundation
import Testing
@testable import DrugRegister

struct GetDrugRequestTests {

    @Test
    func pathHasTheIDAndTheTokenIsSent() throws {
        let client = LiveAPIClient(baseURL: URL(string: "https://example.com")!, apiToken: "abc123")
        let request = try #require(GetDrugRequest(id: "51071"))

        let urlRequest = try client.makeURLRequest(for: request)

        #expect(urlRequest.url?.absoluteString == "https://example.com/api/v1/drugs/51071")
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")
    }

    @Test(arguments: ["", "1234567890123", "51a71", "../meta", "51071 "])
    func invalidIDIsRejected(id: String) {
        #expect(GetDrugRequest(id: id) == nil)
    }

    @Test
    func liveServiceThrowsForInvalidIDWithoutARequest() async {
        let service = LiveDrugService(apiClient: LiveAPIClient(baseURL: URL(string: "https://example.com")!, apiToken: nil))

        await #expect(throws: APIError.self) {
            _ = try await service.drug(id: "../meta")
        }
    }
}
