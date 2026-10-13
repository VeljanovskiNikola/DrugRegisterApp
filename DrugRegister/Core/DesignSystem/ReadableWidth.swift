import SwiftUI

extension View {
    /// Caps the width at `.maxContentWidth` and centers it. On iPhone nothing changes.
    /// Put it on the content inside a scroll view, so the whole screen still scrolls.
    func readableWidth() -> some View {
        frame(maxWidth: .maxContentWidth)
            .frame(maxWidth: .infinity)
    }
}
