import SwiftUI

/// 发现页图文竖卡：封面左上第 N 期、右上播放量、左下收藏·喜欢；作者右侧日期。
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
                publishedAt: article.publishedAt,
                summary: article.summary?.nonEmpty,
                titleAlignment: textAlignment,
                summaryAlignment: textAlignment,
                summaryLineLimit: 2
            )
        }
    }

    private var cover: some View {
        OneCoverImage(
            path: article.thumb,
            aspectRatio: CoverAspect.portrait,
            cornerRadius: 0
        )
        .overlay(alignment: .topLeading) {
            if let vol = article.vol {
                Text("第\(vol)期")
                    .font(ArticleRowTypography.CoverBar.volume)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(8)
            }
        }
        .overlay {
            CoverEngagementBar(article: article, horizontalPadding: 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

#Preview("发现图文") {
    HStack(alignment: .top, spacing: 10) {
        GraphicArticleCard(article: PreviewSamples.Article.graphic, textAlignment: .leading)
        GraphicArticleCard(article: PreviewSamples.Article.graphic, textAlignment: .leading)
    }.styledListRow()
}
