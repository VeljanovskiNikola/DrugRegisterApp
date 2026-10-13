import CoreGraphics

/// Use `.padding(.horizontal, .spacingMedium)` instead of magic numbers.
extension CGFloat {
    static let spacingXSmall: CGFloat = 4
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 16
    static let spacingLarge: CGFloat = 24
    static let spacingXLarge: CGFloat = 40

    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16

    /// Size of the round icon background in list rows and empty states.
    static let iconSize: CGFloat = 32

    /// The smallest height (and width, for icon buttons) a tap target should have.
    static let minTapSize: CGFloat = 44

    /// The widest content gets on iPad. Wider cards and lines are hard to read.
    static let maxContentWidth: CGFloat = 700
}
