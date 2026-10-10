import Observation

/// Screens ask the router to navigate. They do not edit the path themselves.
/// Each tab has its own stack, so switching tabs keeps where you were.
@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .search
    var searchPath: [AppRoute] = []
    var medicinesPath: [AppRoute] = []
    var favoritesPath: [AppRoute] = []

    func showDrug(_ drug: Drug) {
        push(.drugDetail(drug))
    }

    func showDocument(_ document: DrugDocument) {
        push(.document(document))
    }

    func showSavedDrug(_ snapshot: DrugSnapshot) {
        push(.savedDrug(snapshot))
    }

    /// From the empty My medicines screen: find a drug to add.
    func showSearch() {
        selectedTab = .search
    }

    /// Pushes onto the stack of the current tab, so Back returns to where the user came from.
    private func push(_ route: AppRoute) {
        switch selectedTab {
        case .search:
            searchPath.append(route)
        case .myMedicines:
            medicinesPath.append(route)
        case .favorites:
            favoritesPath.append(route)
        case .settings:
            // Settings has no stack of its own. Routes open in Search.
            selectedTab = .search
            searchPath.append(route)
        }
    }

    func popToRoot() {
        switch selectedTab {
        case .search: searchPath.removeAll()
        case .myMedicines: medicinesPath.removeAll()
        case .favorites: favoritesPath.removeAll()
        case .settings: break
        }
    }
}
