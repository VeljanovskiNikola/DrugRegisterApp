import SwiftUI

/// Home and results in one screen. With no text, barcode or filter it shows the home content
/// (scan, recent searches, quick filters). Otherwise it shows the results.
struct DrugSearchView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: DrugSearchViewModel
    @State private var isShowingFilters = false
    @State private var isShowingScanner = false

    init(service: any DrugService, recentSearchStore: RecentSearchStore) {
        _viewModel = State(initialValue: DrugSearchViewModel(service: service, recentSearchStore: recentSearchStore))
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.appBackground)
            .navigationTitle("Lekovi")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $viewModel.query.text,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by name or active ingredient"
            )
            .onSubmit(of: .search) { viewModel.saveRecentSearch() }
            .toolbar { toolbar }
            .sheet(isPresented: $isShowingFilters) {
                DrugFilterSheet(filters: viewModel.query.filters) { viewModel.query.filters = $0 }
            }
            .sheet(isPresented: $isShowingScanner) {
                BarcodeScannerSheet { viewModel.search(barcode: $0) }
            }
            // One drug for the scanned barcode: open it right away. The view navigates, not the view model.
            .onChange(of: viewModel.scannedDrug) { _, drug in
                guard let drug else { return }
                viewModel.didOpenScannedDrug()
                router.showDrug(drug)
            }
            .sensoryFeedback(.success, trigger: viewModel.query.ean) { _, new in new != nil }
            // Runs on appear and again whenever the query changes. The old run is cancelled.
            .task(id: viewModel.query) { await viewModel.reload() }
            .task { await viewModel.loadMeta() }
    }

    // MARK: - Content

    private var content: some View {
        Group {
            switch phase {
            case .home:
                home
            case .loading:
                statusScreen { ProgressView() }
            case .failed(let message):
                statusScreen {
                    ErrorStateView(message: message, systemImageName: "wifi.exclamationmark") {
                        Task { await viewModel.reload(force: true) }
                    }
                }
            case .empty:
                statusScreen { emptyResult }
            case .results:
                results
            }
        }
        .transition(.opacity)
        // Animates only the switch between screens. Typing and paging change the content
        // inside one screen and stay instant.
        .animation(.appStandard, value: phase)
    }

    /// Loading, error and empty states, below the barcode banner and the filter chips.
    /// In a scroll view so the navigation bar can animate when the search field gets focus.
    private func statusScreen(@ViewBuilder _ content: () -> some View) -> some View {
        ScrollView {
            VStack(spacing: .spacingMedium) {
                if hasTopBars {
                    topBars
                }
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.spacingMedium)
            .containerRelativeFrame(.vertical)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.immediately)
    }

    private enum Phase: Hashable {
        case home
        case loading
        case failed(String)
        case empty
        case results
    }

    private var phase: Phase {
        if viewModel.query.isEmpty {
            .home
        } else if !viewModel.drugs.isEmpty {
            .results
        } else if let message = viewModel.errorMessage {
            .failed(message)
        } else if viewModel.hasLoaded && !viewModel.isLoading {
            .empty
        } else {
            .loading
        }
    }

    @ViewBuilder
    private var emptyResult: some View {
        if let ean = viewModel.query.ean {
            ContentUnavailableView {
                Label("No drug with this barcode", systemImage: "barcode")
            } description: {
                Text("The barcode \(ean) is not in the register.")
            } actions: {
                Button("Scan again") { isShowingScanner = true }
                    .buttonStyle(.bordered)
            }
        } else if viewModel.query.searchText.isEmpty {
            ContentUnavailableView {
                Label("No drugs found", systemImage: "pills")
            } description: {
                Text("Try changing the filters.")
            } actions: {
                clearFiltersButton
            }
        } else {
            // Not `ContentUnavailableView.search`: its text comes from iOS, which has no Macedonian.
            ContentUnavailableView {
                Label("No results for “\(viewModel.query.searchText)”", systemImage: "magnifyingglass")
            } description: {
                Text("Check the spelling or try a new search.")
            } actions: {
                if viewModel.query.filters.isActive {
                    clearFiltersButton
                }
            }
        }
    }

    private var clearFiltersButton: some View {
        Button("Clear filters") { viewModel.clearFilters() }
            .buttonStyle(.bordered)
    }

    // MARK: - Home

    private var home: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingLarge) {
                scanCard
                if !viewModel.recentSearches.isEmpty {
                    recentSearches
                }
                quickFilters
                dataFooter
            }
            .padding(.spacingMedium)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var scanCard: some View {
        Button {
            isShowingScanner = true
        } label: {
            HStack(spacing: .spacingMedium) {
                Image(systemName: "barcode.viewfinder")
                    .font(.appSectionTitle)
                    .foregroundStyle(.white)
                    .frame(width: .iconSize, height: .iconSize)
                    .background(.appAccent, in: .rect(cornerRadius: .cornerRadiusMedium))
                VStack(alignment: .leading, spacing: .spacingXSmall) {
                    Text("Scan barcode")
                        .font(.appHeadline)
                    Text("Find a drug by the barcode on its package")
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.appCaption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(.rect)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var recentSearches: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            SectionHeader("Recent searches") {
                Button("Clear") { viewModel.clearRecentSearches() }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacingSmall) {
                    ForEach(viewModel.recentSearches, id: \.self) { text in
                        Chip(title: text, systemImage: "clock.arrow.circlepath") {
                            viewModel.query.text = text
                        }
                    }
                }
                // Room for the chip border, which the scroll view would otherwise cut.
                .padding(.vertical, .spacingXSmall)
            }
        }
    }

    private var quickFilters: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            SectionHeader("Quick filters")
            VStack(spacing: 0) {
                ForEach(Array(SearchShortcut.allCases.enumerated()), id: \.element) { index, shortcut in
                    if index > 0 {
                        Divider()
                            .padding(.leading, .iconSize + .spacingMedium)
                    }
                    Button {
                        viewModel.apply(shortcut)
                    } label: {
                        ShortcutRow(shortcut: shortcut)
                    }
                    .buttonStyle(.plain)
                }
            }
            .cardStyle()
        }
    }

    private var dataFooter: some View {
        VStack(spacing: .spacingXSmall) {
            Label("Data from the official register", systemImage: "checkmark.seal")
            if let meta = viewModel.meta {
                Text("Updated \(meta.scrapedDate.dateOnlyFormatted) · \(meta.count) drugs")
            }
        }
        .font(.appCaption)
        .foregroundStyle(.appSecondaryText)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Results

    private var results: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: .spacingMedium) {
                if hasTopBars {
                    topBars
                }
                Text("\(viewModel.total) results")
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
                    .contentTransition(.numericText())

                ForEach(viewModel.drugs) { drug in
                    Button {
                        viewModel.saveRecentSearch()
                        router.showDrug(drug)
                    } label: {
                        DrugRow(drug: drug)
                            .cardStyle()
                    }
                    .buttonStyle(.plain)
                    .transition(rowTransition)
                    .task { await viewModel.loadMoreIfNeeded(after: drug) }
                }
                resultsFooter
            }
            .padding(.spacingMedium)
            // New rows fade in when a search or the next page arrives. Keyed on the ids, so typing
            // and pull to refresh with the same drugs do not animate.
            .animation(.appStandard, value: viewModel.drugs.map(\.id))
        }
        .scrollDismissesKeyboard(.immediately)
        .refreshable { await viewModel.reload(force: true) }
    }

    /// Rows rise a little while they fade in. With Reduce Motion they only fade.
    private var rowTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .offset(y: .spacingMedium))
    }

    @ViewBuilder
    private var resultsFooter: some View {
        if viewModel.isLoadingMore {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if let message = viewModel.errorMessage {
            VStack(spacing: .spacingSmall) {
                Text(message)
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
                Button("Try Again") {
                    Task { await viewModel.loadNextPage() }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Barcode

    /// Shows which barcode the results are for, with a button to go back to a normal search.
    @ViewBuilder
    private var barcodeBanner: some View {
        if let ean = viewModel.query.ean {
            HStack(spacing: .spacingSmall) {
                Label("Barcode \(ean)", systemImage: "barcode")
                    .font(.appSubheadline.monospacedDigit())
                Spacer()
                Button {
                    viewModel.query.ean = nil
                } label: {
                    Label("Clear barcode", systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.appSecondaryText)
                        .frame(width: .minTapSize, height: .minTapSize)
                        .contentShape(.rect)
                }
                // The tap area reaches into the card's padding, so the card barely grows.
                .padding(.vertical, -.spacingSmall)
                .padding(.trailing, -.spacingSmall)
            }
            .cardStyle()
            .transition(barTransition)
        }
    }

    // MARK: - Filters

    /// The barcode banner and the filter chips, at the top of every screen except home.
    ///
    /// They scroll with the content instead of sitting in a top `safeAreaInset`. The navigation bar
    /// moves the scroll view with its own animation when the search field gets focus. An inset does
    /// not follow that animation and jumps.
    private var topBars: some View {
        VStack(spacing: .spacingSmall) {
            barcodeBanner
            filterBar
        }
        .animation(.appStandard, value: viewModel.query.filters)
        .animation(.appStandard, value: viewModel.query.ean)
    }

    /// Checked by the parent stacks, because an empty `topBars` would still get their spacing.
    private var hasTopBars: Bool {
        viewModel.query.ean != nil || viewModel.query.filters.isActive
    }

    /// The filters that are on, so they are visible and each one is a tap away from off.
    /// The chips wrap, so every filter that is on stays in view.
    @ViewBuilder
    private var filterBar: some View {
        let filters = viewModel.query.filters.active
        if !filters.isEmpty {
            FlowLayout {
                ForEach(filters, id: \.self) { filter in
                    Chip(title: filter.title, trailingSystemImage: "xmark") {
                        viewModel.removeFilter(filter)
                    }
                    .accessibilityLabel(Text("Remove filter \(filter.title)"))
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }
                Button {
                    viewModel.clearFilters()
                } label: {
                    Text("Clear all")
                        .font(.appSubheadline)
                        .frame(minHeight: .minTapSize)
                        .contentShape(.rect)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(barTransition)
        }
    }

    /// The barcode banner and the filter bar slide in from the top. With Reduce Motion they only fade.
    private var barTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                isShowingScanner = true
            } label: {
                Label("Scan barcode", systemImage: "barcode.viewfinder")
            }
            Button {
                isShowingFilters = true
            } label: {
                Label(
                    "Filters",
                    systemImage: viewModel.query.filters.isActive
                        ? "line.3.horizontal.decrease.circle.fill"
                        : "line.3.horizontal.decrease.circle"
                )
            }
        }
    }
}

private struct ShortcutRow: View {
    let shortcut: SearchShortcut

    var body: some View {
        HStack(spacing: .spacingMedium) {
            Image(systemName: shortcut.systemImage)
                .foregroundStyle(.appAccent)
                .frame(width: .iconSize, height: .iconSize)
                .background(.appAccentSoft, in: .rect(cornerRadius: .cornerRadiusMedium))
            Text(shortcut.title)
                .font(.appBody)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.appCaption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, .spacingSmall)
        .contentShape(.rect)
    }
}

#if DEBUG
#Preview("Home") {
    NavigationStack {
        DrugSearchView(service: StubDrugService.preview, recentSearchStore: .preview)
    }
    .environment(AppRouter())
}

#Preview("Error") {
    NavigationStack {
        DrugSearchView(
            service: StubDrugService(searchHandler: { _, _, _ in throw APIError.rateLimited(retryAfter: 12) }),
            recentSearchStore: .preview
        )
    }
    .environment(AppRouter())
}
#endif
