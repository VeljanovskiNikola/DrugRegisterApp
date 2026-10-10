import Foundation
import Observation
import PDFKit

@MainActor
@Observable
final class DocumentViewModel {
    enum State {
        case loading
        case loaded(PDFDocument)
        case failed(String)
    }

    private(set) var state = State.loading

    private let url: URL
    private let service: any DrugService

    init(url: URL, service: any DrugService) {
        self.url = url
        self.service = service
    }

    /// Called from `.task`, which runs again when the screen reappears.
    /// A document that is already shown is not loaded again.
    func load() async {
        if case .loaded = state { return }
        state = .loading

        do {
            let data = try await service.document(at: url)
            // The site may answer with an HTML error page and status 200, so check the bytes.
            guard let document = PDFDocument(data: data) else {
                state = .failed(String(localized: "This document could not be opened."))
                return
            }
            state = .loaded(document)
        } catch {
            // Leaving the screen cancels the load. `.task` starts it again on return.
            guard !error.isCancellation else { return }
            state = .failed(error.localizedDescription)
        }
    }
}
