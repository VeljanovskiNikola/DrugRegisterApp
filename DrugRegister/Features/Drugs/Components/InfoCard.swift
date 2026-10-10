import SwiftUI

/// One title and value in an `InfoCard`.
struct InfoItem {
    let title: LocalizedStringKey
    let value: String?
}

/// A card with a title and label/value rows split by thin lines.
/// Rows with a `nil` or empty value are left out, so the detail screen needs no `if` per field.
struct InfoCard: View {
    let title: LocalizedStringKey
    let items: [InfoItem]

    private var visibleItems: [InfoItem] {
        items.filter { !($0.value ?? "").isEmpty }
    }

    var body: some View {
        if !visibleItems.isEmpty {
            VStack(alignment: .leading, spacing: .spacingSmall) {
                SectionHeader(title)
                VStack(alignment: .leading, spacing: .spacingSmall) {
                    ForEach(Array(visibleItems.enumerated()), id: \.offset) { index, item in
                        if index > 0 {
                            Divider()
                        }
                        VStack(alignment: .leading, spacing: .spacingXSmall) {
                            Text(item.title)
                                .font(.appCaption)
                                .foregroundStyle(.appSecondaryText)
                            Text(item.value ?? "")
                                .font(.appBody)
                                .textSelection(.enabled)
                        }
                    }
                }
                .cardStyle()
            }
        }
    }
}

#if DEBUG
#Preview {
    InfoCard(title: "Overview", items: [
        InfoItem(title: "ATC code", value: "C08CA01"),
        InfoItem(title: "Registration number", value: nil),
        InfoItem(title: "Pack size", value: "20 таблети (блистер 2 х 10)/кутија"),
    ])
    .padding()
    .background(.appBackground)
}
#endif
