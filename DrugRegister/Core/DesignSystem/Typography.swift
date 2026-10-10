import SwiftUI

/// Use `.font(.appBody)` instead of `.font(.system(size: 16))`.
/// These are built on Dynamic Type styles, so text still scales with user settings.
extension Font {
    static var appTitle: Font { .title2.weight(.bold) }
    static var appSectionTitle: Font { .title3.weight(.semibold) }
    static var appHeadline: Font { .headline }
    static var appBody: Font { .body }
    static var appSubheadline: Font { .subheadline }
    static var appCaption: Font { .footnote }
}
