import SwiftUI

/// 首页日更「图文」：全宽 3:4 封面，下方标题 + 作者。
struct HomeGraphicArticleRow: View {
    let article: ArticleSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            OneCoverImage(
                path: article.thumb,
                aspectRatio: CoverAspect.portrait,
                cornerRadius: 8
            )

            if let author = article.author?.nonEmpty {
                Text(author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(article.displayTitle)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}
