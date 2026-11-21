import SwiftUI

/// 两列瀑布流：按子视图实测高度放入更短的一列；列号缓存避免封面增高后乱跳。
struct MasonryLayout: Layout {
    var columns: Int = 2
    var spacing: CGFloat = 10

    struct Cache {
        var width: CGFloat = -1
        var totalHeight: CGFloat = 0
        var columnOfSubview: [Int] = []
        var frames: [CGRect] = []
    }

    func makeCache(subviews: Subviews) -> Cache { Cache() }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        layout(width: width, subviews: subviews, cache: &cache)
        return CGSize(width: width, height: cache.totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
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

        if widthDiffers(cache.width, from: width) || cache.columnOfSubview.count > subviews.count {
            cache.columnOfSubview.removeAll(keepingCapacity: true)
        }
        cache.width = width

        resolveColumns(subviews: subviews, columnCount: columnCount, itemProposal: itemProposal, cache: &cache)

        var columnTops = [CGFloat](repeating: 0, count: columnCount)
        var frames: [CGRect] = []
        frames.reserveCapacity(subviews.count)

        for (index, subview) in subviews.enumerated() {
            let column = cache.columnOfSubview[index]
            let height = subview.sizeThatFits(itemProposal).height
            let x = CGFloat(column) * (columnWidth + spacing)
            let y = columnTops[column]
            frames.append(CGRect(x: x, y: y, width: columnWidth, height: height))
            columnTops[column] = y + height + spacing
        }

        cache.frames = frames
        cache.totalHeight = frames.isEmpty ? 0 : max((columnTops.max() ?? 0) - spacing, 0)
    }

    private func resolveColumns(
        subviews: Subviews,
        columnCount: Int,
        itemProposal: ProposedViewSize,
        cache: inout Cache
    ) {
        guard cache.columnOfSubview.count < subviews.count else { return }

        var columnTops = columnBottoms(
            through: cache.columnOfSubview.count,
            subviews: subviews,
            columnCount: columnCount,
            columnOfSubview: cache.columnOfSubview,
            itemProposal: itemProposal
        )

        while cache.columnOfSubview.count < subviews.count {
            let index = cache.columnOfSubview.count
            let height = subviews[index].sizeThatFits(itemProposal).height
            let column = columnTops.indices.min(by: { columnTops[$0] < columnTops[$1] }) ?? 0
            cache.columnOfSubview.append(column)
            columnTops[column] += height + spacing
        }
    }

    private func columnBottoms(
        through count: Int,
        subviews: Subviews,
        columnCount: Int,
        columnOfSubview: [Int],
        itemProposal: ProposedViewSize
    ) -> [CGFloat] {
        var tops = [CGFloat](repeating: 0, count: columnCount)
        guard count > 0 else { return tops }
        for index in 0 ..< count {
            let height = subviews[index].sizeThatFits(itemProposal).height
            tops[columnOfSubview[index]] += height + spacing
        }
        return tops
    }

    private func widthDiffers(_ cached: CGFloat, from width: CGFloat) -> Bool {
        cached < 0 || abs(cached - width) > 0.5
    }
}