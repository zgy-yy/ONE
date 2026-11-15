import SwiftUI

/// 顶部胶囊筛选条 + 底部分割线（搜索 / 喜欢 / 收藏等共用）。
struct TopCapsuleBar<Item: Identifiable, ID: Hashable>: View {
    let items: [Item]
    let selectedID: ID?
    let title: (Item) -> String
    let id: (Item) -> ID
    let onSelect: (Item) -> Void
    var compact: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HorizontalCapsuleStrip(
                items: items,
                selectedID: selectedID,
                title: title,
                id: id,
                onSelect: onSelect,
                compact: compact
            )
            Divider()
        }
        .background(Color(.systemBackground))
    }
}
