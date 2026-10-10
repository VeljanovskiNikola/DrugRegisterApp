import SwiftUI

/// Edits a copy of the filters. Nothing changes in the search until the user taps Apply.
///
/// The API cannot filter by dosage form or manufacturer, so those are not offered here.
struct DrugFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: DrugFilters
    private let apply: (DrugFilters) -> Void

    init(filters: DrugFilters, apply: @escaping (DrugFilters) -> Void) {
        _draft = State(initialValue: filters)
        self.apply = apply
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Prescription type") {
                    ForEach(Dispensing.filterOptions, id: \.self) { option in
                        Toggle(option.title, isOn: binding(for: option, in: \.dispensing))
                    }
                }

                Section("Product type") {
                    ForEach(ProductType.filterOptions, id: \.self) { option in
                        Toggle(option.title, isOn: binding(for: option, in: \.productTypes))
                    }
                }

                Section("ATC group") {
                    Picker("ATC group", selection: $draft.atcGroup) {
                        Text("All groups")
                            .tag(ATCGroup?.none)
                        ForEach(ATCGroup.allCases, id: \.self) { group in
                            ATCGroupLabel(group: group)
                                .tag(Optional(group))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section {
                    Toggle("Positive list only", isOn: $draft.positiveListOnly)
                } footer: {
                    Text("Drugs on the positive list are covered by the Health Insurance Fund.")
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { draft = DrugFilters() }
                        .disabled(!draft.isActive)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    apply(draft)
                    dismiss()
                } label: {
                    Text("Apply")
                        .font(.appHeadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.spacingMedium)
                .background(.bar)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // Small UI logic like this can stay in the view.
    private func binding<Option: Hashable>(
        for option: Option,
        in keyPath: WritableKeyPath<DrugFilters, Set<Option>>
    ) -> Binding<Bool> {
        Binding(
            get: { draft[keyPath: keyPath].contains(option) },
            set: { isOn in
                if isOn {
                    draft[keyPath: keyPath].insert(option)
                } else {
                    draft[keyPath: keyPath].remove(option)
                }
            }
        )
    }
}

private struct ATCGroupLabel: View {
    let group: ATCGroup

    var body: some View {
        HStack(spacing: .spacingSmall) {
            Text(group.code)
                .font(.appBody.monospaced().weight(.semibold))
                .foregroundStyle(.appAccent)
            Text(group.title)
        }
    }
}

#if DEBUG
#Preview {
    Text("Search")
        .sheet(isPresented: .constant(true)) {
            DrugFilterSheet(filters: DrugFilters(dispensing: [.prescription])) { _ in }
        }
}
#endif
