import Foundation
import Testing
@testable import DrugRegister

@MainActor
struct SavedDrugViewModelTests {

    private let snapshot = DrugSnapshot(.sample)

    private func makeViewModel(_ handler: @escaping @Sendable (String) async throws -> Drug) -> SavedDrugViewModel {
        SavedDrugViewModel(snapshot: snapshot, service: StubDrugService(drugHandler: handler))
    }

    @Test
    func freshDrugIsLoadedByItsID() async {
        let viewModel = makeViewModel { id in Drug.make(id: id, name: "FRESH") }

        await viewModel.load()

        #expect(viewModel.state == .loaded(Drug.make(id: snapshot.id, name: "FRESH")))
    }

    @Test
    func notFoundMeansTheDrugLeftTheRegister() async {
        let viewModel = makeViewModel { _ in throw APIError.server(status: 404, message: "No drug with id 51071.") }

        await viewModel.load()

        #expect(viewModel.state == .removed)
    }

    @Test
    func noConnectionFallsBackToTheSnapshot() async {
        let viewModel = makeViewModel { _ in throw URLError(.notConnectedToInternet) }

        await viewModel.load()

        #expect(viewModel.state == .offline)
    }

    @Test
    func cancellationKeepsLoading() async {
        let viewModel = makeViewModel { _ in throw CancellationError() }

        await viewModel.load()

        #expect(viewModel.state == .loading)
    }
}
