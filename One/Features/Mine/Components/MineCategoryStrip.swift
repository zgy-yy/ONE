import SwiftUI

/// 喜欢列表 / 单个收藏夹内内容的分类筛选（`ContentCategory`）。
struct MineCategoryStrip: View {
    @Binding var category: ContentCategory

    var body: some View {
        TopCapsuleBar(
            items: Array(ContentCategory.allCases),
            selectedID: category,
            title: \.title,
            id: \.self,
            onSelect: { category = $0 }
        )
    }
}
