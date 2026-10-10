import Foundation
import Testing
@testable import DrugRegister

/// Remembers every request the view model sent, so tests can count them.
private actor CallLog {
    struct Call: Sendable {
        let query: DrugQuery
        let page: Int
    }

    private(set) var calls: [Call] = []

    func record(_ query: DrugQuery, _ page: Int) {
        calls.append(Call(query: query, page: page))
    }
}

/// Holds a request until the test opens it, so a test can change the query while it is in flight.
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

/// Fresh defaults per test, so tests never share or touch the real recent searches.
private func makeRecentSearchStore() -> RecentSearchStore {
    RecentSearchStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
}

@MainActor
struct DrugSearchViewModelTests {

    /// 45 drugs and a page size of 20 means three pages: 20, 20 and 5.
    /// The query starts with text, because an empty query shows the home screen and loads nothing.
    private func makeViewModel(
        log: CallLog,
        total: Int = 45,
        failingPage: Int? = nil,
        error: any Error = URLError(.timedOut),
        recentSearchStore: RecentSearchStore = makeRecentSearchStore()
    ) -> DrugSearchViewModel {
        let service = StubDrugService(searchHandler: { query, page, limit in
            await log.record(query, page)
            if page == failingPage { throw error }
            return DrugPage.make(page: page, limit: limit, total: total)
        })
        let viewModel = DrugSearchViewModel(
            service: service,
            recentSearchStore: recentSearchStore,
            pageSize: 20,
            debounce: .zero
        )
        viewModel.query.text = "a"
        return viewModel
    }

    // MARK: - First page

    @Test
    func firstLoadFillsTheList() async {
        let viewModel = makeViewModel(log: CallLog())

        await viewModel.reload()

        #expect(viewModel.drugs.count == 20)
        #expect(viewModel.total == 45)
        #expect(viewModel.hasLoaded)
        #expect(viewModel.canLoadMore)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func reloadIsSkippedWhenNothingChanged() async {
        let log = CallLog()
        let viewModel = makeViewModel(log: log)

        await viewModel.reload()
        await viewModel.reload()   // like coming back from the detail screen
        #expect(await log.calls.count == 1)

        await viewModel.reload(force: true)   // like pull to refresh
        #expect(await log.calls.count == 2)
    }

    @Test
    func changingTheQueryStartsAgainAtPageOne() async {
        let log = CallLog()
        let viewModel = makeViewModel(log: log)
        await viewModel.reload()
        await viewModel.loadNextPage()
        #expect(viewModel.drugs.count == 40)

        viewModel.query.text = "aml"
        await viewModel.reload()

        let last = await log.calls.last
        #expect(last?.query.text == "aml")
        #expect(last?.page == 1)
        #expect(viewModel.drugs.count == 20)
        #expect(viewModel.drugs.first?.id == "1")
    }

    @Test
    func changingAFilterStartsAgainAtPageOne() async {
        let log = CallLog()
        let viewModel = makeViewModel(log: log)
        await viewModel.reload()
        await viewModel.loadNextPage()

        viewModel.query.filters.atcGroup = .c
        await viewModel.reload()

        let last = await log.calls.last
        #expect(last?.query.filters.atcGroup == .c)
        #expect(last?.page == 1)
        #expect(viewModel.drugs.count == 20)
    }

    // MARK: - Home

    @Test
    func emptyQueryShowsHomeAndSendsNoRequest() async {
        let log = CallLog()
        let viewModel = makeViewModel(log: log)
        viewModel.query.text = "   "

        await viewModel.reload()

        #expect(viewModel.query.isEmpty)
        #expect(await log.calls.isEmpty)
        #expect(viewModel.drugs.isEmpty)
        #expect(viewModel.isLoading == false)
    }

    @Test
    func clearingTheTextClearsTheResults() async {
        let viewModel = makeViewModel(log: CallLog())
        await viewModel.reload()
        #expect(viewModel.drugs.count == 20)

        viewModel.query.text = ""
        await viewModel.reload()

        #expect(viewModel.drugs.isEmpty)
        #expect(viewModel.hasLoaded == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func answerThatArrivesAfterGoingHomeIsIgnored() async {
        let gate = Gate()
        let service = StubDrugService(searchHandler: { _, page, limit in
            await gate.wait()
            return DrugPage.make(page: page, limit: limit, total: 45)
        })
        let viewModel = DrugSearchViewModel(
            service: service,
            recentSearchStore: makeRecentSearchStore(),
            debounce: .zero
        )
        viewModel.query.text = "aml"
        let search = Task { await viewModel.reload() }
        while await !gate.hasWaiter { await Task.yield() }

        viewModel.query.text = ""   // the user clears the field while the search is running
        await viewModel.reload()
        await gate.open()
        await search.value

        #expect(viewModel.drugs.isEmpty)
        #expect(viewModel.hasLoaded == false)
        #expect(viewModel.isLoading == false)
    }

