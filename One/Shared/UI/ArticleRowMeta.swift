import SwiftUI

/// 列表行标题：封面下方单行文案。
struct ArticleRowMeta: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.body.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension ArticleSummary {
    /// 用 `displayTitle` 生成列表标题视图，方便 `VodArticleRow` 直接嵌入。
    var rowMeta: ArticleRowMeta {
        ArticleRowMeta(title: displayTitle)
    }
}
