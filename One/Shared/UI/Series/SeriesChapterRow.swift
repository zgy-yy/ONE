import SwiftUI

/// 系列详情里的章节行（只负责展示，跳转由外层 `NavigationLink` 处理）。
struct SeriesChapterRow: View {
    let chapter: SeriesChapter
    private let coverWidth: CGFloat = 186

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            OneCoverImage(path: chapter.imagePath)
                .frame(width: coverWidth)

            VStack(alignment: .leading, spacing: 6) {
                Text(chapter.displayTitle)
                    .font(ArticleRowTypography.title)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(chapter.description?.nonEmpty ?? "")
                    .font(ArticleRowTypography.summary)
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                ArticleDateText(publishedAt: chapter.publishedAt)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .matchCoverHeight(width: coverWidth)
        }
        .padding(.vertical, 2)
    }
}

#Preview("章节行") {
    List {
        SeriesChapterRow(chapter: SeriesChapterRowPreview.full)
            .styledListRow()
        SeriesChapterRow(chapter: SeriesChapterRowPreview.compact)
            .styledListRow()
    }
    .plainContentList()
}

private enum SeriesChapterRowPreview {
    private static let coverA =
        "https://images.unsplash.com/photo-1494976388531-d105849fbeb8?w=400&h=600&fit=crop"
    private static let coverB =
        "https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=400&h=600&fit=crop"

    static let full = SeriesChapter(
        id: 7001,
        title: "第十二章 · 海风与余温",
        thumb: coverA,
        chapter: 12,
        description: "两行长简介：章节更新说明，用来预览固定两行高度与底栏对齐效果。",
        publishedAt: "2024-07-08 12:00:00"
    )

    static let compact = SeriesChapter(
        id: 7002,
        title: "短标题",
        thumb: coverB,
        chapter: 3,
        description: nil,
        publishedAt: "2024-01-02"
    )
}
