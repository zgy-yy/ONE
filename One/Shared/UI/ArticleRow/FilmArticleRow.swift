import SwiftUI

/// 发现「影视」列表行：左侧 16:9 封面，右侧标题 / 收藏 / 喜欢 / 期数。
struct FilmArticleRow: View {
    let article: ArticleSummary

    private let coverWidth: CGFloat = 156

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
                    Button(action: ArticleRowActions.favorite) {
                        Image(systemName: "bookmark")
                    }
                    .buttonStyle(.borderless)
                    if let likes = article.likeNumber {
                        Button(action: ArticleRowActions.like) {
                            MetaIconText(systemImage: "heart", text: "\(likes)")
                        }
                        .buttonStyle(.borderless)
                    }
                    if let vol = article.vol {
                        MetaIconText(systemImage: "number", text: "\(vol)期")
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            }
            .matchCoverHeight(width: coverWidth)
        }
        .padding(.vertical, 2)
    }
}
