import SwiftUI

/// Opens the drug of a saved medicine. Shows the full detail screen with fresh register data,
/// or the saved snapshot when there is no connection or the drug left the register.
struct SavedDrugView: View {
    @State private var viewModel: SavedDrugViewModel
    private let medicines: MedicineServices

    init(snapshot: DrugSnapshot, service: any DrugService, medicines: MedicineServices) {
        _viewModel = State(initialValue: SavedDrugViewModel(snapshot: snapshot, service: service))
        self.medicines = medicines
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.appBackground)
                    .navigationTitle(viewModel.snapshot.nameLatin)
                    .navigationBarTitleDisplayMode(.inline)
            case .loaded(let drug):
                DrugDetailView(drug: drug, medicines: medicines)
            case .offline:
                SavedDrugFallbackView(
                    snapshot: viewModel.snapshot,
                    notice: "No connection. This is the information saved with your medicine.",
                    systemImage: "wifi.slash",
                    retry: { Task { await viewModel.load() } }
                )
            case .removed:
                SavedDrugFallbackView(
                    snapshot: viewModel.snapshot,
                    notice: "This drug is no longer in the register. This is the information saved with your medicine.",
                    systemImage: "archivebox",
                    retry: nil
                )
            }
        }
        .task { await viewModel.load() }
    }
}

private struct SavedDrugFallbackView: View {
    let snapshot: DrugSnapshot
    let notice: LocalizedStringKey
    let systemImage: String
    let retry: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingLarge) {
                VStack(alignment: .leading, spacing: .spacingSmall) {
                    Text(snapshot.nameLatin)
                        .font(.appTitle)
                    Text(snapshot.nameCyrillic)
                        .font(.appBody)
                        .foregroundStyle(.appSecondaryText)
                    if !snapshot.strengthAndForm.isEmpty {
                        Text(snapshot.strengthAndForm)
                            .font(.appSubheadline)
                    }
                }
                .cardStyle()

                Label(notice, systemImage: systemImage)
                    .font(.appSubheadline)
                    .foregroundStyle(.appSecondaryText)

                if let retry {
                    Button("Try Again", action: retry)
                        .buttonStyle(.bordered)
                }
                Link(destination: snapshot.detailUrl) {
                    LinkRowLabel("Open on the official site")
                }

                Text("Check the package or ask a pharmacist.")
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
            }
            .padding(.spacingMedium)
        }
        .background(.appBackground)
        .navigationTitle(snapshot.nameLatin)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview("Offline") {
    NavigationStack {
        SavedDrugView(
            snapshot: DrugSnapshot(.sample),
            service: StubDrugService(drugHandler: { _ in throw URLError(.notConnectedToInternet) }),
            medicines: .preview(medicines: [])
        )
    }
    .environment(AppRouter())
    .environment(FavoritesStore(fileURL: nil))
}
#endif
