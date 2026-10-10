import Foundation
import PDFKit
import Testing
@testable import DrugRegister

@MainActor
struct DocumentViewModelTests {

    private let url = URL(string: "https://example.com/leaflet.pdf")!

    private func makeViewModel(
        _ handler: @escaping @Sendable (URL) async throws -> Data
    ) -> DocumentViewModel {
        DocumentViewModel(url: url, service: StubDrugService(documentHandler: handler))
    }

    private func loadedDocument(_ viewModel: DocumentViewModel) -> PDFDocument? {
        if case .loaded(let document) = viewModel.state { document } else { nil }
    }

    private func failureMessage(_ viewModel: DocumentViewModel) -> String? {
        if case .failed(let message) = viewModel.state { message } else { nil }
    }

    @Test
    func pdfIsLoadedFromTheGivenURL() async {
        let requested = URLBox()
        let viewModel = makeViewModel { url in
            await requested.set(url)
            return Data.samplePDF
        }

        await viewModel.load()

        #expect(loadedDocument(viewModel)?.pageCount == 1)
        #expect(await requested.value == url)
    }

    @Test
    func htmlInsteadOfPDFIsAnError() async {
        let viewModel = makeViewModel { _ in Data("<html>Error</html>".utf8) }

        await viewModel.load()

        #expect(failureMessage(viewModel) == String(localized: "This document could not be opened."))
    }

    @Test
    func networkErrorIsShown() async {
        let viewModel = makeViewModel { _ in throw APIError.server(status: 500, message: nil) }

        await viewModel.load()

        #expect(failureMessage(viewModel) == String(localized: "Something went wrong (error \(500))."))
    }

    @Test
    func cancellationIsNotShownAsAnError() async {
        let viewModel = makeViewModel { _ in throw CancellationError() }

        await viewModel.load()

        #expect(failureMessage(viewModel) == nil)
        #expect(loadedDocument(viewModel) == nil)
    }

    @Test
    func retryAfterAnErrorLoadsAgain() async {
        let attempts = Counter()
        let viewModel = makeViewModel { _ in
            if await attempts.next() == 1 { throw URLError(.timedOut) }
            return Data.samplePDF
        }

        await viewModel.load()
        #expect(failureMessage(viewModel) != nil)

        await viewModel.load()   // the user taps "Try Again"
        #expect(loadedDocument(viewModel) != nil)
    }

    @Test
    func loadedDocumentIsNotLoadedAgain() async {
        let attempts = Counter()
        let viewModel = makeViewModel { _ in
            _ = await attempts.next()
            return Data.samplePDF
        }

        await viewModel.load()
        await viewModel.load()   // like coming back to the screen

        #expect(await attempts.count == 1)
    }
}

private actor URLBox {
    private(set) var value: URL?

    func set(_ url: URL) {
        value = url
    }
}

private actor Counter {
    private(set) var count = 0

    /// Counts one more call and returns the new count.
    func next() -> Int {
        count += 1
        return count
    }
}
