import SwiftUI

/// 发现「图文」瀑布流卡片（与首页 `HomeGraphicArticleView` 不同：含封面底栏与互动区）。
struct GraphicArticleCard: View {
    let article: ArticleSummary
    var textAlignment: TextAlignment = .center
    var cornerRadius: CGFloat = 8

    private var stackAlignment: HorizontalAlignment {
        textAlignment == .center ? .center : .leading
    }

    private var frameAlignment: Alignment {
        textAlignment == .center ? .center : .leading
    }

    var body: some View {
        VStack(alignment: stackAlignment, spacing: 6) {
            cover
            titleLine(article.displayTitle)
            if let summary = article.summary?.nonEmpty {
                descriptionLine(summary)
            }
            if let author = article.author?.nonEmpty {
                metaLine(author)
            }
            HStack(alignment: .center, spacing: 4) {
                ArticleDateText(publishedAt: article.publishedAt, font: ArticleRowTypography.metaSmall)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .layoutPriority(-1)
                Spacer(minLength: 4)
                ArticleCollectLikeMeta(article: article, itemSpacing: 6)
                    .layoutPriority(1)
            }
            .font(ArticleRowTypography.metaSmall)
            .frame(maxWidth: .infinity)
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
                    CoverStatLabel(icon: "eye", text: ArticleFormat.shortCount(views))
                }
                Spacer(minLength: 0)
                if let vol = article.vol {
                    Text("第\(vol)期")
                        .font(ArticleRowTypography.summary)
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

    private func titleLine(_ text: String) -> some View {
        Text(text)
            .font(ArticleRowTypography.cardTitle)
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(textAlignment)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private func descriptionLine(_ text: String) -> some View {
        Text(text)
            .font(ArticleRowTypography.summary)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(textAlignment)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private func metaLine(_ text: String) -> some View {
        Text(text)
            .font(ArticleRowTypography.metaSmall)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .multilineTextAlignment(textAlignment)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
    }
}

#Preview("图文卡片") {
    List {
        HStack(alignment: .top, spacing: 10) {
            GraphicArticleCard(
                article: GraphicArticleCardPreview.sample,
                textAlignment: .leading
            )
            GraphicArticleCard(
                article: GraphicArticleCardPreview.shortTitle,
                textAlignment: .leading
            )
        }
        .styledListRow()
    }
    .plainContentList()
}

private enum GraphicArticleCardPreview {
    private static let coverA =
        "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&h=533&fit=crop"
    private static let coverB =
        "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=640&h=400&fit=crop"

    static let sample = ArticleSummary(
        id: 9201,
        title: "夏日街拍特辑 · 两列网格",
        thumb: coverA,
        author: "图文编辑部",
        publishedAt: "2024-06-18 10:00:00",
        modelID: ContentCategory.ModelID.graphic,
        summary: "简介最多两行，配合不等高封面在 Masonry 里更有错落感。",
        likeNumber: 2048,
        collectionNumber: 3120,
        views: 98_000,
        isLike: 1,
        isCollected: 0,
        vol: 18
    )

    static let shortTitle = ArticleSummary(
        id: 9202,
        title: "短标题",
        thumb: coverB,
        author: "作者 B",
        publishedAt: "2023-12-01",
        modelID: ContentCategory.ModelID.graphic,
        summary: nil,
        likeNumber: 56,
        collectionNumber: 12,
        views: 31200,
        isLike: 0,
        isCollected: 1,
        vol: 3
    )
}
