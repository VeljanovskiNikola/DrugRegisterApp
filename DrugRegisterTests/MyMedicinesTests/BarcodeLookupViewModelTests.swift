import Foundation
import Testing
@testable import DrugRegister

/// Remembers every query the lookup sent.
private actor QueryLog {
    private(set) var queries: [DrugQuery] = []

    func record(_ query: DrugQuery) {
        queries.append(query)
    }
}

/// Holds the first request until the test opens it, so a second scan can overtake it.
private actor Gate {
    private var continuation: CheckedContinuation<Void, Never>?

    var hasWaiter: Bool { continuation != nil }

    func wait() async {
        await withCheckedContinuation { continuation = $0 }
    }

    func open() {
        continuation?.resume()
        continuation = nil
    }
}

private func page(_ drugs: [Drug]) -> DrugPage {
    DrugPage(data: drugs, pagination: .init(page: 1, limit: 10, total: drugs.count, totalPages: 1))
}

@MainActor
struct BarcodeLookupViewModelTests {

    private func makeViewModel(log: QueryLog = QueryLog(), drugs: [Drug]) -> BarcodeLookupViewModel {
        BarcodeLookupViewModel(service: StubDrugService(searchHandler: { query, _, _ in
            await log.record(query)
            return page(drugs)
        }))
    }

    @Test
    func oneMatchOpensTheForm() async {
        let drug = Drug.make(id: "51071")
        let viewModel = makeViewModel(drugs: [drug])

        await viewModel.lookUp("5310090003085")

        #expect(viewModel.outcome == .found(DrugSnapshot(drug)))
        #expect(viewModel.isLooking == false)
    }

    @Test
    func severalMatchesLetTheUserChoose() async {
        let drugs = [Drug.make(id: "1"), Drug.make(id: "2")]
        let viewModel = makeViewModel(drugs: drugs)

        await viewModel.lookUp("5310090003085")

        #expect(viewModel.outcome == .choose(drugs))
    }

    @Test
    func noMatchNamesTheNormalizedBarcode() async {
        let viewModel = makeViewModel(drugs: [])

        await viewModel.lookUp("  53100900  ")

        #expect(viewModel.outcome == .notFound(ean: "53100900"))
    }

    @Test
    func searchesByTheBarcodeAlone() async {
        let log = QueryLog()
        let viewModel = makeViewModel(log: log, drugs: [])

        await viewModel.lookUp("5310090003085")

        #expect(await log.queries == [DrugQuery(ean: "5310090003085")])
    }

    @Test
    func invalidCodeSendsNoRequest() async {
        let log = QueryLog()
        let viewModel = makeViewModel(log: log, drugs: [])

        await viewModel.lookUp("12AB")

        #expect(await log.queries.isEmpty)
        #expect(viewModel.outcome == nil)
    }

    @Test
    func errorShowsTheMessageAndCanBeRetried() async {
        let log = QueryLog()
        let viewModel = BarcodeLookupViewModel(service: StubDrugService(searchHandler: { query, _, _ in
            await log.record(query)
            throw APIError.rateLimited(retryAfter: 12)
        }))

        await viewModel.lookUp("5310090003085")
        #expect(viewModel.outcome == .failed(APIError.rateLimited(retryAfter: 12).localizedDescription))

        await viewModel.retry()
        #expect(await log.queries.count == 2)
        #expect(await log.queries.last == DrugQuery(ean: "5310090003085"))
    }

    @Test
    func cancellationIsNotAnError() async {
        let viewModel = BarcodeLookupViewModel(service: StubDrugService(searchHandler: { _, _, _ in
            throw URLError(.cancelled)
        }))

        await viewModel.lookUp("5310090003085")

        #expect(viewModel.outcome == nil)
        #expect(viewModel.isLooking == false)
    }

    @Test
    func slowAnswerFromAnOldScanIsIgnored() async {
        let gate = Gate()
        let first = Drug.make(id: "1")
        let second = Drug.make(id: "2")
        let viewModel = BarcodeLookupViewModel(service: StubDrugService(searchHandler: { query, _, _ in
            if query.ean == "11111111" {
                await gate.wait()
                return page([first])
            }
            return page([second])
        }))

        let slow = Task { await viewModel.lookUp("11111111") }
        while await !gate.hasWaiter { await Task.yield() }
        await viewModel.lookUp("22222222")
        await gate.open()
        await slow.value

        #expect(viewModel.outcome == .found(DrugSnapshot(second)))
        #expect(viewModel.isLooking == false)
    }

    @Test
    func clearOutcomeResets() async {
        let viewModel = makeViewModel(drugs: [])
        await viewModel.lookUp("5310090003085")

        viewModel.clearOutcome()

        #expect(viewModel.outcome == nil)
    }
}
