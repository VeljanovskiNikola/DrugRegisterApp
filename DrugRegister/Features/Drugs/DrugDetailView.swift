import SwiftUI

/// No view model: this screen only shows a drug it already has.
/// Search results carry the full drug, so no extra request is needed.
struct DrugDetailView: View {
    let drug: Drug
    let medicines: MedicineServices

    @Environment(FavoritesStore.self) private var favorites
    @Environment(AppRouter.self) private var router
    @State private var isAddingMedicine = false
    @State private var didAddMedicine = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingLarge) {
                header
                addToMyMedicines
                InfoCard(title: "Overview", items: [
                    InfoItem(title: "Active ingredient", value: drug.genericName),
                    InfoItem(title: "ATC code", value: drug.atcCode),
                    InfoItem(title: "Manufacturer", value: drug.manufacturers),
                    InfoItem(title: "Marketing authorization holder", value: drug.marketingAuthorizationHolder),
                    InfoItem(title: "Registration number", value: drug.authorization.number),
                    InfoItem(title: "Pack size", value: drug.packaging),
                ])
                documents
                prices
                textCard("Composition", drug.composition)
                textCard("Dosage", drug.dosage)
                textCard("Special warning", drug.specialWarning)
                moreDetails

                Text("Information from the public drug register of North Macedonia. It is not medical advice. Ask a doctor or a pharmacist.")
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
            }
            .padding(.spacingMedium)
        }
        .background(.appBackground)
        .navigationTitle(drug.nameLatin)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .sheet(isPresented: $isAddingMedicine) {
            MedicineFormView(mode: .add(DrugSnapshot(drug)), services: medicines) {
                didAddMedicine = true
            }
        }
        .sensoryFeedback(.success, trigger: didAddMedicine) { _, added in added }
        // Keeps a saved copy up to date when the user opens the drug from search.
        .onAppear { favorites.update(drug) }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            ShareLink(item: drug.detailUrl, subject: Text(drug.nameLatin)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            let isFavorite = favorites.contains(drug)
            Button {
                favorites.toggle(drug)
            } label: {
                Label(
                    isFavorite ? "Remove from favorites" : "Add to favorites",
                    systemImage: isFavorite ? "heart.fill" : "heart"
                )
            }
            .sensoryFeedback(.selection, trigger: isFavorite)
        }
    }

    // MARK: - Sections

    private var addToMyMedicines: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            Button {
                isAddingMedicine = true
            } label: {
                Label("Add to my medicines", systemImage: "cross.case")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            if didAddMedicine {
                Label("Added to my medicines", systemImage: "checkmark.circle.fill")
                    .font(.appCaption)
                    .foregroundStyle(.appAccent)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            Text(drug.nameLatin)
                .font(.appTitle)
                .textSelection(.enabled)
            Text(drug.nameCyrillic)
                .font(.appBody)
                .foregroundStyle(.appSecondaryText)
            Text([drug.strength, drug.pharmaceuticalForm].compactMap { $0 }.joined(separator: " · "))
                .font(.appSubheadline)

            HStack(spacing: .spacingSmall) {
                if let badge = drug.dispensing.badge {
                    TagBadge(text: badge)
                }
                if drug.productType != .unknown {
                    TagBadge(text: drug.productType.title)
                }
                if drug.isOnPositiveList {
                    TagBadge(text: String(localized: "Positive list"))
                }
            }
        }
        .cardStyle()
    }

    /// The PDFs stay on the register's own site. They open in the app's PDF viewer,
    /// because the site sends them as downloads and Safari would save them to the phone.
    private var documents: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            if let url = drug.documents.url(for: .patientLeaflet) {
                Button {
                    router.showDocument(DrugDocument(kind: .patientLeaflet, url: url))
                } label: {
                    Label("Open leaflet (PDF)", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            if let url = drug.documents.url(for: .smpc) {
                Button {
                    router.showDocument(DrugDocument(kind: .smpc, url: url))
                } label: {
                    Label("Open SmPC (PDF)", systemImage: "doc.richtext")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            // Full-width rows, at least 44 pt tall, so the two small links are easy to tell apart.
            if let url = drug.documents.url(for: .label) {
                Button {
                    router.showDocument(DrugDocument(kind: .label, url: url))
                } label: {
                    linkRow("Label and packaging (PDF)")
                }
            }
            Link(destination: drug.detailUrl) {
                linkRow("Open on the official site")
            }
        }
    }

    private func linkRow(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.appSubheadline)
            .frame(maxWidth: .infinity, minHeight: .minTapSize, alignment: .leading)
            .contentShape(.rect)
    }

    private var prices: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            SectionHeader("Prices")
            VStack(spacing: .spacingSmall) {
                PriceRow(title: "Retail, with VAT", amount: drug.prices.retailWithVat)
                Divider()
                PriceRow(title: "Wholesale, without VAT", amount: drug.prices.wholesaleExVat)
                Divider()
                PriceRow(title: "Reference", amount: drug.prices.reference)
            }
            .cardStyle()
        }
    }

    @ViewBuilder
    private func textCard(_ title: LocalizedStringKey, _ text: String?) -> some View {
        if let text, !text.isEmpty {
            VStack(alignment: .leading, spacing: .spacingSmall) {
                SectionHeader(title)
                Text(text)
                    .font(.appBody)
                    .textSelection(.enabled)
                    .cardStyle()
            }
        }
    }

    private var moreDetails: some View {
        InfoCard(title: "More details", items: [
            InfoItem(title: "Dispensing", value: drug.dispensing == .unknown ? nil : drug.dispensing.title),
            InfoItem(title: "Extended ATC code", value: drug.extendedAtcCode),
            InfoItem(title: "EAN", value: drug.ean),
            InfoItem(title: "Fund code", value: drug.fundCode),
            InfoItem(title: "Specialist recommendation", value: drug.specialistRecommendation),
            InfoItem(title: "Manufacturing sites", value: drug.manufacturingSites),
            InfoItem(title: "Authorization issued", value: drug.authorization.issuedDate?.dateOnlyFormatted),
            // The validity of the register decision. Not a package expiry date, so it is kept
            // out of the overview and labeled so it cannot be mistaken for one.
            InfoItem(title: "Decision valid until", value: drug.authorization.expiryDate?.dateOnlyFormatted),
            InfoItem(title: "Renewal", value: drug.authorization.renewalDate?.dateOnlyFormatted),
            InfoItem(title: "Braille on package", value: yesNo(drug.hasBraille)),
            InfoItem(title: "Has variations", value: yesNo(drug.hasVariations)),
        ])
    }

    private func yesNo(_ value: Bool) -> String {
        value ? String(localized: "Yes") : String(localized: "No")
    }
}

private struct PriceRow: View {
    let title: LocalizedStringKey
    let amount: Double?

    var body: some View {
        LabeledContent(title) {
            if let amount {
                Text(amount, format: .currency(code: "MKD"))
                    .foregroundStyle(.primary)
            } else {
                Text("No price set")
                    .foregroundStyle(.appSecondaryText)
            }
        }
        .font(.appBody)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        DrugDetailView(drug: .sample, medicines: .preview(medicines: []))
    }
    .environment(FavoritesStore(fileURL: nil))
    .environment(AppRouter())
}
#endif
