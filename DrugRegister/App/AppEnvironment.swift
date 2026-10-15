import Foundation
import Observation
import UserNotifications

/// Shared dependencies, created in one place.
@MainActor
@Observable
final class AppEnvironment {
    let drugService: any DrugService
    let favorites: FavoritesStore
    let recentSearchStore: RecentSearchStore
    let medicineServices: MedicineServices
    /// Kept here because the notification center holds its delegate weakly.
    let reminderTaps = ReminderTapHandler()

    init(
        drugService: any DrugService,
        favorites: FavoritesStore,
        recentSearchStore: RecentSearchStore,
        medicineServices: MedicineServices
    ) {
        self.drugService = drugService
        self.favorites = favorites
        self.recentSearchStore = recentSearchStore
        self.medicineServices = medicineServices
    }

    static func live() -> AppEnvironment {
        let apiClient = LiveAPIClient(
            baseURL: URL(string: "https://drug-register-api.vercel.app")!,
            apiToken: Secrets.apiToken
        )
        let environment = AppEnvironment(
            drugService: LiveDrugService(apiClient: apiClient),
            favorites: FavoritesStore(fileURL: FavoritesStore.defaultFileURL()),
            recentSearchStore: RecentSearchStore(),
            medicineServices: MedicineServices(
                repository: SwiftDataMedicineRepository.live(),
                scheduler: UserNotificationScheduler()
            )
        )
        // Set while the app starts, so a tap that launched the app is not missed.
        UNUserNotificationCenter.current().delegate = environment.reminderTaps
        return environment
    }
}

#if DEBUG
extension AppEnvironment {
    /// Stub data for SwiftUI previews. No network, nothing saved.
    static func preview() -> AppEnvironment {
        AppEnvironment(
            drugService: StubDrugService.preview,
            favorites: FavoritesStore(fileURL: nil),
            recentSearchStore: .preview,
            medicineServices: .preview(medicines: Medicine.previewList)
        )
    }
}

extension RecentSearchStore {
    /// Separate defaults, so previews never touch the real recent searches.
    static var preview: RecentSearchStore {
        RecentSearchStore(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    }
}
#endif
