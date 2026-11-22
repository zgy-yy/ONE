import SwiftUI

/// 发现「电台」：封面标识 + 底栏标题播放；下方作者 / 收藏 / 喜欢 / 日期。
struct RadioArticleRow: View {
    let article: ArticleSummary

    var body: some View {
        ArticleCardChromeCoverTop {
            cover
        } text: {
            metaRow
        }
        .padding(.vertical, 2)
    }

    private var cover: some View {
        OneCoverImage(
            path: article.thumb,
            aspectRatio: CoverAspect.landscape,
            cornerRadius: 0
        )
        .overlay(alignment: .topLeading) {
            CoverCategoryVolumeBadge(systemImage: "radio", vol: article.vol)
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 10) {
                Text(article.displayTitle)
                    .font(ArticleRowTypography.title)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background { CoverBottomFade() }
        }
    }

    private var metaRow: some View {
        HStack(spacing: 14) {
            if let author = article.author?.nonEmpty {
                Text("主播 / \(author)")
                    .font(ArticleRowTypography.meta)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            ArticleCollectLikeMeta(article: article, itemSpacing: 6)
                .font(ArticleRowTypography.metaSmall)
            ArticleDateText(publishedAt: article.publishedAt, font: ArticleRowTypography.metaSmall)
        }
    }
}

#Preview("电台行") {
    PreviewListChrome.list {
        RadioArticleRow(article: PreviewSamples.Article.radio).styledListRow()
        RadioArticleRow(article: PreviewSamples.Article.radioShort).styledListRow()
    }
}
