import SwiftUI

/// 列表行标题 / 作者 / 时间（与详情元信息字段一致）。
struct ArticleRowMeta: View {
    let title: String
    let author: String?
    let publishedAt: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
            if let author, !author.isEmpty {
                Text(author)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let publishedAt, !publishedAt.isEmpty {
                Text(publishedAt)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

extension ArticleSummary {
    var rowMeta: ArticleRowMeta {
        ArticleRowMeta(title: displayTitle, author: author, publishedAt: publishedAt)
    }
}
