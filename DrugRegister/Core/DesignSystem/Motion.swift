import SwiftUI

/// Use `.animation(.appStandard, value: ...)` instead of a raw duration.
extension Animation {
    /// Quick and calm. For views that appear, disappear or change state.
    static let appStandard = Animation.snappy(duration: 0.25)
}
