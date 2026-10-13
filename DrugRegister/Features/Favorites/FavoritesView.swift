import SwiftUI

/// No view model: the list comes straight from `FavoritesStore`, with no loading or rules.
///
/// Delete is a custom swipe action, not `onDelete` or `EditButton`, because their
/// text comes from iOS, which has no Macedonian.
///
/// Still a `List`, for the swipe action, but each row is the same card as in Search results.
struct FavoritesView: View {
    @Environment(FavoritesStore.self) private var favorites
    @Environment(AppRouter.self) private var router

    var body: some View {
        content
            .navigationTitle("Favorites")
    }

    @ViewBuilder
    private var content: some View {
        if favorites.drugs.isEmpty {
            ContentUnavailableView {
                Label("No favorites yet", systemImage: "heart")
            } description: {
                Text("Tap the heart on a drug to save it here. Saved drugs also open without internet.")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.appBackground)
        } else {
            List {
                ForEach(favorites.drugs) { drug in
                    Button {
                        router.showDrug(drug)
                    } label: {
                        DrugRow(drug: drug)
                            .cardStyle()
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            favorites.remove(drug)
                        }
                    }
                    // Half the Search card spacing on each side, so the gap between cards matches.
                    .listRowInsets(EdgeInsets(
                        top: .spacingSmall,
                        leading: .spacingMedium,
                        bottom: .spacingSmall,
                        trailing: .spacingMedium
                    ))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(.appBackground)
        }
    }
}

#if DEBUG
#Preview("Saved") {
    let favorites = FavoritesStore(fileURL: nil)
    Drug.previewList.prefix(3).forEach(favorites.toggle)
    return NavigationStack {
        FavoritesView()
    }
    .environment(favorites)
    .environment(AppRouter())
}

#Preview("Empty") {
    NavigationStack {
        FavoritesView()
    }
    .environment(FavoritesStore(fileURL: nil))
    .environment(AppRouter())
}
#endif
