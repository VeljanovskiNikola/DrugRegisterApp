import SwiftUI

/// The content of one drug in a list. Search wraps it in a card, Favorites puts it in a List.
struct DrugRow: View {
    let drug: Drug

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingXSmall) {
            HStack(alignment: .firstTextBaseline, spacing: .spacingSmall) {
                Text(drug.nameLatin)
                    .font(.appHeadline)
                    .foregroundStyle(.primary)
                Spacer(minLength: .spacingSmall)
                if let badge = drug.dispensing.badge {
                    TagBadge(text: badge)
                }
            }

            Text(drug.genericName)
                .font(.appSubheadline)
                .foregroundStyle(.primary)

            HStack(alignment: .firstTextBaseline) {
                Text([drug.strength, drug.pharmaceuticalForm].compactMap { $0 }.joined(separator: " · "))
                Spacer(minLength: .spacingSmall)
                if let price = drug.prices.retailWithVat {
                    Text(price, format: .currency(code: "MKD"))
                        .foregroundStyle(.primary)
                }
            }
            .font(.appCaption)
            .foregroundStyle(.appSecondaryText)

            // Only cut on screen. The detail screen shows the full text.
            Label(drug.manufacturers, systemImage: "building.2")
                .font(.appCaption)
                .foregroundStyle(.appSecondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: .spacingMedium) {
            ForEach(Drug.previewList) { DrugRow(drug: $0).cardStyle() }
        }
        .padding()
    }
    .background(.appBackground)
}
#endif
