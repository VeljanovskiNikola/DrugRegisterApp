import Foundation

/// Describes one endpoint. Features say *what* they want.
/// The API client handles the URL, headers, status codes and decoding.
///
/// The register API is read-only (GET and HEAD only), so there is no method or body here.
protocol APIRequest: Sendable {
    associatedtype Response: Decodable & Sendable

    var path: String { get }
    var queryItems: [URLQueryItem] { get }
}

extension APIRequest {
    var queryItems: [URLQueryItem] { [] }
}
