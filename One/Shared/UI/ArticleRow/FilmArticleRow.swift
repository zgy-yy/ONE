import SwiftUI

/// 发现「影视」：封面左上角标、右上播放量、左下收藏·喜欢；封面下标题、作者与日期。
struct FilmArticleRow: View {
    let article: ArticleSummary

    private let textBackdropHorizontal: CGFloat = 8
    private let textBackdropVertical: CGFloat = 6

    var body: some View {
        ArticleCardChromeCoverTop(
            textBackdropHorizontal: textBackdropHorizontal,
            textBackdropVertical: textBackdropVertical
        ) {
            cover
        } text: {
            VStack(alignment: .leading, spacing: 6) {
                Text(article.displayTitle)
                    .font(ArticleRowTypography.filmTitle)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if showsAuthorOrDate {
                    authorDateRow
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var cover: some View {
        OneCoverImage(
            path: article.thumb,
            aspectRatio: CoverAspect.landscape,
            cornerRadius: 0
        )
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topLeading) {
            CoverCategoryVolumeBadge(systemImage: "film", vol: article.vol)
        }
        .overlay {
            CoverEngagementBar(article: article)
        }
    }

    private var showsAuthorOrDate: Bool {
        article.author?.nonEmpty != nil
            || ArticleFormat.dateOnly(from: article.publishedAt) != nil
    }

    private var authorDateRow: some View {
        HStack(spacing: 8) {
            if let authorLine = article.homeAuthorLine() {
                Text(authorLine)
                    .font(ArticleRowTypography.summary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            ArticleDateText(publishedAt: article.publishedAt, font: ArticleRowTypography.summary)
        }
    }

}

#Preview("影视行") {
    PreviewListChrome.list {
        FilmArticleRow(article: PreviewSamples.Article.filmLong).styledListRow()
        FilmArticleRow(article: PreviewSamples.Article.filmShort).styledListRow()
    }
}
