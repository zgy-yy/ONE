import SwiftUI

/// 列表行：封面下方单行标题。
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
    var rowMeta: ArticleRowMeta {
        ArticleRowMeta(title: displayTitle)
    }
}
