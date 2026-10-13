import SwiftUI

/// A tappable row in a card: tinted icon, title and a trailing chevron.
/// Used for Quick filters and Documents, so rows that do the same kind of thing look the same.
struct IconRow: View {
    let title: Text
    let systemImage: String
    /// `chevron.right` opens something in the app. `arrow.up.right` leaves the app.
    var trailingSystemImage = "chevron.right"

    var body: some View {
        HStack(spacing: .spacingMedium) {
            Image(systemName: systemImage)
                .foregroundStyle(.appAccent)
                .frame(width: .iconSize, height: .iconSize)
                .background(.appAccentSoft, in: .rect(cornerRadius: .cornerRadiusMedium))
            title
                .font(.appBody)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: trailingSystemImage)
                .font(.appCaption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, .spacingSmall)
        .contentShape(.rect)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 0) {
        IconRow(title: Text("Open SmPC (PDF)"), systemImage: "doc.richtext")
        Divider()
        IconRow(title: Text("Open on the official site"), systemImage: "safari", trailingSystemImage: "arrow.up.right")
    }
    .cardStyle()
    .padding()
    .background(.appBackground)
}
#endif
