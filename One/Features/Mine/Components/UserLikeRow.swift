import SwiftUI

/// 我的喜欢列表行：左封面（左上角品类角标），右标题 / 类型·作者 / 日期与可取消的喜欢。
struct UserLikeRow: View {
    let item: UserLikeItem
    @Bindable var session: MineLibrarySession

    @Bindable private var reactions = ArticleReactionStore.shared

    private let coverWidth: CGFloat = 152
    private let coverAspect = CoverAspect.landscape

    private var article: ArticleSummary { item.asArticleSummary }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            coverBlock

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                if let line = item.typeAuthorLine {
                    Text(line)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                metaRow
            }
            .matchCoverHeight(width: coverWidth, aspect: coverAspect)
        }
        .padding(.vertical, 4)
    }

    private var coverBlock: some View {
        OneCoverImage(
            path: item.imagePath,
            aspectRatio: coverAspect,
            cornerRadius: 8
        )
        .frame(width: coverWidth)
        .overlay(alignment: .topLeading) {
            CoverCategoryVolumeBadge(
                systemImage: item.listCategory.coverVolumeBadgeIcon,
                vol: nil,
                showsBackdrop: false
            )
        }
    }

    private var metaRow: some View {
        let state = reactions.displayState(for: article)
        let likeBusy = reactions.isBusy(article.id, kind: .like)

        return HStack(spacing: 8) {
            if let date = ArticleFormat.dateOnly(from: item.publishedAt) {
                Text(date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Button {
                Task { await session.unlikeItem(item) }
            } label: {
                MetaIconText.likes(state.likeNumber, active: state.isLiked, isLoading: likeBusy)
                    .font(.caption2)
            }
            .buttonStyle(.plain)
            .disabled(likeBusy)

            Spacer(minLength: 0)
        }
    }
}