import SwiftUI

/// A small pill, for example "Prescription" or "In 12 days".
/// Warning and critical badges also show an icon, so the meaning never depends on color alone.
struct TagBadge: View {
    enum Tone {
        case accent
        case warning
        case critical

        var color: Color {
            switch self {
            case .accent: .appAccent
            case .warning: .appWarning
            case .critical: .appCritical
            }
        }
    }

    let text: String
    var tone = Tone.accent
    var systemImage: String?

    var body: some View {
        HStack(spacing: .spacingXSmall) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
        }
        .font(.appCaption.weight(.semibold))
        .foregroundStyle(tone.color)
        .padding(.horizontal, .spacingSmall)
        .padding(.vertical, .spacingXSmall)
        .background(tone.color.opacity(0.12), in: .capsule)
    }
}

#if DEBUG
#Preview {
    VStack {
        TagBadge(text: "Prescription")
        TagBadge(text: "In 12 days", tone: .warning, systemImage: "clock")
        TagBadge(text: "Expired 3 weeks ago", tone: .critical, systemImage: "exclamationmark.triangle.fill")
    }
}
#endif
