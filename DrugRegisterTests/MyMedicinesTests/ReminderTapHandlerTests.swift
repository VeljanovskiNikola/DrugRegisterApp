import Foundation
import Testing
@testable import DrugRegister

@MainActor
struct ReminderTapHandlerTests {
    private let reminderID = "\(ReminderPlanner.idPrefix)\(UUID().uuidString)-30"

    @Test
    func tapOnAReminderOpensMyMedicines() {
        let handler = ReminderTapHandler()
        var opened = 0
        handler.connect { opened += 1 }

        handler.handleTap(identifier: reminderID)

        #expect(opened == 1)
    }

    @Test
    func tapOnAnotherNotificationIsIgnored() {
        let handler = ReminderTapHandler()
        var opened = 0
        handler.connect { opened += 1 }

        handler.handleTap(identifier: "something-else")

        #expect(opened == 0)
    }

    @Test
    func tapBeforeTheUIExistsIsDeliveredOnConnect() {
        let handler = ReminderTapHandler()
        var opened = 0

        handler.handleTap(identifier: reminderID)
        #expect(opened == 0)

        handler.connect { opened += 1 }
        #expect(opened == 1)

        // Only once: a second connect must not open it again.
        handler.connect { opened += 1 }
        #expect(opened == 1)
    }
}
