import SwiftUI

/// 首页日更「非图文」条目：类型 → 标题 → 作者 → 简介 → 横图封面（期数 / 播放 / 互动）。
struct HomeFeedArticleView: View {
    let article: ArticleSummary
    var showsDescription: Bool = true
    var cornerRadius: CGFloat = 8

    private var category: ContentCategory { article.listCategory }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.title)
                .font(ArticleRowTypography.metaSmall)
                .foregroundStyle(.tertiary)

            Text(article.displayTitle)
                .font(ArticleRowTypography.filmTitle)
                .foregroundStyle(.primary)
                .lineLimit(2)

            if let authorLine = article.homeAuthorLine() {
                Text(authorLine)
                    .font(ArticleRowTypography.summary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if showsDescription, let summary = article.summary?.nonEmpty {
                Text(summary)
                    .font(ArticleRowTypography.summary)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            cover
        }
    }

    private var cover: some View {
        OneCoverImage(
            path: article.thumb,
            aspectRatio: CoverAspect.landscape,
            cornerRadius: 0
        )
        .overlay(alignment: .topLeading) {
            CoverCategoryVolumeBadge(
                systemImage: category.coverVolumeBadgeIcon,
                vol: article.vol
            )
        }
        .overlay(alignment: .bottom) {
            CoverEngagementBar(article: article)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}