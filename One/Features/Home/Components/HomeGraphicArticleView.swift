import SwiftUI

/// 首页图文竖卡：封面右上播放量、右下收藏·喜欢；文案见 `GraphicCardTextBlock`。
struct HomeGraphicArticleView: View {
    let article: ArticleSummary
    var showsDescription: Bool = true
    var cornerRadius: CGFloat = 8

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            cover
            GraphicCardTextBlock(
                title: article.displayTitle,
                author: article.author?.nonEmpty,
                summary: article.summary?.nonEmpty,
                showsSummary: showsDescription,
                summaryLineLimit: nil
            )
        }
    }

    private var cover: some View {
        OneCoverImage(
            path: article.thumb,
            usesOriginalAspectRatio: true,
            placeholderAspectRatio: CoverAspect.portrait,
            cornerRadius: 0
        )
        .overlay(alignment: .topTrailing) {
            if let views = article.views {
                CoverStatLabel(
                    icon: "eye",
                    text: ArticleFormat.shortCount(views),
                    font: ArticleRowTypography.GraphicCard.views
                )
                .padding(8)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            ArticleCollectLikeMeta(article: article, onDarkOverlay: true, itemSpacing: 6)
                .font(ArticleRowTypography.GraphicCard.reactions)
                .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

#Preview("首页图文") {
    PreviewListChrome.list {
        HomeGraphicArticleView(article: PreviewSamples.Article.graphic).styledListRow()
    }
}