    @Test
    func shortcutReplacesFiltersAndLoads() async {
        let log = CallLog()
        let viewModel = makeViewModel(log: log)
        viewModel.query.text = ""
        viewModel.query.filters.productTypes = [.generic]

        viewModel.apply(.prescription)
        await viewModel.reload()

        #expect(viewModel.query.filters == DrugFilters(dispensing: [.prescription]))
        #expect(await log.calls.first?.query.filters.dispensing == [.prescription])
        #expect(viewModel.drugs.count == 20)
    }

    @Test
    func shortcutsSetTheRightFilters() {
        #expect(SearchShortcut.overTheCounter.filters.dispensing == [.otcPharmacy, .otcGeneralSale])
        #expect(SearchShortcut.generics.filters.productTypes == [.generic])
    }

    // MARK: - Barcode

    @Test
    func barcodeReplacesTextAndFilters() async {
        let log = CallLog()
        let viewModel = makeViewModel(log: log)
        viewModel.query.filters.atcGroup = .c

        viewModel.search(barcode: "5310090003085")
        await viewModel.reload()

        #expect(viewModel.query == DrugQuery(ean: "5310090003085"))
        #expect(await log.calls.last?.query.ean == "5310090003085")
    }

    @Test
    func invalidBarcodeSendsNoRequest() async {
        let log = CallLog()
        let viewModel = makeViewModel(log: log)

        viewModel.search(barcode: "12AB")

        #expect(viewModel.query.ean == nil)
        #expect(viewModel.query.text == "a")
        #expect(await log.calls.isEmpty)
    }

    @Test
    func barcodeWithOneMatchIsOpened() async {
        let viewModel = makeViewModel(log: CallLog(), total: 1)

        viewModel.search(barcode: "5310090003085")
        await viewModel.reload()
        #expect(viewModel.scannedDrug?.id == "1")

        viewModel.didOpenScannedDrug()
        #expect(viewModel.scannedDrug == nil)
    }

    @Test
    func barcodeWithSeveralMatchesShowsTheList() async {
        let viewModel = makeViewModel(log: CallLog(), total: 3)

        viewModel.search(barcode: "5310090003085")
        await viewModel.reload()

        #expect(viewModel.scannedDrug == nil)
        #expect(viewModel.drugs.count == 3)
    }

    @Test
    func textSearchWithOneMatchIsNotOpened() async {
        let viewModel = makeViewModel(log: CallLog(), total: 1)

        await viewModel.reload()

        #expect(viewModel.scannedDrug == nil)
    }

    @Test
    func scanningTheSameBarcodeAgainOpensItWithoutARequest() async {
        let log = CallLog()
        let viewModel = makeViewModel(log: log, total: 1)
        viewModel.search(barcode: "5310090003085")
        await viewModel.reload()
        viewModel.didOpenScannedDrug()   // the user opened it and came back

        viewModel.search(barcode: "5310090003085")

        #expect(viewModel.scannedDrug?.id == "1")
        #expect(await log.calls.count == 1)
    }

    // MARK: - Recent searches

    @Test
    func recentSearchIsTrimmedAndNewestFirst() {
        let viewModel = makeViewModel(log: CallLog())

        viewModel.query.text = " paracetamol "
        viewModel.saveRecentSearch()
        viewModel.query.text = "ibuprofen"
        viewModel.saveRecentSearch()

        #expect(viewModel.recentSearches == ["ibuprofen", "paracetamol"])
    }

    @Test
    func repeatedSearchMovesToTheTopOnce() {
        let viewModel = makeViewModel(log: CallLog())

        for text in ["aspirin", "Ibuprofen", "aspirin", "IBUPROFEN"] {
            viewModel.query.text = text
            viewModel.saveRecentSearch()
        }

        #expect(viewModel.recentSearches == ["IBUPROFEN", "aspirin"])
    }

