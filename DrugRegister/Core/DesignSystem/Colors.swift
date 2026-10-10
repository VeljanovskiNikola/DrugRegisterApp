import SwiftUI

/// Works both as `Color.appAccent` and as `.foregroundStyle(.appAccent)`.
/// The accent is teal (#0A7E8C), set in the asset catalog with a lighter variant for dark mode.
extension ShapeStyle where Self == Color {
    static var appAccent: Color { .accentColor }
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
}
