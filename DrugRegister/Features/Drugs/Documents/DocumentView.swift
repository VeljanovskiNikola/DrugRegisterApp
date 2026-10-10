import SwiftUI

/// Shows a register PDF inside the app. The file is read into memory and never saved.
struct DocumentView: View {
    let document: DrugDocument
    @State private var viewModel: DocumentViewModel

    init(document: DrugDocument, service: any DrugService) {
        self.document = document
        _viewModel = State(initialValue: DocumentViewModel(url: document.url, service: service))
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.appBackground)
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Shares the official link, so the PDF stays on the register's site.
                    ShareLink(item: document.url) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading document…")
        case .loaded(let pdf):
            PDFKitView(document: pdf)
                .ignoresSafeArea(edges: .bottom)
        case .failed(let message):
            ErrorStateView(message: message, systemImageName: "exclamationmark.circle") {
                Task { await viewModel.load() }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        DocumentView(
            document: DrugDocument(kind: .patientLeaflet, url: URL(string: "https://example.com/leaflet.pdf")!),
            service: StubDrugService()
        )
    }
}
#endif