    @Test
    func blankSearchIsNotSaved() {
        let viewModel = makeViewModel(log: CallLog())

        viewModel.query.text = "  "
        viewModel.saveRecentSearch()

        #expect(viewModel.recentSearches.isEmpty)
    }

    @Test
    func recentSearchesAreCappedAndKeptBetweenLaunches() {
        let store = makeRecentSearchStore()
        let viewModel = makeViewModel(log: CallLog(), recentSearchStore: store)

        for index in 1...10 {
            viewModel.query.text = "drug \(index)"
            viewModel.saveRecentSearch()
        }
        #expect(viewModel.recentSearches.count == DrugSearchViewModel.recentSearchLimit)
        #expect(viewModel.recentSearches.first == "drug 10")

        let relaunched = makeViewModel(log: CallLog(), recentSearchStore: store)
        #expect(relaunched.recentSearches == viewModel.recentSearches)

        relaunched.clearRecentSearches()
        #expect(makeViewModel(log: CallLog(), recentSearchStore: store).recentSearches.isEmpty)
    }

    // MARK: - Paging

    @Test
    func nextPagesAreAddedUntilTheEnd() async {
        let log = CallLog()
        let viewModel = makeViewModel(log: log)
        await viewModel.reload()

        await viewModel.loadNextPage()
        #expect(viewModel.drugs.count == 40)

        await viewModel.loadNextPage()
        #expect(viewModel.drugs.count == 45)
        #expect(viewModel.canLoadMore == false)

        await viewModel.loadNextPage()   // nothing left, so no request
        #expect(await log.calls.count == 3)
    }

    @Test
    func nextPageUsesTheQueryOfTheLoadedResults() async {
        let log = CallLog()
        let viewModel = makeViewModel(log: log)
        viewModel.query.text = "aml"
        await viewModel.reload()

        viewModel.query.text = "aml, half typed"   // the user is still typing
        await viewModel.loadNextPage()

        #expect(await log.calls.last?.query.text == "aml")
        #expect(await log.calls.last?.page == 2)
    }

    @Test
    func loadMoreStartsOnlyNearTheEnd() async {
        let log = CallLog()
        let viewModel = makeViewModel(log: log)
        await viewModel.reload()

        await viewModel.loadMoreIfNeeded(after: viewModel.drugs[0])
        #expect(await log.calls.count == 1)

        await viewModel.loadMoreIfNeeded(after: viewModel.drugs[19])
        #expect(await log.calls.count == 2)
    }

    // MARK: - Errors

    @Test
    func failedFirstLoadShowsTheMessage() async {
        let viewModel = makeViewModel(
            log: CallLog(),
            failingPage: 1,
            error: APIError.rateLimited(retryAfter: 12)
        )

        await viewModel.reload()

        #expect(viewModel.errorMessage == String(localized: "Too many requests. Try again in \(12) seconds."))
        #expect(viewModel.drugs.isEmpty)
        #expect(viewModel.hasLoaded == false)
    }

    @Test
    func failedNextPageKeepsTheListAndDoesNotRetryByItself() async {
        let log = CallLog()
        let viewModel = makeViewModel(log: log, failingPage: 2)
        await viewModel.reload()
        let last = viewModel.drugs[19]

        await viewModel.loadMoreIfNeeded(after: last)
        #expect(viewModel.drugs.count == 20)
        #expect(viewModel.errorMessage != nil)
        #expect(await log.calls.count == 2)

        await viewModel.loadMoreIfNeeded(after: last)   // the row appears again
        #expect(await log.calls.count == 2)             // no new request

        await viewModel.loadNextPage()                  // the user taps "Try Again"
        #expect(await log.calls.count == 3)
    }

    @Test
    func cancellationIsNotShownAsAnError() async {
        let viewModel = makeViewModel(log: CallLog(), failingPage: 1, error: CancellationError())

        await viewModel.reload()

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    // MARK: - Dataset info

    @Test
    func metaIsLoadedAndFailureIsSilent() async {
        let good = DrugSearchViewModel(
            service: StubDrugService(),
            recentSearchStore: makeRecentSearchStore(),
            debounce: .zero
        )
        await good.loadMeta()
        #expect(good.meta?.count == 4119)

        let bad = DrugSearchViewModel(
            service: StubDrugService(metaResult: .failure(URLError(.notConnectedToInternet))),
            recentSearchStore: makeRecentSearchStore(),
            debounce: .zero
        )
        await bad.loadMeta()
        #expect(bad.meta == nil)
        #expect(bad.errorMessage == nil)
    }
}
