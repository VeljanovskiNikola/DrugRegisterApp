import SwiftUI

/// The + flow on My medicines: scan the box (or type the number), find the drug, open the add form.
/// Each lookup outcome gets its own sheet, dialog or alert here, so the list view stays short.
struct AddByScan: ViewModifier {
    let lookup: BarcodeLookupViewModel
    @Binding var isScanning: Bool
    @Binding var adding: DrugSnapshot?
    let services: MedicineServices
    let onSaved: () -> Void

    @Environment(AppRouter.self) private var router

    func body(content: Content) -> some View {
        content
            .overlay {
                if lookup.isLooking {
                    ProgressView()
                        .padding(.spacingLarge)
                        .background(.regularMaterial, in: .rect(cornerRadius: .cornerRadiusMedium))
                }
            }
            .sheet(isPresented: $isScanning) {
                BarcodeScannerSheet { code in
                    Task { await lookup.lookUp(code) }
                }
            }
            .sheet(item: $adding) { drug in
                MedicineFormView(mode: .add(drug), services: services, onSaved: onSaved)
            }
            // One match: open the form right away. The view model never presents anything itself.
            .onChange(of: lookup.outcome) { _, outcome in
                guard case .found(let drug) = outcome else { return }
                lookup.clearOutcome()
                adding = drug
            }
            .confirmationDialog(
                "Choose the drug",
                isPresented: isShowing(\.choices),
                titleVisibility: .visible,
                presenting: lookup.outcome?.choices
            ) { drugs in
                ForEach(drugs) { drug in
                    // Names and strength exactly as the register sends them.
                    Button(Self.title(for: DrugSnapshot(drug))) {
                        adding = DrugSnapshot(drug)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert(
                "No drug with this barcode",
                isPresented: isShowing(\.notFoundEAN),
                presenting: lookup.outcome?.notFoundEAN
            ) { _ in
                Button("Scan again") { isScanning = true }
                Button("Go to Search") { router.showSearch() }
                Button("Cancel", role: .cancel) {}
            } message: { ean in
                Text("The barcode \(ean) is not in the register.")
            }
            .alert(
                "Something went wrong",
                isPresented: isShowing(\.failureMessage),
                presenting: lookup.outcome?.failureMessage
            ) { _ in
                Button("Try Again") { Task { await lookup.retry() } }
                Button("Cancel", role: .cancel) {}
            } message: { message in
                Text(message)
            }
    }

    /// Shown while the outcome has that case. Closing it clears the outcome.
    private func isShowing<Value>(_ value: KeyPath<BarcodeLookupViewModel.Outcome, Value?>) -> Binding<Bool> {
        Binding(
            get: { lookup.outcome?[keyPath: value] != nil },
            set: { if !$0 { lookup.clearOutcome() } }
        )
    }

    /// A plain `String`, so the API text is shown as is and never looked up in the catalog.
    private static func title(for drug: DrugSnapshot) -> String {
        drug.strengthAndForm.isEmpty ? drug.nameLatin : drug.nameLatin + " · " + drug.strengthAndForm
    }
}

private extension BarcodeLookupViewModel.Outcome {
    var choices: [Drug]? {
        if case .choose(let drugs) = self { drugs } else { nil }
    }

    var notFoundEAN: String? {
        if case .notFound(let ean) = self { ean } else { nil }
    }

    var failureMessage: String? {
        if case .failed(let message) = self { message } else { nil }
    }
}
