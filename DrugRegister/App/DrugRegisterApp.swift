import SwiftUI

/// The composition root. It builds the app and nothing else.
@main
struct DrugRegisterApp: App {
    @State private var environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
        }
    }
}
