import SwiftUI
import UIKit

struct MyMedicinesView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: MyMedicinesViewModel
    @State private var lookup: BarcodeLookupViewModel
    @State private var editing: Medicine?
    /// The scanned drug the add form is open for.
    @State private var adding: DrugSnapshot?
    @State private var isScanning = false
    private let services: MedicineServices

    init(services: MedicineServices, drugService: any DrugService) {
        self.services = services
        _viewModel = State(initialValue: MyMedicinesViewModel(services: services))
        _lookup = State(initialValue: BarcodeLookupViewModel(service: drugService))
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.appBackground)
            .navigationTitle("My medicines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isScanning = true
                    } label: {
                        Label("Add to my medicines", systemImage: "plus")
                    }
                    .disabled(lookup.isLooking)
                }
            }
            // Runs each time the tab appears, so medicines added from a detail screen show up.
            .task { await viewModel.load() }
            .safeAreaInset(edge: .bottom) { undoBanner }
            .animation(.appStandard, value: viewModel.recentlyDeleted)
            // The banner hides itself after a while. A new delete starts the wait again.
            .task(id: viewModel.recentlyDeleted?.id) {
                guard viewModel.recentlyDeleted != nil else { return }
                try? await Task.sleep(for: Self.undoDuration)
                guard !Task.isCancelled else { return }
                viewModel.dismissUndo()
            }
            .onChange(of: viewModel.recentlyDeleted) { _, medicine in
                guard let medicine else { return }
                AccessibilityNotification.Announcement(String(localized: "Deleted: \(medicine.drug.nameLatin)")).post()
            }
            .onDisappear { viewModel.dismissUndo() }
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
            .modifier(AddByScan(
                lookup: lookup,
                isScanning: $isScanning,
                adding: $adding,
                services: services,
                onSaved: { Task { await viewModel.load() } }
            ))
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
            // Scanning the box is how most people add a pack at home.
            Button("Scan a package") { isScanning = true }
                .buttonStyle(.borderedProminent)
            Button("Go to Search") { router.showSearch() }
                .buttonStyle(.bordered)
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

    // MARK: - Undo

    private static let undoDuration = Duration.seconds(5)

    /// Shows only the drug name. The note is private and never shown here.
    @ViewBuilder
    private var undoBanner: some View {
        if let medicine = viewModel.recentlyDeleted {
            HStack(spacing: .spacingMedium) {
                Text("Deleted: \(medicine.drug.nameLatin)")
                    .font(.appSubheadline)
                    .lineLimit(2)
                Spacer()
                Button {
                    Task { await viewModel.undoDelete() }
                } label: {
                    Text("Undo")
                        .font(.appHeadline)
                        .frame(minHeight: .minTapSize)
                        .contentShape(.rect)
                }
            }
            .cardStyle()
            .padding(.horizontal, .spacingMedium)
            .padding(.bottom, .spacingSmall)
            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
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
        MyMedicinesView(services: .preview(medicines: Medicine.previewList), drugService: StubDrugService.preview)
    }
    .environment(AppRouter())
}

#Preview("With expired items") {
    NavigationStack {
        MyMedicinesView(services: .preview(medicines: Medicine.previewExpired, permission: .denied), drugService: StubDrugService.preview)
    }
    .environment(AppRouter())
}

#Preview("Empty") {
    NavigationStack {
        MyMedicinesView(services: .preview(medicines: []), drugService: StubDrugService.preview)
    }
    .environment(AppRouter())
}
#endif
