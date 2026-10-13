import SwiftUI

struct SettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var viewModel: SettingsViewModel

    /// Used until `/meta` answers, and when it fails.
    private static let registerURL = URL(string: "https://lekovi.zdravstvo.gov.mk/drugsregister")!

    init(service: any DrugService, medicines: MedicineServices) {
        _viewModel = State(initialValue: SettingsViewModel(service: service, medicines: medicines))
    }

    var body: some View {
        List {
            Section("Data") {
                Link(destination: viewModel.meta?.source ?? Self.registerURL) {
                    LabeledContent("Data source") {
                        Image(systemName: "arrow.up.right.square")
                    }
                }
                LabeledContent("Last data update") {
                    if let meta = viewModel.meta {
                        Text(meta.scrapedDate.dateOnlyFormatted)
                    } else if viewModel.metaFailed {
                        Text("Not available")
                    } else {
                        ProgressView()
                    }
                }
                if let meta = viewModel.meta {
                    LabeledContent("Drugs in the register") {
                        Text(meta.count, format: .number)
                    }
                }
            }

            reminders

            Section("About") {
                LabeledContent("App version", value: appVersion)
            }

            Section {
                Label("For information only. This app shows data from the official drug register and does not replace advice from a doctor or pharmacist.", systemImage: "info.circle")
                    .font(.appSubheadline)
                    .foregroundStyle(.appSecondaryText)
            }
        }
        .scrollContentBackground(.hidden)
        .readableWidth()
        .background(.appBackground)
        .navigationTitle("Settings")
        .task { await viewModel.loadMeta() }
        // Again on return from iOS Settings, where the user may have allowed notifications.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await viewModel.refreshPermission()
        }
        .onChange(of: viewModel.remindersEnabled) {
            Task { await viewModel.applyReminderChoice() }
        }
    }

    private var reminders: some View {
        Section {
            @Bindable var viewModel = viewModel
            Toggle(isOn: $viewModel.remindersEnabled) {
                Label("Expiry reminders", systemImage: "bell")
            }
            if viewModel.remindersBlocked, let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                Button("Open iOS Settings") { openURL(url) }
            }
        } header: {
            Text("Notifications")
        } footer: {
            if viewModel.remindersBlocked {
                Text("Notifications for this app are turned off in iOS Settings.")
            } else {
                Text("For My medicines: 30 days and 7 days before the expiry date and on the day itself, at 09:00.")
            }
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView(service: StubDrugService(), medicines: .preview(medicines: []))
    }
}
#endif
