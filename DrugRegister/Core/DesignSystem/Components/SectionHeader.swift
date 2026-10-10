import SwiftUI

/// The title above a group of cards, with an optional button on the right.
struct SectionHeader<Accessory: View>: View {
    let title: LocalizedStringKey
    let accessory: Accessory

    init(_ title: LocalizedStringKey, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.appSectionTitle)
            Spacer()
            accessory
                .font(.appSubheadline)
        }
    }
}

extension SectionHeader where Accessory == EmptyView {
    init(_ title: LocalizedStringKey) {
        self.title = title
        self.accessory = EmptyView()
    }
}
