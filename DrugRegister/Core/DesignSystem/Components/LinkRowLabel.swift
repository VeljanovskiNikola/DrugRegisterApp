import SwiftUI

/// The label of a small text link shown as a full-width row, at least 44 pt tall,
/// so links stacked close together are still easy to tap.
struct LinkRowLabel: View {
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.appSubheadline)
            .frame(maxWidth: .infinity, minHeight: .minTapSize, alignment: .leading)
            .contentShape(.rect)
    }
}
