import Foundation

/// The barcode number on a drug package.
enum EAN {
    /// Returns the digits when the text is a valid `ean` value for the API: 8 to 14 digits.
    /// The API answers 400 to anything else, so a bad value is never sent.
    static func normalized(_ text: String) -> String? {
        let digits = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (8...14).contains(digits.count), digits.allSatisfy(\.isASCII), digits.allSatisfy(\.isNumber) else {
            return nil
        }
        return digits
    }
}
