import SwiftUI

/// Works both as `Color.appAccent` and as `.foregroundStyle(.appAccent)`.
/// The accent is teal (#0A7E8C), set in the asset catalog with a lighter variant for dark mode.
extension ShapeStyle where Self == Color {
    static var appAccent: Color { .accentColor }
    /// A pale accent behind an accent icon, for example in the quick filter rows.
    static var appAccentSoft: Color { Color.accentColor.opacity(.softTintOpacity) }
    static var appSecondaryText: Color { .secondary }
    /// Soft gray behind cards and lists.
    static var appBackground: Color { Color(.systemGroupedBackground) }
    /// White in light mode.
    static var appCardBackground: Color { Color(.secondarySystemGroupedBackground) }
    static var appSeparator: Color { Color(.separator) }
    /// Something needs attention soon, for example a pack that expires within 30 days.
    static var appWarning: Color { .orange }
    /// Something is already past, for example an expired pack.
    static var appCritical: Color { .red }

    // Text on a light tint of the color above. Darker in light mode so small text reaches
    // WCAG AA (4.5:1) on the 12% tint. Dark mode uses the same color as the tint.
    static var appAccentText: Color { Color(.badgeAccentText) }
    static var appWarningText: Color { Color(.badgeWarningText) }
    static var appCriticalText: Color { Color(.badgeCriticalText) }
}

extension Double {
    /// How strong a pale tint is, for example `.appAccentSoft` or the background of a badge.
    static let softTintOpacity = 0.12
}
