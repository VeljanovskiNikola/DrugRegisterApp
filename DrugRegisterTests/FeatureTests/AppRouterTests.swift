import Foundation
import Testing
@testable import DrugRegister

@MainActor
struct AppRouterTests {

    @Test
    func showDrugPushesOntoTheSearchStack() {
        let router = AppRouter()

        router.showDrug(.sample)
        #expect(router.searchPath == [.drugDetail(.sample)])
        #expect(router.favoritesPath.isEmpty)

        router.popToRoot()
        #expect(router.searchPath.isEmpty)
    }

    @Test
    func documentOpensOnTopOfTheDrugInTheSameTab() {
        let router = AppRouter()
        router.selectedTab = .favorites
        let document = DrugDocument(kind: .smpc, url: URL(string: "https://example.com/smpc.pdf")!)

        router.showDrug(.sample)
        router.showDocument(document)

        #expect(router.favoritesPath == [.drugDetail(.sample), .document(document)])
        #expect(router.searchPath.isEmpty)
    }

    @Test
    func showDrugInFavoritesStaysInFavorites() {
        let router = AppRouter()
        router.selectedTab = .favorites

        router.showDrug(.sample)

        #expect(router.favoritesPath == [.drugDetail(.sample)])
        #expect(router.searchPath.isEmpty)
        #expect(router.selectedTab == .favorites)
    }

    @Test
    func savedDrugOpensInMyMedicines() {
        let router = AppRouter()
        router.selectedTab = .myMedicines
        let snapshot = DrugSnapshot(.sample)

        router.showSavedDrug(snapshot)

        #expect(router.medicinesPath == [.savedDrug(snapshot)])
        #expect(router.searchPath.isEmpty)
    }

    @Test
    func showSearchSwitchesTheTab() {
        let router = AppRouter()
        router.selectedTab = .myMedicines

        router.showSearch()

        #expect(router.selectedTab == .search)
    }

    @Test
    func showDrugFromSettingsOpensItInSearch() {
        let router = AppRouter()
        router.selectedTab = .settings

        router.showDrug(.sample)

        #expect(router.selectedTab == .search)
        #expect(router.searchPath == [.drugDetail(.sample)])
    }
}

@MainActor
struct AppRouterMyMedicinesTests {

    @Test
    func showMyMedicinesSelectsTheTabAndGoesBackToItsRoot() {
        let router = AppRouter()
        router.selectedTab = .myMedicines
        router.showDrug(.sample)
        router.selectedTab = .settings

        router.showMyMedicines()

        #expect(router.selectedTab == .myMedicines)
        #expect(router.medicinesPath.isEmpty)
    }
}
