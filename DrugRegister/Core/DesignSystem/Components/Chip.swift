import SwiftUI

/// A tappable pill, for example a recent search.
struct Chip: View {
    let title: String
    var systemImage: String?
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
            }
            .font(.appSubheadline)
            .foregroundStyle(.primary)
            .padding(.horizontal, .spacingMedium)
            .padding(.vertical, .spacingSmall)
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
