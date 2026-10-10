import Foundation
import Observation

@MainActor
@Observable
final class DrugSearchViewModel {
    var query = DrugQuery()
    private(set) var meta: RegisterMeta?
    /// Newest first.
    private(set) var recentSearches: [String]
    /// A scanned barcode matched exactly one drug. The view opens it, then calls `didOpenScannedDrug()`.
    private(set) var scannedDrug: Drug?

    /// `nil` until a search finishes, and again on the home screen or after a failed first page.
    private var results: Results?
    private var status = Status.idle
    /// Goes up on every new search. A slow answer from an old search is ignored.
    private var generation = 0

    private let service: any DrugService
    private let recentSearchStore: RecentSearchStore
    private let pageSize: Int
    private let debounce: Duration

    static let recentSearchLimit = 8

    init(
        service: any DrugService,
        recentSearchStore: RecentSearchStore,
        pageSize: Int = 20,
        debounce: Duration = .milliseconds(300)
    ) {
        self.service = service
        self.recentSearchStore = recentSearchStore
        self.recentSearches = recentSearchStore.load()
        self.pageSize = pageSize
        self.debounce = debounce
    }

    // MARK: - State for the view

    var drugs: [Drug] { results?.drugs ?? [] }
    var total: Int { results?.pagination.total ?? 0 }
    /// True once one search has finished. Used to tell "no results" from "not loaded yet".
    var hasLoaded: Bool { results != nil }
    /// True while the first page of a search is loading.
    var isLoading: Bool { status == .loading }
    var isLoadingMore: Bool { status == .loadingMore }

    var errorMessage: String? {
        if case .failed(let message) = status { message } else { nil }
    }

    var canLoadMore: Bool {
        guard let pagination = results?.pagination else { return false }
        return pagination.page < pagination.totalPages
    }

    // MARK: - Search

    /// Called from `.task(id: query)`. SwiftUI cancels the old task when the query changes,
    /// so waiting here is the debounce and the cancellation is free.
    ///
    /// `.task` also runs again when you come back from the detail screen.
    /// We skip the request when we already have results for this query.
    ///
    /// An empty query shows the home screen, so it clears the results and sends no request.
    func reload(force: Bool = false) async {
        if query.isEmpty {
            clearResults()
            return
        }
        if !force, results?.query == query, errorMessage == nil { return }

        if !force {
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
        }

        generation += 1
        let generation = generation
        let requestQuery = query
        status = .loading

        do {
            let page = try await service.search(requestQuery, page: 1, limit: pageSize)
            guard generation == self.generation else { return }

            results = Results(query: requestQuery, drugs: page.data, pagination: page.pagination)
            status = .idle
            if requestQuery.ean != nil, page.data.count == 1 {
                scannedDrug = page.data.first
            }
        } catch {
            guard generation == self.generation else { return }
            guard !error.isCancellation else {
                status = .idle
                return
            }
            results = nil
            status = .failed(error.localizedDescription)
        }
    }

    private func clearResults() {
        // A search still in flight must not fill the list after we went back home.
        generation += 1
        results = nil
        status = .idle
    }

    // MARK: - Barcode

    /// Searches by the barcode alone. Text and filters are cleared, because the barcode
    /// already names one product and they could hide it.
    func search(barcode: String) {
        guard let ean = EAN.normalized(barcode) else { return }
        let barcodeQuery = DrugQuery(ean: ean)

        // The same barcode again: the query does not change, so `.task(id:)` would not run.
        if results?.query == barcodeQuery, drugs.count == 1 {
            scannedDrug = drugs.first
        } else {
            query = barcodeQuery
        }
    }

    func didOpenScannedDrug() {
        scannedDrug = nil
    }

    // MARK: - Home

    /// Replaces the filters, so "Generics" does not stay on after tapping "On prescription".
    func apply(_ shortcut: SearchShortcut) {
        query.filters = shortcut.filters
    }

    /// Called when the user submits the search or opens a result.
    /// Blank text is not saved. The same text in another case moves to the top.
    func saveRecentSearch() {
        let text = query.searchText
        guard !text.isEmpty else { return }

        var searches = recentSearches.filter { $0.localizedCaseInsensitiveCompare(text) != .orderedSame }
        searches.insert(text, at: 0)
        recentSearches = Array(searches.prefix(Self.recentSearchLimit))
        recentSearchStore.save(recentSearches)
    }

    func clearRecentSearches() {
        recentSearches = []
        recentSearchStore.save([])
    }

    // MARK: - Paging

    /// Call this when a row appears. It loads the next page when the row is near the end.
    /// It does nothing after an error, so a failing server is not hit again and again.
    func loadMoreIfNeeded(after drug: Drug) async {
        guard errorMessage == nil, drugs.suffix(5).contains(where: { $0.id == drug.id }) else { return }
        await loadNextPage()
    }

    func loadNextPage() async {
        // Next pages use the query of the loaded results, not `query`,
        // which may already have changed while the user is typing.
        guard canLoadMore, !isLoading, !isLoadingMore, let results else { return }

        let generation = generation
        status = .loadingMore

        do {
            let page = try await service.search(results.query, page: results.pagination.page + 1, limit: pageSize)
            guard generation == self.generation else { return }

            self.results?.drugs += page.data
            self.results?.pagination = page.pagination
            status = .idle
        } catch {
            guard generation == self.generation else { return }
            status = error.isCancellation ? .idle : .failed(error.localizedDescription)
        }
    }

    // MARK: - Dataset info

    /// Nice to have, not needed. A failure here is silent.
    func loadMeta() async {
        guard meta == nil else { return }
        meta = try? await service.meta()
    }
}

// MARK: - State

private extension DrugSearchViewModel {
    /// The loaded pages and the query that produced them.
    /// The last page's pagination tells which page comes next and when to stop.
    struct Results {
        let query: DrugQuery
        var drugs: [Drug]
        var pagination: DrugPage.Pagination
    }

    /// One value instead of three flags, so "loading" and "failed" can never both be true.
    enum Status: Equatable {
        case idle
        case loading
        case loadingMore
        case failed(String)
    }
}
