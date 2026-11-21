import SwiftUI

/// 发现「电台」：封面标识 + 底栏标题播放；下方作者 / 收藏 / 喜欢 / 日期。
struct RadioArticleRow: View {
    let article: ArticleSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            cover
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
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
    List {
        RadioArticleRow(article: RadioArticleRowPreview.withVolume)
            .styledListRow()
        RadioArticleRow(article: RadioArticleRowPreview.compact)
            .styledListRow()
    }
    .plainContentList()
}

/// 预览用假数据（`thumb` 为公开 https 图）。
private enum RadioArticleRowPreview {
    private static let coverA =
        "https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=560&h=315&fit=crop"
    private static let coverB =
        "https://images.unsplash.com/photo-1590602847861-f357a9332bbc?w=560&h=315&fit=crop"

    static let withVolume = ArticleSummary(
        id: 9101,
        title: "午夜电台 · 城市漫步",
        thumb: coverA,
        author: "小林",
        publishedAt: "2024-05-20 18:00:00",
        modelID: ContentCategory.ModelID.radio,
        summary: nil,
        likeNumber: 3200,
        collectionNumber: 512,
        isLike: 1,
        isCollected: 0,
        vol: 128
    )

    static let compact = ArticleSummary(
        id: 9102,
        title: "短标题一期",
        thumb: coverB,
        author: "电台编辑部",
        publishedAt: "2023-09-01",
        modelID: ContentCategory.ModelID.radio,
        summary: nil,
        likeNumber: 88,
        collectionNumber: nil,
        isLike: 0,
        isCollected: 1,
        vol: 12
    )
}
