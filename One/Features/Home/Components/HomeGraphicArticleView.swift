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
    List {
        HomeGraphicArticleView(article: HomeGraphicArticlePreview.sample)
            .styledListRow()
    }
    .plainContentList()
}

private enum HomeGraphicArticlePreview {
    private static let thumb =
        "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&h=533&fit=crop"

    static let sample = ArticleSummary(
        id: 8301,
        title: "首页图文",
        thumb: thumb,
        author: "摄影组",
        publishedAt: "2024-07-01",
        modelID: ContentCategory.ModelID.graphic,
        summary: "简介不限制行数，封面按原图比例。",
        likeNumber: 888,
        collectionNumber: 120,
        views: 42_000,
        isLike: 1,
        isCollected: 0
    )
}