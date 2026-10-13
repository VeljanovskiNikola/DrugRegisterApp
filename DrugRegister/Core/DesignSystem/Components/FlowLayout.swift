import SwiftUI

/// Places views in a row and wraps to a new line when the row is full,
/// so every item stays in view without scrolling sideways.
struct FlowLayout: Layout {
    var spacing: CGFloat = .spacingSmall

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, maxWidth: proposal.width ?? .infinity)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(for: subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Item {
        let index: Int
        let size: CGSize
    }

    private struct Row {
        var items: [Item] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            // A view wider than the line gets the line width, so a long chip truncates instead of overflowing.
            let ideal = subviews[index].sizeThatFits(.unspecified)
            let size = ideal.width > maxWidth
                ? subviews[index].sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
                : ideal
            let neededWidth = row.items.isEmpty ? size.width : row.width + spacing + size.width
            if neededWidth > maxWidth, !row.items.isEmpty {
                rows.append(row)
                row = Row()
            }
            row.width = row.items.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.items.append(Item(index: index, size: size))
        }
        if !row.items.isEmpty {
            rows.append(row)
        }
        return rows
    }
}

#if DEBUG
#Preview {
    FlowLayout {
        Chip(title: "Prescription", trailingSystemImage: "xmark") {}
        Chip(title: "Generic", trailingSystemImage: "xmark") {}
        Chip(title: "Antineoplastic and immunomodulating agents", trailingSystemImage: "xmark") {}
        Chip(title: "Positive list", trailingSystemImage: "xmark") {}
    }
    .padding()
    .background(.appBackground)
}
#endif
