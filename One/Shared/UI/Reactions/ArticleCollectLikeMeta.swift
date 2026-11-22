import SwiftUI

/// 列表 / 卡片：收藏 + 喜欢（与详情的 `ArticleDetailEngagementRow` 成对）。
struct ArticleCollectLikeMeta: View {
    let article: ArticleSummary
    var onDarkOverlay = false
    /// 收藏与喜欢之间的间距；窄卡片可改小避免挤换行。
    var itemSpacing: CGFloat = 12
    /// 用户取消收藏后回调（如从收藏夹列表移除该项）。
    var onUncollect: ((Int) -> Void)? = nil

    @Bindable private var reactions = ArticleReactionStore.shared

    @State private var collectMoveContext: CollectFolderMoveContext?

    var body: some View {
        let state = reactions.displayState(for: article)
        let collectBusy = reactions.isBusy(article.id, kind: .collect)
        let likeBusy = reactions.isBusy(article.id, kind: .like)
        let seed = ArticleReactionStore.State(article)

        HStack(spacing: itemSpacing) {
            Button {
                Task {
                    let hadCollected = state.hasCollected
                    collectMoveContext = await ArticleCollectAction.handle(article: article)
                    if hadCollected, !reactions.displayState(for: article).hasCollected {
                        onUncollect?(article.id)
                    }
                }
            } label: {
                MetaIconText.collect(
                    count: state.collectionNumber,
                    active: state.hasCollected,
                    isLoading: collectBusy,
                    onDarkOverlay: onDarkOverlay
                )
            }
            .buttonStyle(.plain)
            .disabled(collectBusy)

            Button {
                Task { await reactions.toggle(.like, articleID: article.id, seed: seed) }
            } label: {
                MetaIconText.likes(
                    state.likeNumber,
                    active: state.isLiked,
                    isLoading: likeBusy,
                    onDarkOverlay: onDarkOverlay
                )
            }
            .buttonStyle(.plain)
            .disabled(likeBusy)
        }
        .fixedSize(horizontal: true, vertical: false)
        .articleCollectMoveFlow($collectMoveContext)
    }
}