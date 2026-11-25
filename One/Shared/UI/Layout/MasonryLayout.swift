import SwiftUI

/// 瀑布流子项种类（由 `MasonryLayoutCell` 写入 `LayoutValue`）。
enum MasonrySubviewKind: Hashable, Sendable {
    case month
    case article
}

private nonisolated struct MasonrySubviewKindKey: LayoutValueKey {
    static let defaultValue: MasonrySubviewKind = .article
}

/// `MasonryLayout` 的直接子视图；声明种类供列分配。
struct MasonryLayoutCell<Content: View>: View {
    let kind: MasonrySubviewKind
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .layoutValue(key: MasonrySubviewKindKey.self, value: kind)
    }
}

/// 两列瀑布流：同类与「文章→月」落在当前高度最低的列；仅「月→文章」沿用上一项所在列。
nonisolated struct MasonryLayout: Layout {
    var columns: Int = 2
    var spacing: CGFloat = 10

    struct Cache {
        var totalHeight: CGFloat = 0
        var columnOfSubview: [Int] = []
        var frames: [CGRect] = []
    }

    func makeCache(subviews _: Subviews) -> Cache { Cache() }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        layout(width: width, subviews: subviews, cache: &cache)
        return CGSize(width: width, height: cache.totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        layout(width: bounds.width, subviews: subviews, cache: &cache)
        for (index, frame) in cache.frames.enumerated() where index < subviews.count {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    private func layout(width: CGFloat, subviews: Subviews, cache: inout Cache) {
        let columnCount = max(columns, 1)
        let columnWidth = max((width - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount), 1)
        let itemProposal = ProposedViewSize(width: columnWidth, height: nil)

        var columnTops = [CGFloat](repeating: 0, count: columnCount)
        var assignedColumns: [Int] = []
        assignedColumns.reserveCapacity(subviews.count)
        var frames: [CGRect] = []
        frames.reserveCapacity(subviews.count)

        for (index, subview) in subviews.enumerated() {
            let currentKind = subview[MasonrySubviewKindKey.self]
            let previousKind = index > 0 ? subviews[index - 1][MasonrySubviewKindKey.self] : nil
            let previousColumn = index > 0 ? assignedColumns[index - 1] : nil
            let column = pickColumn(
                columnCount: columnCount,
                columnTops: columnTops,
                previousKind: previousKind,
                currentKind: currentKind,
                previousColumn: previousColumn
            )
            assignedColumns.append(column)

            let height = subview.sizeThatFits(itemProposal).height
            let x = CGFloat(column) * (columnWidth + spacing)
            let y = columnTops[column]
            frames.append(CGRect(x: x, y: y, width: columnWidth, height: height))
            columnTops[column] = y + height + spacing
        }

        cache.columnOfSubview = assignedColumns

        cache.frames = frames
        cache.totalHeight = frames.isEmpty ? 0 : max((columnTops.max() ?? 0) - spacing, 0)
    }

    /// 同类选最低列；仅月→文章沿用上一列；其余（含文章→月、首项）选最低列。
    private func pickColumn(
        columnCount _: Int,
        columnTops: [CGFloat],
        previousKind: MasonrySubviewKind?,
        currentKind: MasonrySubviewKind,
        previousColumn: Int?
    ) -> Int {
        if let previousColumn,
           case .month = previousKind,
           case .article = currentKind {
            return previousColumn
        }
        return columnTops.indices.min(by: { columnTops[$0] < columnTops[$1] }) ?? 0
    }
}