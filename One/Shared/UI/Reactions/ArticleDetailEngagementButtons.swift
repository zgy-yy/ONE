import SwiftUI

/// 详情页单颗互动按钮（收藏或喜欢）；与 `ArticleReactionStore` 联动 loading。
struct ArticleDetailEngagementButton: View {
    enum Kind {
        case collect, like

        var reactionKind: ArticleReactionStore.Kind {
            switch self {
            case .collect: .collect
            case .like: .like
            }
        }

        fileprivate var symbol: (off: String, on: String) {
            switch self {
            case .collect: (ArticleDetailSymbol.collect, ArticleDetailSymbol.collectOn)
            case .like: (ArticleDetailSymbol.like, ArticleDetailSymbol.likeOn)
            }
        }
    }

    let kind: Kind
    let article: ArticleSummary
    var detail: ArticleDetail?
    var action: (() -> Void)?

    @Bindable private var reactions = ArticleReactionStore.shared

    private var articleID: Int { article.id }

    private var state: ArticleReactionStore.State {
        if let detail {
            reactions.displayState(for: detail)
        } else {
            reactions.displayState(for: article)
        }
    }

    private var isBusy: Bool {
        reactions.isBusy(articleID, kind: kind.reactionKind)
    }

    var body: some View {
        let active = kind == .collect ? state.hasCollected : state.isLiked
        let count = kind == .collect ? state.collectionNumber : state.likeNumber
        let symbols = kind.symbol

        let label = ArticleDetailIconLabel(
            systemImage: active ? symbols.on : symbols.off,
            text: ArticleFormat.shortCount(count),
            active: active,
            isLoading: isBusy
        )
        .monospacedDigit()

        if let action {
            Button(action: action) { label }
                .buttonStyle(.plain)
                .disabled(isBusy)
        } else {
            label
        }
    }
}

/// 详情页一行：收藏 + 喜欢。
struct ArticleDetailEngagementRow: View {
    let article: ArticleSummary
    var detail: ArticleDetail?
    var spacing: CGFloat = 16
    var interactionDisabled: Bool = false
    var onCollect: () -> Void
    var onLike: () -> Void

    var body: some View {
        HStack(spacing: spacing) {
            ArticleDetailEngagementButton(
                kind: .collect,
                article: article,
                detail: detail,
                action: interactionDisabled ? nil : onCollect
            )
            ArticleDetailEngagementButton(
                kind: .like,
                article: article,
                detail: detail,
                action: interactionDisabled ? nil : onLike
            )
        }
    }
}