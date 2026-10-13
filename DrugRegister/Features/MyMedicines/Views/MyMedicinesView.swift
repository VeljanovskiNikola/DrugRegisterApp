import SwiftUI
import UIKit

struct MyMedicinesView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.openURL) private var openURL
    @State private var viewModel: MyMedicinesViewModel
    @State private var editing: Medicine?
    private let services: MedicineServices

    init(services: MedicineServices) {
        self.services = services
        _viewModel = State(initialValue: MyMedicinesViewModel(services: services))
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.appBackground)
            .navigationTitle("My medicines")
            // Runs each time the tab appears, so medicines added from a detail screen show up.
            .task { await viewModel.load() }
            .sheet(item: $editing) { medicine in
                MedicineFormView(
                    mode: .edit(medicine),
                    services: services,
                    onSaved: { Task { await viewModel.load() } },
                    onViewInRegister: { snapshot in
                        editing = nil
                        router.showSavedDrug(snapshot)
                    }
                )
            }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoaded {
            ProgressView()
        } else if viewModel.medicines.isEmpty {
            if let message = viewModel.errorMessage {
                ErrorStateView(message: message, systemImageName: "exclamationmark.circle") {
                    Task { await viewModel.load() }
                }
            } else {
                emptyState
            }
        } else {
            list
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No medicines yet", systemImage: "cross.case")
        } description: {
            Text("Find a drug in Search and tap “Add to my medicines”. You will see which packs expire first and get a reminder before they do.")
        } actions: {
            Button("Go to Search") { router.showSearch() }
                .buttonStyle(.borderedProminent)
        }
    }

    private var list: some View {
        List {
            Section {
                summary
                if viewModel.showsPermissionWarning {
                    permissionWarning
                }
                if let message = viewModel.errorMessage {
                    Label(message, systemImage: "exclamationmark.circle")
                        .font(.appSubheadline)
                        .foregroundStyle(.appCritical)
                }
            }

            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(section.entries) { entry in
                        row(for: entry)
                    }
                } header: {
                    Text(section.group.title)
                }
            }

            Section {
            } footer: {
                Text("Check the package or ask a pharmacist.")
            }
        }
    }

    /// A tap opens the user's pack (expiry, packs, note). The register drug is one more tap away.
    private func row(for entry: ExpiryEntry) -> some View {
        let medicine = entry.medicine
        return Button {
            editing = medicine
        } label: {
            MedicineRow(entry: entry, expiryText: viewModel.expiryText(for: medicine))
        }
        .tint(.primary)
        .swipeActions(edge: .trailing) {
            Button("Delete", systemImage: "trash", role: .destructive) {
                Task { await viewModel.delete(medicine) }
            }
        }
        .swipeActions(edge: .leading) {
            Button("Edit", systemImage: "pencil") { editing = medicine }
                .tint(.appAccent)
        }
        .contextMenu {
            Button("Edit", systemImage: "pencil") { editing = medicine }
            Button("View in register", systemImage: "doc.text.magnifyingglass") {
                router.showSavedDrug(medicine.drug)
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                Task { await viewModel.delete(medicine) }
            }
        }
    }

    // MARK: - Summary

    /// Two separate texts, each with its own plural form, instead of one sentence built from pieces.
    @ViewBuilder
    private var summary: some View {
        let summary = viewModel.summary
        if summary.expired == 0 && summary.within30Days == 0 {
            Label("Nothing expires in the next 30 days", systemImage: "checkmark.circle")
                .font(.appSubheadline)
                .foregroundStyle(.appSecondaryText)
        } else {
            HStack(spacing: .spacingSmall) {
                if summary.expired > 0 {
                    TagBadge(
                        text: String(localized: "\(summary.expired) expired"),
                        tone: .critical,
                        systemImage: ExpiryGroup.expired.systemImage
                    )
                }
                if summary.within30Days > 0 {
                    TagBadge(
                        text: String(localized: "\(summary.within30Days) expire within 30 days"),
                        tone: .warning,
                        systemImage: ExpiryGroup.within30Days.systemImage
                    )
                }
            }
        }
    }

    private var permissionWarning: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            Label("Reminders are off. Allow notifications to be reminded before a pack expires.", systemImage: "bell.slash")
                .font(.appSubheadline)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    openURL(url)
                }
            }
            .font(.appSubheadline.weight(.semibold))
        }
        .padding(.vertical, .spacingXSmall)
    }
}

#if DEBUG
#Preview("With data") {
    NavigationStack {
        MyMedicinesView(services: .preview(medicines: Medicine.previewList))
    }
    .environment(AppRouter())
}

#Preview("With expired items") {
    NavigationStack {
        MyMedicinesView(services: .preview(medicines: Medicine.previewExpired, permission: .denied))
    }
    .environment(AppRouter())
}

#Preview("Empty") {
    NavigationStack {
        MyMedicinesView(services: .preview(medicines: []))
    }
    .environment(AppRouter())
}
#endif
