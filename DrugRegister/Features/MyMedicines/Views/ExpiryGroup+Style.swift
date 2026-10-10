import SwiftUI

/// How each group looks. Expired and soon rows get an icon and a badge, not only a color.
extension ExpiryGroup {
    var systemImage: String {
        switch self {
        case .expired: "exclamationmark.triangle.fill"
        case .within30Days: "clock.badge.exclamationmark"
        case .within3Months: "calendar"
        case .later: "calendar"
        }
    }

    /// `nil` for groups that need no attention: their label is plain text.
    var badgeTone: TagBadge.Tone? {
        switch self {
        case .expired: .critical
        case .within30Days: .warning
        case .within3Months, .later: nil
        }
    }
}
