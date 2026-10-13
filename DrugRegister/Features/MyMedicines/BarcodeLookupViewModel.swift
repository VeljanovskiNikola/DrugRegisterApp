import Foundation
import Observation

/// Finds the drug for a scanned package, so My medicines can open the add form for it.
@MainActor
@Observable
final class BarcodeLookupViewModel {
    enum Outcome: Equatable {
        /// One drug: the view opens the add form.
        case found(DrugSnapshot)
        /// Several drugs share the barcode: the user picks one.
        case choose([Drug])
        case notFound(ean: String)
        case failed(String)
    }

    private(set) var isLooking = false
    /// Set when a lookup finishes. The view shows it, then calls `clearOutcome()`.
    private(set) var outcome: Outcome?

    /// Goes up on every lookup. A slow answer from an old scan is ignored.
    private var generation = 0
    /// For Try Again after a failed lookup.
    private var lastEAN: String?
    private let service: any DrugService

    /// A barcode names one product, so a few results are plenty.
    private static let limit = 10

    init(service: any DrugService) {
        self.service = service
    }

    /// Searches by the barcode alone, without text or filters.
    func lookUp(_ code: String) async {
        guard let ean = EAN.normalized(code) else { return }
        lastEAN = ean

        generation += 1
        let generation = generation
        isLooking = true
        outcome = nil

        do {
            let page = try await service.search(DrugQuery(ean: ean), page: 1, limit: Self.limit)
            guard generation == self.generation else { return }

            isLooking = false
            switch page.data.count {
            case 0: outcome = .notFound(ean: ean)
            case 1: outcome = page.data.first.map { .found(DrugSnapshot($0)) }
            default: outcome = .choose(page.data)
            }
        } catch {
            guard generation == self.generation else { return }
            isLooking = false
            if !error.isCancellation {
                outcome = .failed(error.localizedDescription)
            }
        }
    }

    func retry() async {
        guard let lastEAN else { return }
        await lookUp(lastEAN)
    }

    func clearOutcome() {
        outcome = nil
    }
}
