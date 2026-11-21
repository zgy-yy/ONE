import Foundation
import Observation

/// 文章喜欢 / 收藏的跨页状态（列表 Row 与详情共用）。
///
/// 用法：
/// ```swift
/// let state = ArticleReactionStore.shared.displayState(for: article)
/// await ArticleReactionStore.shared.toggle(.like, articleID: id, seed: .init(article))
/// ```
@MainActor
@Observable
final class ArticleReactionStore {
    static let shared = ArticleReactionStore()

    enum Kind { case like, collect }

    struct State: Hashable {
        var isLiked: Bool
        var hasCollected: Bool
        var likeNumber: Int
        var collectionNumber: Int

        init(
            isLiked: Bool = false,
            hasCollected: Bool = false,
            likeNumber: Int = 0,
            collectionNumber: Int = 0
        ) {
            self.isLiked = isLiked
            self.hasCollected = hasCollected
            self.likeNumber = likeNumber
            self.collectionNumber = collectionNumber
        }

        init(_ article: ArticleSummary) {
            self.init(
                isLiked: article.isLiked,
                hasCollected: article.hasCollected,
                likeNumber: article.likeNumber ?? 0,
                collectionNumber: article.collectionNumber ?? 0
            )
        }

        init(_ detail: ArticleDetail) {
            self.init(
                isLiked: detail.isLiked,
                hasCollected: detail.hasCollected,
                likeNumber: detail.likeNumber ?? 0,
                collectionNumber: detail.collectionNumber ?? 0
            )
        }
    }

    private(set) var states: [Int: State] = [:]
    private var busyIDs: Set<Int> = []

    private init() {}

    func isBusy(_ articleID: Int) -> Bool {
        busyIDs.contains(articleID)
    }

    /// 有缓存用缓存，否则用列表/详情底稿。
    func displayState(for article: ArticleSummary) -> State {
        states[article.id] ?? State(article)
    }

    /// 详情拉取后写入（若缓存已有乐观更新则先盖回详情再统一写缓存）。
    func merge(into detail: inout ArticleDetail) {
        if let cached = states[detail.id] {
            detail.isLike = cached.isLiked ? 1 : 0
            detail.isCollected = cached.hasCollected ? 1 : 0
            detail.likeNumber = cached.likeNumber
            detail.collectionNumber = cached.collectionNumber
        }
        states[detail.id] = State(detail)
    }

    /// 把缓存盖回详情（切换成功后刷新 UI）。
    func apply(to detail: inout ArticleDetail) {
        guard let state = states[detail.id] else { return }
        detail.isLike = state.isLiked ? 1 : 0
        detail.isCollected = state.hasCollected ? 1 : 0
        detail.likeNumber = state.likeNumber
        detail.collectionNumber = state.collectionNumber
    }

    func toggle(_ kind: Kind, articleID: Int, seed: State) async {
        if states[articleID] == nil {
            states[articleID] = seed
        }
        guard !busyIDs.contains(articleID), var state = states[articleID] else { return }
        busyIDs.insert(articleID)
        defer { busyIDs.remove(articleID) }

        do {
            switch kind {
            case .like:
                try await OneClient.articleLike(articleID: articleID)
                state.isLiked.toggle()
                state.likeNumber = max(0, state.likeNumber + (state.isLiked ? 1 : -1))
            case .collect:
                try await OneClient.articleCollect(articleID: articleID)
                state.hasCollected.toggle()
                state.collectionNumber = max(0, state.collectionNumber + (state.hasCollected ? 1 : -1))
            }
            states[articleID] = state
        } catch {
            print("[ArticleReaction] \(kind) failed id=\(articleID): \(error.localizedDescription)")
        }
    }

    /// 收藏并移入指定夹：未收藏时先 `article/collect`，再 `moveToCollectFolder`。
    func collectToFolder(articleID: Int, folderID: Int, seed: State) async throws {
        if states[articleID] == nil {
            states[articleID] = seed
        }
        guard !busyIDs.contains(articleID), var state = states[articleID] else { return }
        busyIDs.insert(articleID)
        defer { busyIDs.remove(articleID) }

        if !state.hasCollected {
            try await OneClient.articleCollect(articleID: articleID)
        }
        try await OneClient.moveToCollectFolder(articleIDs: [articleID], folderID: folderID)

        if !state.hasCollected {
            state.hasCollected = true
            state.collectionNumber = max(0, state.collectionNumber + 1)
        }
        states[articleID] = state
    }
}
