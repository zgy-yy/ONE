import SwiftUI

/// 首页日更「非图文」：上文案、下封面一体卡片；仅分类名居中，文案区毛玻璃衬底。
struct HomeFeedArticleView: View {
    let article: ArticleSummary
    var showsDescription: Bool = true
    var cornerRadius: CGFloat = 8

    private var category: ContentCategory { article.listCategory }

    var body: some View {
        ArticleCardChrome(cornerRadius: cornerRadius) {
            textBlock
        } cover: {
            cover
        }
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            articleCardCategoryTitle(category.title)

            Text(article.displayTitle)
                .font(ArticleRowTypography.HomeFeedCard.title)
                .foregroundStyle(.primary)
                .lineLimit(2)

            if let authorLine = article.homeAuthorLine() {
                Text(authorLine)
                    .font(ArticleRowTypography.HomeFeedCard.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if showsDescription, let summary = article.summary?.nonEmpty {
                Text(summary)
                    .font(ArticleRowTypography.HomeFeedCard.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
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
    }
}