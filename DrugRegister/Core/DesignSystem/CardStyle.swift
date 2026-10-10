import SwiftUI

extension View {
    /// A white rounded card with a soft shadow, on the gray app background.
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.spacingMedium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.appCardBackground, in: .rect(cornerRadius: .cornerRadiusLarge))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}
