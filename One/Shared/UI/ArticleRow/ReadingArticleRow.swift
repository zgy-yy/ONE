import SwiftUI

/// 发现「阅读」列表行：左侧方形封面，右侧标题 / 作者 / 喜欢数。
struct ReadingArticleRow: View {
    let article: ArticleSummary

    private let coverWidth: CGFloat = 96

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(
                path: article.thumb,
                aspectRatio: CoverAspect.square,
                cornerRadius: 8
            )
            .frame(width: coverWidth)

            VStack(alignment: .leading, spacing: 8) {
                Text(article.displayTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    if let author = article.author?.nonEmpty {
                        Text(author)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if let likes = article.likeNumber {
                        MetaIconText(systemImage: "heart", text: "\(likes)")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .matchCoverHeight(width: coverWidth, aspect: CoverAspect.square)
        }
        .padding(.vertical, 2)
    }
}
