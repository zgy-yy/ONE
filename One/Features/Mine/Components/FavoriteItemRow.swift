import SwiftUI

/// 收藏夹内竖卡：上封面、下文案（与 `FilmArticleRow` 同套衬底）；封面底栏可点喜欢 / 收藏。
struct FavoriteItemRow: View {
    let item: FavoriteItem

    @Bindable private var session = MineLibrarySession.shared

    private var article: ArticleSummary { item.asArticleSummary }

    private var coverAspect: CGFloat {
        item.listCategory.coverAspect
    }

    var body: some View {
        ArticleCardChromeCoverTop {
            coverBlock
        } text: {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayTitle)
                    .font(ArticleRowTypography.filmTitle)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                metaRow
            }
        }
    }

    private var metaRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(item.typeAuthorLine)
                .font(ArticleRowTypography.summary)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let collectDate = ArticleFormat.dateOnly(from: item.collectTime) {
                Text(collectDate)
                    .font(ArticleRowTypography.summary)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
        }
    }

    private var coverBlock: some View {
        OneCoverImage(
            path: item.imagePath,
            aspectRatio: coverAspect,
            cornerRadius: 0
        )
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topLeading) {
            coverTopLeadingBadge
        }
        .overlay(alignment: .bottomTrailing) {
            ArticleCollectLikeMeta(
                article: article,
                onDarkOverlay: true,
                itemSpacing: 6,
                onUncollect: { session.removeFavorite(articleID: $0) }
            )
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background { CoverBottomFade(opacity: 0.65) }
        }
    }

    @ViewBuilder
    private var coverTopLeadingBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: item.listCategory.coverVolumeBadgeIcon)
                .font(.caption2.weight(.semibold))
            if let date = ArticleFormat.dateOnly(from: item.publishedAt) {
                Text(date)
                    .font(ArticleRowTypography.coverVolume)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.black.opacity(0.38), in: Capsule())
        .padding(6)
    }
}