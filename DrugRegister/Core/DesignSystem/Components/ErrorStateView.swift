import SwiftUI

/// One consistent "something failed, try again" screen for every feature.
struct ErrorStateView: View {
    let message: String
    let systemImageName: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: systemImageName)
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.bordered)
        }
    }
}

#Preview {
    ErrorStateView(message: "The Internet connection appears to be offline.", systemImageName: "wifi.exclamationmark") {}
}
