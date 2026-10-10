import Foundation

/// The API sends dates as `yyyy-MM-dd` with no time and no time zone.
/// We read them as midnight GMT and show them in GMT, so the day never shifts.
extension Date {
    init?(dateOnly string: String) {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        guard let date = calendar.date(
            from: DateComponents(year: parts[0], month: parts[1], day: parts[2])
        ) else { return nil }

        self = date
    }

    /// For example "17 окт. 2019 г.".
    var dateOnlyFormatted: String {
        formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, locale: .app, timeZone: .gmt))
    }
}

extension JSONDecoder {
    /// The decoder for this API: date-only strings become `Date`.
    static func api() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            guard let date = Date(dateOnly: string) else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: decoder.codingPath,
                        debugDescription: "Expected a yyyy-MM-dd date, got \(string)"
                    )
                )
            }
            return date
        }
        return decoder
    }
}
