import Foundation

protocol APIClient: Sendable {
    func send<Request: APIRequest>(_ request: Request) async throws -> Request.Response
    /// Raw bytes from any URL, for example a PDF on the register's site. No token is sent.
    func data(from url: URL) async throws -> Data
}

/// The only place in the app that talks to URLSession.
///
/// The API needs a bearer token on every call. It is an app ID and a quota key,
/// so it is a plain value from configuration. There is no login and no refresh.
struct LiveAPIClient: APIClient {
    let baseURL: URL
    let apiToken: String?
    var session: URLSession = .shared

    func send<Request: APIRequest>(_ request: Request) async throws -> Request.Response {
        let urlRequest = try makeURLRequest(for: request)
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw Self.error(for: httpResponse, data: data)
        }

        do {
            return try JSONDecoder.api().decode(Request.Response.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    /// Internal (not private) so tests can check URL and headers without a network.
    func makeURLRequest<Request: APIRequest>(for request: Request) throws -> URLRequest {
        let url = baseURL.appending(path: request.path)

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        // The API answers 400 to unknown or repeated parameters, so send none when empty.
        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }
        guard let finalURL = components.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        // Auth lives here, once. No feature adds this header itself.
        if let apiToken, !apiToken.isEmpty {
            urlRequest.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        }
        return urlRequest
    }

    /// The PDFs live on the register's own site, not on the API. The site sends them as
    /// `Content-Disposition: attachment`, so Safari would download them. Reading the bytes
    /// here lets the app show them in place, and nothing is saved on the phone.
    func data(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(for: makeDocumentRequest(for: url))

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.server(status: httpResponse.statusCode, message: nil)
        }
        return data
    }

    /// Internal (not private) so tests can check it never carries the token.
    /// The token is for the API only and must not go to another host.
    func makeDocumentRequest(for url: URL) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/pdf", forHTTPHeaderField: "Accept")
        return urlRequest
    }

    static func error(for response: HTTPURLResponse, data: Data) -> APIError {
        if response.statusCode == 429 {
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After").flatMap { Int($0) }
            return .rateLimited(retryAfter: retryAfter)
        }
        let message = try? JSONDecoder().decode(APIErrorBody.self, from: data).error.message
        return .server(status: response.statusCode, message: message)
    }
}
