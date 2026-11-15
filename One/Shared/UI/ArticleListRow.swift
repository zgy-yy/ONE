import SwiftUI

/// 主流列表行：全宽封面 + 标题（可选作者）。
///
/// `fallbackModelID`：列表没回传 `model_id` 时，用频道已知类型决定竖图 / 横图。
struct ArticleListRow: View {
    let article: ArticleSummary
    var fallbackModelID: Int? = nil
    var showsAuthor: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            OneCoverImage(
                path: article.thumb,
                aspectRatio: article.coverAspectRatio(fallbackModelID: fallbackModelID)
            )
            if showsAuthor, let author = article.author?.nonEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    article.rowMeta
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                article.rowMeta
            }
        }
        .padding(.vertical, 4)
    }
}
