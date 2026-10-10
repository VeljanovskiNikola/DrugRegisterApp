import Foundation
import Observation

/// Opens a saved medicine's drug with fresh data from the register.
/// Falls back to the saved snapshot when offline or when the drug left the register.
@MainActor
@Observable
final class SavedDrugViewModel {
    enum State: Equatable {
        case loading
        case loaded(Drug)
        case offline
        /// The register answered 404: the drug is no longer listed.
        case removed
    }

    private(set) var state = State.loading
    let snapshot: DrugSnapshot

    private let service: any DrugService

    init(snapshot: DrugSnapshot, service: any DrugService) {
        self.snapshot = snapshot
        self.service = service
    }

    func load() async {
        if case .loaded = state { return }
        state = .loading

        do {
            state = .loaded(try await service.drug(id: snapshot.id))
        } catch {
            // Leaving the screen cancels the load. `.task` starts it again on return.
            guard !error.isCancellation else { return }
            if let apiError = error as? APIError, case .server(status: 404, _) = apiError {
                state = .removed
            } else {
                state = .offline
            }
        }
    }
}
