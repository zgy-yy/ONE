import SwiftUI

/// 点播行：左上角期数；封面底标题与作者 / 时长 / 播放量；下为金额与互动。
struct VodArticleRow: View {
    let article: ArticleSummary
    var aspectRatio: CGFloat = CoverAspect.landscape

    var body: some View {
        ArticleCardChromeCoverTop {
            cover
                .allowsHitTesting(false)
        } text: {
            metaBar
        }
        .padding(.vertical, 2)
    }

    private var cover: some View {
        OneCoverImage(
            path: article.thumb,
            aspectRatio: aspectRatio,
            cornerRadius: 0
        )
        .overlay(alignment: .topLeading) {
            CoverCategoryVolumeBadge(systemImage: "play.rectangle", vol: article.vol)
        }
        .overlay(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.displayTitle)
                    .font(ArticleRowTypography.title)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if showsSubtitleRow {
                    coverSubtitleRow
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { CoverBottomFade() }
        }
    }

    private var showsSubtitleRow: Bool {
        article.author?.nonEmpty != nil
            || article.length?.nonEmpty != nil
            || article.views != nil
    }

    private var coverSubtitleRow: some View {
        HStack(alignment: .center, spacing: 8) {
            if let author = article.author?.nonEmpty {
                Text(author)
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
            }
            if let length = article.length?.nonEmpty {
                MetaIconText(systemImage: "clock", text: length, onDarkOverlay: true)
            }
            Spacer(minLength: 0)
            if let views = article.views {
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                    Text(ArticleFormat.shortCount(views))
                }
                .font(ArticleRowTypography.metaSmall)
                .foregroundStyle(.white.opacity(0.9))
            }
        }
        .font(ArticleRowTypography.summary)
    }

    private var metaBar: some View {
        HStack(spacing: 14) {
            priceBlock
            Spacer(minLength: 0)
            ArticleCollectLikeMeta(article: article)
            ArticleDateText(publishedAt: article.publishedAt)
        }
        .font(ArticleRowTypography.meta)
    }

    @ViewBuilder
    private var priceBlock: some View {
        if article.coin != nil || article.originalCoin != nil {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let price = article.coin {
                    Text("¥\(price)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.orange)
                }
                if let original = article.originalCoin, original != article.coin {
                    Text("¥\(original)")
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
            }
        }
    }
}

#Preview("点播行") {
    List {
        VodArticleRow(article: VodArticleRowPreview.full)
            .styledListRow()
        VodArticleRow(article: VodArticleRowPreview.discount)
            .styledListRow()
    }
    .plainContentList()
}

/// 预览用假数据（`thumb` 为公开 https 图）。
private enum VodArticleRowPreview {
    private static let coverA =
        "https://images.unsplash.com/photo-1574267432645-b74e72d8b193?w=560&h=315&fit=crop"
    private static let coverB =
        "https://images.unsplash.com/photo-1485846230555-89fc4e4f964b?w=560&h=315&fit=crop"

    static let full = ArticleSummary(
        id: 9301,
        title: "导演访谈 · 幕后纪录完整版",
        thumb: coverA,
        author: "Studio One",
        publishedAt: "2024-04-12 20:00:00",
        modelID: ContentCategory.ModelID.vod,
        summary: nil,
        coin: 12,
        originalCoin: 18,
        likeNumber: 640,
        collectionNumber: 220,
        views: 128_400,
        isLike: 1,
        isCollected: 0,
        length: "129分钟",
        vol: 7
    )

    static let discount = ArticleSummary(
        id: 9302,
        title: "短片选",
        thumb: coverB,
        author: "独立映像",
        publishedAt: "2023-08-05",
        modelID: ContentCategory.ModelID.vod,
        summary: nil,
        coin: 6,
        originalCoin: nil,
        likeNumber: 42,
        collectionNumber: 8,
        views: 9200,
        isLike: 0,
        isCollected: 1,
        length: "24分钟",
        vol: 2
    )
}