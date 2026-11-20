import SwiftUI

/// 搜索列表行：左固定封面，右标题 + 作者/日期。
struct SearchResultRow: View {
    let hit: SearchHit

    /// 各频道封面统一尺寸，不随 `ContentCategory.coverAspect` 变化。
    private static let coverWidth: CGFloat = 120
    private static let coverAspect = CoverAspect.landscape

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(
                path: hit.imagePath,
                aspectRatio: Self.coverAspect,
                cornerRadius: 8
            )
            .frame(width: Self.coverWidth)

            VStack(alignment: .leading, spacing: 6) {
                Text(hit.displayTitle)
                    .font(ArticleRowTypography.filmTitle)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                HStack(spacing: 8) {
                    if let author = hit.author?.nonEmpty {
                        Text(author)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    ArticleDateText(publishedAt: hit.publishedAt)
                }
                .font(ArticleRowTypography.summary)

                Spacer(minLength: 0)
            }
            .matchCoverHeight(width: Self.coverWidth)
        }
        .padding(.vertical, 2)
    }
}