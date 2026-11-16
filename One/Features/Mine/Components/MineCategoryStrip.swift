import SwiftUI

/// 喜欢 / 收藏顶部的内容分类条。
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
