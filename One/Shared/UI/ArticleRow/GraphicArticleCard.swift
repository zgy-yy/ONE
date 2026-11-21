import SwiftUI

/// 发现页图文竖卡：封面底栏播放量与期数；文末日期与收藏·喜欢。
struct GraphicArticleCard: View {
    let article: ArticleSummary
    var textAlignment: TextAlignment = .center
    var cornerRadius: CGFloat = 8

    var body: some View {
        VStack(alignment: textAlignment == .center ? .center : .leading, spacing: 6) {
            cover
            GraphicCardTextBlock(
                title: article.displayTitle,
                author: article.author?.nonEmpty,
                summary: article.summary?.nonEmpty,
                titleAlignment: textAlignment,
                summaryAlignment: textAlignment,
                summaryLineLimit: 2
            )
            footerRow
        }
    }

    private var cover: some View {
        OneCoverImage(
            path: article.thumb,
            usesOriginalAspectRatio: true,
            placeholderAspectRatio: CoverAspect.portrait,
            cornerRadius: 0
        )
        .overlay(alignment: .bottom) {
            HStack(spacing: 8) {
                if let views = article.views {
                    CoverStatLabel(
                        icon: "eye",
                        text: ArticleFormat.shortCount(views),
                        font: ArticleRowTypography.GraphicCard.views
                    )
                }
                Spacer(minLength: 0)
                if let vol = article.vol {
                    Text("第\(vol)期")
                        .font(ArticleRowTypography.CoverBar.volume)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background { CoverBottomFade() }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var footerRow: some View {
        HStack(alignment: .center, spacing: 4) {
            ArticleDateText(
                publishedAt: article.publishedAt,
                font: ArticleRowTypography.GraphicCard.date
            )
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .layoutPriority(-1)
            Spacer(minLength: 4)
            ArticleCollectLikeMeta(article: article, itemSpacing: 6)
                .layoutPriority(1)
        }
        .font(ArticleRowTypography.GraphicCard.reactions)
        .frame(maxWidth: .infinity)
    }
}

#Preview("发现图文") {
    List {
        GraphicArticleCard(article: GraphicArticleCardPreview.sample, textAlignment: .leading)
            .styledListRow()
    }
    .plainContentList()
}

private enum GraphicArticleCardPreview {
    private static let thumb =
        "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&h=533&fit=crop"

    static let sample = ArticleSummary(
        id: 9201,
        title: "夏日街拍",
        thumb: thumb,
        author: "编辑部",
        publishedAt: "2024-06-18",
        modelID: ContentCategory.ModelID.graphic,
        summary: "简介最多两行。",
        likeNumber: 2048,
        collectionNumber: 3120,
        views: 98_000,
        isLike: 1,
        isCollected: 0,
        vol: 18
    )
}