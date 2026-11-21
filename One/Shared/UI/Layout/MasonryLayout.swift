import SwiftUI

/// 两列瀑布流：子视图顺序与列表一致（0 左、1 右、2 左…），各列独立向下叠放，不拉高行高留空。
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

        if widthDiffers(cache.width, from: width) || cache.columnOfSubview.count != subviews.count {
            cache.columnOfSubview = (0 ..< subviews.count).map { column(forListIndex: $0, columnCount: columnCount) }
        }
        cache.width = width

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

    /// 列表下标 0 在左列；与 `Layout` 子视图遍历方向对齐（两列时左右对调修正）。
    private func column(forListIndex index: Int, columnCount: Int) -> Int {
        let slot = index % columnCount
        guard columnCount == 2 else { return slot }
        return 1 - slot
    }

    private func widthDiffers(_ cached: CGFloat, from width: CGFloat) -> Bool {
        cached < 0 || abs(cached - width) > 0.5
    }
}