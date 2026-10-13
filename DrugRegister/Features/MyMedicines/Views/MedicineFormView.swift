import SwiftUI

/// Adds a medicine from the detail screen, or edits one from the list.
///
/// The register's "decision valid until" date is never offered here. It is not a package
/// expiry date, so the user always types what is printed on the package.
struct MedicineFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MedicineFormViewModel
    private let onSaved: () -> Void
    /// Set by the My medicines list, which opens a pack here. The list closes the form and navigates.
    private let onViewInRegister: ((DrugSnapshot) -> Void)?

    init(
        mode: MedicineFormViewModel.Mode,
        services: MedicineServices,
        onSaved: @escaping () -> Void = {},
        onViewInRegister: ((DrugSnapshot) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: MedicineFormViewModel(mode: mode, services: services))
        self.onSaved = onSaved
        self.onViewInRegister = onViewInRegister
    }

    var body: some View {
        NavigationStack {
            Form {
                drugSection
                expirySection
                packsSection
                openedSection
                noteSection
                if let message = viewModel.errorMessage {
                    Section {
                        Label(message, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.appCritical)
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit medicine" : "Add to my medicines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.save() {
                                onSaved()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }

    private var drugSection: some View {
        Section {
            VStack(alignment: .leading, spacing: .spacingXSmall) {
                Text(viewModel.drug.nameLatin)
                    .font(.appHeadline)
                if !viewModel.drug.strengthAndForm.isEmpty {
                    Text(viewModel.drug.strengthAndForm)
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                }
            }
            if viewModel.isEditing, let onViewInRegister {
                Button {
                    onViewInRegister(viewModel.drug)
                } label: {
                    Label("View in register", systemImage: "doc.text.magnifyingglass")
                }
            }
        }
    }

    private var expirySection: some View {
        Section {
            if viewModel.knowsExactDay {
                DatePicker("Expiry date", selection: $viewModel.exactExpiryDate, displayedComponents: .date)
            } else {
                Picker("Month", selection: $viewModel.expiryMonth) {
                    Text("Choose").tag(Int?.none)
                    ForEach(Array(viewModel.monthNames.enumerated()), id: \.offset) { index, name in
                        Text(name).tag(Optional(index + 1))
                    }
                }
                Picker("Year", selection: $viewModel.expiryYear) {
                    Text("Choose").tag(Int?.none)
                    ForEach(viewModel.yearOptions, id: \.self) { year in
                        // Not `Text(year, format:)`: a year must not get a thousands separator.
                        Text(verbatim: String(year)).tag(Optional(year))
                    }
                }
            }
            Toggle("I know the exact day", isOn: $viewModel.knowsExactDay)
        } header: {
            Text("Expiry date")
        } footer: {
            Text("Use the date printed on the package, for example EXP 05/2027. Month and year count as the last day of that month.")
        }
    }

    private var packsSection: some View {
        Section {
            Stepper(value: $viewModel.packCount, in: MedicineFormViewModel.packRange) {
                Text("Packs: \(viewModel.packCount)")
            }
        }
    }

    private var openedSection: some View {
        Section {
            Toggle("Opened", isOn: $viewModel.isOpened)
            if viewModel.isOpened {
                DatePicker(
                    "Opened on",
                    selection: $viewModel.openedDate,
                    in: ...viewModel.latestOpenedDate,
                    displayedComponents: .date
                )
            }
        }
    }

    private var noteSection: some View {
        Section {
            TextField("Note", text: $viewModel.note, axis: .vertical)
                .lineLimit(2...5)
        } header: {
            Text("Note")
        } footer: {
            HStack(alignment: .firstTextBaseline) {
                Text("Optional. It stays on this device and is never shown in reminders.")
                Spacer()
                Text(verbatim: "\(viewModel.trimmedNote.count)/\(MedicineFormViewModel.noteLimit)")
                    .monospacedDigit()
                    .foregroundStyle(viewModel.trimmedNote.count > MedicineFormViewModel.noteLimit ? Color.appCritical : Color.appSecondaryText)
            }
        }
    }
}

#if DEBUG
#Preview("Add") {
    MedicineFormView(mode: .add(DrugSnapshot(.sample)), services: .preview(medicines: []))
}

#Preview("Edit") {
    MedicineFormView(mode: .edit(Medicine.previewList[0]), services: .preview(medicines: Medicine.previewList))
}
#endif
