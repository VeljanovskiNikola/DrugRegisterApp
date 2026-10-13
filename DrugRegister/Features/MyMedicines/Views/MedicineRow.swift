import SwiftUI

struct MedicineRow: View {
    let entry: ExpiryEntry
    /// "мај 2027". Formatted by the view model, which owns the calendar.
    let expiryText: String

    private var medicine: Medicine { entry.medicine }

    var body: some View {
        HStack(alignment: .top, spacing: .spacingMedium) {
            Image(systemName: entry.group.systemImage)
                .foregroundStyle(entry.group.badgeTone?.textColor ?? .appSecondaryText)
                .frame(width: .iconSize)

            VStack(alignment: .leading, spacing: .spacingXSmall) {
                Text(medicine.drug.nameLatin)
                    .font(.appHeadline)
                    .foregroundStyle(.primary)
                if !medicine.drug.strengthAndForm.isEmpty {
                    Text(medicine.drug.strengthAndForm)
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                }
                Text("Expiry date: \(expiryText)")
                    .font(.appSubheadline)
                    .foregroundStyle(.primary)

                statusLabel

                if medicine.packCount > 1 {
                    Text("\(medicine.packCount) packs")
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                }
                if !medicine.note.isEmpty {
                    Text(medicine.note)
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, .spacingXSmall)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var statusLabel: some View {
        let text = ExpiryRules.label(daysLeft: entry.daysLeft)
        if let tone = entry.group.badgeTone {
            TagBadge(text: text, tone: tone, systemImage: entry.group.systemImage)
        } else {
            Text(text)
                .font(.appCaption)
                .foregroundStyle(.appSecondaryText)
        }
    }
}
