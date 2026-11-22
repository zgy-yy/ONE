import Foundation
import Observation

/// 演员详情 + 作品 / 写真 / 评论分页。
@MainActor
@Observable
final class ActorDetailSession {
    private(set) var detail: ActorDetail?
    private(set) var isLoading = false
    private(set) var error: String?

    private(set) var articles = PagedListState<ArticleSummary>(pageSize: 30)
    private(set) var photos = PagedListState<ActorPhoto>(pageSize: 30)
    private(set) var comments = PagedListState<CommentItem>(pageSize: 10)

    /// 作品排序（UI：发布时间 / 最受欢迎 → 接口 `published_at` / `like_number`）。
    var articleSort: ArticleSort = .publishedAt {
        didSet {
            guard oldValue != articleSort else { return }
            articles.reset()
        }
    }

    private var loadedActorID: Int?
    private(set) var isCollecting = false
    private static var detailCache: [Int: ActorDetail] = [:]

    /// Preview：注入详情，避免走线路 / 接口。
    func configureForPreview(detail: ActorDetail) {
        loadedActorID = detail.id
        self.detail = detail
        error = nil
        isLoading = false
        articles.reset()
        photos.reset()
        comments.reset()
    }

    func load(actorID: Int) async {
        if loadedActorID != actorID {
            articles.reset()
            photos.reset()
            comments.reset()
            articleSort = .publishedAt
            detail = nil
            loadedActorID = actorID
        }

        if let cached = Self.detailCache[actorID] {
            detail = cached
            error = nil
        } else {
            await loadDetail(actorID: actorID)
        }

        await loadSegment(.articles, actorID: actorID)
    }

    func loadSegment(_ segment: ActorDetailSegment, actorID: Int) async {
        await loadPaged(segment, actorID: actorID, force: false)
    }

    func loadMore(_ segment: ActorDetailSegment, actorID: Int) async {
        await loadMorePaged(segment, actorID: actorID)
    }

    func retry(_ segment: ActorDetailSegment, actorID: Int) async {
        await loadPaged(segment, actorID: actorID, force: true)
    }

    // MARK: - Detail

    private func loadDetail(actorID: Int) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let detail = try await OneClient.actorDetail(actorID: actorID)
            self.detail = detail
            Self.detailCache[actorID] = detail
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Paging

    private func loadPaged(_ segment: ActorDetailSegment, actorID: Int, force: Bool) async {
        switch segment {
        case .articles:
            guard articles.beginLoad(force: force) else { return }
            let sort = articleSort.rawValue
            await applyFirstPage(to: \.articles) {
                try await Self.fetchArticles(actorID: actorID, page: 1, size: 30, sort: sort)
            }
        case .photos:
            guard photos.beginLoad(force: force) else { return }
            await applyFirstPage(to: \.photos) {
                try await Self.fetchPhotos(actorID: actorID, page: 1, size: 30)
            }
        case .comments:
            guard comments.beginLoad(force: force) else { return }
            await applyFirstPage(to: \.comments) {
                try await Self.fetchComments(actorID: actorID, page: 1, size: 10)
            }
        }
    }

    private func loadMorePaged(_ segment: ActorDetailSegment, actorID: Int) async {
        switch segment {
        case .articles:
            guard let page = articles.beginLoadMore() else { return }
            let sort = articleSort.rawValue
            await applyMorePage(to: \.articles) {
                try await Self.fetchArticles(actorID: actorID, page: page, size: 30, sort: sort)
            }
        case .photos:
            guard let page = photos.beginLoadMore() else { return }
            await applyMorePage(to: \.photos) {
                try await Self.fetchPhotos(actorID: actorID, page: page, size: 30)
            }
        case .comments:
            guard let page = comments.beginLoadMore() else { return }
            await applyMorePage(to: \.comments) {
                try await Self.fetchComments(actorID: actorID, page: page, size: 10)
            }
        }
    }

    private func applyFirstPage<Item: Identifiable>(
        to keyPath: ReferenceWritableKeyPath<ActorDetailSession, PagedListState<Item>>,
        fetch: () async throws -> [Item]
    ) async where Item.ID: Hashable {
        do {
            var state = self[keyPath: keyPath]
            state.finishLoad(try await fetch())
            self[keyPath: keyPath] = state
        } catch {
            var state = self[keyPath: keyPath]
            state.failLoad(error)
            self[keyPath: keyPath] = state
        }
    }

    private func applyMorePage<Item: Identifiable>(
        to keyPath: ReferenceWritableKeyPath<ActorDetailSession, PagedListState<Item>>,
        fetch: () async throws -> [Item]
    ) async where Item.ID: Hashable {
        do {
            var state = self[keyPath: keyPath]
            state.finishLoadMore(try await fetch())
            self[keyPath: keyPath] = state
        } catch {
            var state = self[keyPath: keyPath]
            state.cancelLoadMore()
            self[keyPath: keyPath] = state
        }
    }

    private static func fetchArticles(
        actorID: Int,
        page: Int,
        size: Int,
        sort: String
    ) async throws -> [ArticleSummary] {
        try await OneClient.actorArticles(
            actorID: actorID,
            page: page,
            size: size,
            sort: sort
        )
    }

    private static func fetchPhotos(actorID: Int, page: Int, size: Int) async throws -> [ActorPhoto] {
        try await OneClient.actorPhotos(actorID: actorID, page: page, size: size)
    }

    private static func fetchComments(actorID: Int, page: Int, size: Int) async throws -> [CommentItem] {
        try await OneClient.commentList(
            targetID: actorID,
            type: CommentTargetType.actor,
            page: page,
            size: size
        )
    }

    func loadReplies(for comment: CommentItem, sorting: CommentSort = .likes) async -> [CommentItem] {
        await OneClient.commentReplies(parent: comment, sorting: sorting.rawValue)
    }

    /// `actor/collect` 切换收藏，并同步缓存里的 `is_collected`。
    func toggleCollect(actorID: Int) async throws {
        guard !isCollecting else { return }
        isCollecting = true
        defer { isCollecting = false }

        try await OneClient.actorCollect(actorID: actorID)

        guard var current = detail, current.id == actorID else { return }
        let next = current.hasCollected ? 0 : 1
        current.isCollected = next
        detail = current
        Self.detailCache[actorID] = current

        if next == 0 {
            MineLibrarySession.shared.removeFollowedActor(id: actorID)
        } else {
            MineLibrarySession.shared.insertFollowedActor(current.asSummary)
        }
    }
}
