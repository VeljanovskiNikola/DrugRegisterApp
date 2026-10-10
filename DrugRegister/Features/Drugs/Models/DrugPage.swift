import Foundation

struct DrugPage: Decodable, Sendable {
    let data: [Drug]
    let pagination: Pagination

    struct Pagination: Decodable, Equatable, Sendable {
        let page: Int
        let limit: Int
        /// Number of matching drugs.
        let total: Int
        let totalPages: Int
    }
}

/// Dataset info from `/api/v1/meta`.
struct RegisterMeta: Decodable, Equatable, Sendable {
    let source: URL
    let scrapedDate: Date
    let currency: String
    let count: Int
    let apiVersion: String
    let fullDatasetPath: String
}
