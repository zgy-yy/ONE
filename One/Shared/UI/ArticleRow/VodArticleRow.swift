import SwiftUI

/// 点播行：左上角期数、右上播放量；封面底标题与作者 / 时长；下为金额与互动。
struct VodArticleRow: View {
    let article: ArticleSummary
    var aspectRatio: CGFloat = CoverAspect.landscape

    private let textBackdropHorizontal: CGFloat = 8
    private let textBackdropVertical: CGFloat = 6

    var body: some View {
        ArticleCardChromeCoverTop(
            textBackdropHorizontal: textBackdropHorizontal,
            textBackdropVertical: textBackdropVertical
        ) {
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
        .overlay(alignment: .topTrailing) {
            if let views = article.views {
                CoverStatLabel(
                    icon: "eye",
                    text: ArticleFormat.shortCount(views),
                    font: ArticleRowTypography.CoverBar.views
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
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
        }
        .font(ArticleRowTypography.summary)
    }

    private var metaBar: some View {
        HStack(spacing: 14) {
            priceBlock
            Spacer(minLength: 0)
            ArticleCollectLikeMeta(article: article, itemSpacing: 6)
                .font(ArticleRowTypography.metaSmall)
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
    PreviewListChrome.list {
        VodArticleRow(article: PreviewSamples.Article.vod).styledListRow()
        VodArticleRow(article: PreviewSamples.Article.vodDiscount).styledListRow()
    }
}
