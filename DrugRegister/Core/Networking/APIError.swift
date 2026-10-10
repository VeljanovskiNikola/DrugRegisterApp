import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimited(retryAfter: Int?)
    case server(status: Int, message: String?)
    case decoding(any Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            String(localized: "The request URL is not valid.")
        case .invalidResponse:
            String(localized: "The server sent an unexpected response.")
        case .rateLimited(let seconds?):
            String(localized: "Too many requests. Try again in \(seconds) seconds.")
        case .rateLimited(nil):
            String(localized: "Too many requests. Please try again soon.")
        case .server(_, let message?):
            // The API writes its messages in English. They are shown as they come.
            message
        case .server(let status, nil):
            String(localized: "Something went wrong (error \(status)).")
        case .decoding:
            String(localized: "We could not read the server response.")
        }
    }
}

/// Every error from the API has this shape: `{ "error": { "code", "message", "parameter"? } }`.
struct APIErrorBody: Decodable {
    struct Detail: Decodable {
        let code: String
        let message: String
        let parameter: String?
    }

    let error: Detail
}
