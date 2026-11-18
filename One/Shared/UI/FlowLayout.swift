import SwiftUI

/// 从左到右排布子视图，放不下就换行；宽度跟内容走，不强制等宽。
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(maxWidth: resolvedMaxWidth(proposal), subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        // 实际布局用 bounds 宽度，避免依赖已弃用的 UIScreen.main。
        let result = arrange(maxWidth: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: .unspecified
            )
        }
    }

    private struct Arrangement {
        var origins: [CGPoint]
        var size: CGSize
    }

    /// ScrollView 偶发 nil 宽时用有限默认值，避免无限宽单行撑出横滑。
    private func resolvedMaxWidth(_ proposal: ProposedViewSize) -> CGFloat {
        if let width = proposal.width, width.isFinite, width > 0 {
            return width
        }
        return 393
    }

    private func arrange(maxWidth: CGFloat, subviews: Subviews) -> Arrangement {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalWidth = max(totalWidth, min(x - spacing, maxWidth))
        }

        return Arrangement(
            origins: origins,
            size: CGSize(width: min(totalWidth, maxWidth), height: y + rowHeight)
        )
    }
}
