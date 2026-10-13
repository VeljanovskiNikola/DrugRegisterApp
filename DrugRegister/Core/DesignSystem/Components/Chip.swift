import SwiftUI

/// A tappable pill, for example a recent search.
struct Chip: View {
    let title: String
    var systemImage: String?
    /// Shown after the title, for example an × on a chip that removes something.
    var trailingSystemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingXSmall) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.appSecondaryText)
                }
                Text(title)
                    .lineLimit(1)
                if let trailingSystemImage {
                    Image(systemName: trailingSystemImage)
                        .foregroundStyle(.appSecondaryText)
                }
            }
            .font(.appSubheadline)
            .foregroundStyle(.primary)
            .padding(.horizontal, .spacingMedium)
            .padding(.vertical, .spacingSmall)
            .frame(minHeight: .minTapSize)
            .background(.appCardBackground, in: .capsule)
            .overlay(Capsule().strokeBorder(.appSeparator))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    Chip(title: "paracetamol", systemImage: "clock.arrow.circlepath") {}
        .padding()
        .background(.appBackground)
}
#endif
