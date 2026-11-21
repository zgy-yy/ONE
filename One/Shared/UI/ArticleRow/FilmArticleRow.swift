import SwiftUI

/// 发现「影视」：封面角标 + 底栏播放/互动；封面下标题、作者与日期。
struct FilmArticleRow: View {
    let article: ArticleSummary

    var body: some View {
        ArticleCardChromeCoverTop {
            cover
        } text: {
            VStack(alignment: .leading, spacing: 8) {
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
        .overlay(alignment: .bottom) {
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
    List {
        FilmArticleRow(article: FilmArticleRowPreview.longTitle)
            .styledListRow()
        FilmArticleRow(article: FilmArticleRowPreview.shortTitle)
            .styledListRow()
    }
    .plainContentList()
}

/// 预览用假数据（`thumb` 为公开 https 图，不走 `one_img` CDN）。
private enum FilmArticleRowPreview {
    private static let coverA =
        "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=560&h=315&fit=crop"
    private static let coverB =
        "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=560&h=315&fit=crop"

    static let longTitle = ArticleSummary(
        id: 9001,
        title: "漫长的季节 · 全集回顾",
        thumb: coverA,
        author: "辛爽",
        publishedAt: "2024-03-15 12:00:00",
        modelID: ContentCategory.ModelID.film,
        summary: nil,
        likeNumber: 12_800,
        collectionNumber: 3200,
        views: 1_413_682,
        isLike: 1,
        isCollected: 0,
        vol: 3
    )

    static let shortTitle = ArticleSummary(
        id: 9002,
        title: "海边一日",
        thumb: coverB,
        author: "佚名",
        publishedAt: "2023-11-01",
        modelID: ContentCategory.ModelID.film,
        summary: nil,
        likeNumber: 256,
        collectionNumber: 890,
        views: 52_000,
        isLike: 0,
        isCollected: 1,
        vol: 1
    )
}
