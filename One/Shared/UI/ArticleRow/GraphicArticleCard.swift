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
            aspectRatio: CoverAspect.portrait,
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
    HStack(alignment: .top, spacing: 10) {
        GraphicArticleCard(article: PreviewSamples.Article.graphic, textAlignment: .leading)
        GraphicArticleCard(article: PreviewSamples.Article.graphic, textAlignment: .leading)
    }.styledListRow()
}
