import SwiftUI

/// 发现「影视」列表行：左侧 16:9 封面，右侧标题 / 喜欢 / 时长（无作者、无金额）。
struct FilmArticleRow: View {
    let article: ArticleSummary

    private let coverWidth: CGFloat = 148

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(
                path: article.thumb,
                aspectRatio: CoverAspect.landscape,
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

                HStack(spacing: 14) {
                    if let likes = article.likeNumber {
                        Label("\(likes)", systemImage: "heart.fill")
                    }
                    if let length = article.length?.nonEmpty {
                        Label(length, systemImage: "clock.fill")
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
            }
            .frame(maxWidth: .infinity, minHeight: coverWidth / CoverAspect.landscape, alignment: .topLeading)
        }
        .padding(.vertical, 6)
    }
}
