import SwiftUI

/// A small pill, for example "Prescription" or "In 12 days".
/// Warning and critical badges also show an icon, so the meaning never depends on color alone.
struct TagBadge: View {
    enum Tone {
        case accent
        case warning
        case critical

        /// The background behind the text, used at low opacity.
        var tint: Color {
            switch self {
            case .accent: .appAccent
            case .warning: .appWarning
            case .critical: .appCritical
            }
        }

        /// Text and icons, inside the badge or on their own. The tint colors are too light for that.
        var textColor: Color {
            switch self {
            case .accent: .appAccentText
            case .warning: .appWarningText
            case .critical: .appCriticalText
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
        .foregroundStyle(tone.textColor)
        .padding(.horizontal, .spacingSmall)
        .padding(.vertical, .spacingXSmall)
        .background(tone.tint.opacity(0.12), in: .capsule)
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
