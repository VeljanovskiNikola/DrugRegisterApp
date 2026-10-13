import SwiftUI

/// The tab bar. Search, My medicines and Favorites each have their own navigation stack.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.scenePhase) private var scenePhase
    @State private var router = AppRouter()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.searchPath) {
                DrugSearchView(
                    service: environment.drugService,
                    recentSearchStore: environment.recentSearchStore
                )
                .drugDestinations()
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(AppTab.search)

            NavigationStack(path: $router.medicinesPath) {
                MyMedicinesView(services: environment.medicineServices)
                    .drugDestinations()
            }
            .tabItem { Label("My medicines", systemImage: "cross.case") }
            .tag(AppTab.myMedicines)

            NavigationStack(path: $router.favoritesPath) {
                FavoritesView()
                    .drugDestinations()
            }
            .tabItem { Label("Favorites", systemImage: "heart") }
            .tag(AppTab.favorites)

            NavigationStack {
                SettingsView(service: environment.drugService, medicines: environment.medicineServices)
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(AppTab.settings)
        }
        .environment(router)
        .environment(environment.favorites)
        // Prices and numbers in `Text` follow this, not the device language.
        .environment(\.locale, .app)
        // iOS keeps only 64 pending reminders. Fired ones make room, so later ones are added here.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await environment.medicineServices.syncReminders() }
        }
    }
}

private extension View {
    func drugDestinations() -> some View {
        modifier(DrugDestinations())
    }
}

/// A modifier, not a plain function, so it can read the shared service from the environment.
private struct DrugDestinations: ViewModifier {
    @Environment(AppEnvironment.self) private var environment

    func body(content: Content) -> some View {
        content.navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .drugDetail(let drug):
                DrugDetailView(drug: drug, medicines: environment.medicineServices)
            case .document(let document):
                DocumentView(document: document, service: environment.drugService)
            case .savedDrug(let snapshot):
                SavedDrugView(
                    snapshot: snapshot,
                    service: environment.drugService,
                    medicines: environment.medicineServices
                )
            }
        }
    }
}

#if DEBUG
#Preview {
    RootView()
        .environment(AppEnvironment.preview())
}
#endif
