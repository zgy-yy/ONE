import SwiftUI

/// 系列章节行（系列详情 / 首页写真漫画条目）。
struct SeriesChapterRow: View {
    let chapter: SeriesChapter
    var showsDate: Bool = true
    private let coverWidth: CGFloat = 156

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(path: chapter.imagePath)
                .frame(width: coverWidth)

            VStack(alignment: .leading, spacing: 6) {
                Text(chapter.displayTitle)
                    .font(ArticleRowTypography.title)
                    .lineLimit(2)

                if let description = chapter.description?.nonEmpty {
                    Text(description)
                        .font(ArticleRowTypography.summary)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 4) {
                    if chapter.author?.nonEmpty != nil || chapter.likeNumber != nil {
                        HStack(spacing: 8) {
                            if let author = chapter.author?.nonEmpty {
                                Text(author).lineLimit(1)
                            }
                            if let likes = chapter.likeNumber {
                                MetaIconText.likes(likes)
                            }
                        }
                        .font(ArticleRowTypography.summary)
                        .foregroundStyle(.secondary)
                    }

                    if showsDate {
                        ArticleDateText(publishedAt: chapter.publishedAt)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .matchCoverHeight(width: coverWidth)
        }
        .padding(.vertical, 2)
    }
}
