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

    private var loadedActorID: Int?
    private static var detailCache: [Int: ActorDetail] = [:]

    func load(actorID: Int) async {
        if loadedActorID != actorID {
            articles.reset()
            photos.reset()
            comments.reset()
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

        guard let creds = OneCredentials.pair(tokenPath: OneAPI.actorDetailPath) else {
            error = OneCredentials.readinessError
            return
        }

        do {
            let detail = try await OneClient.actorDetail(
                base: creds.base,
                token: creds.token,
                actorID: actorID
            )
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
            await applyFirstPage(to: \.articles) {
                try await Self.fetchArticles(actorID: actorID, page: 1, size: 30)
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
            await applyMorePage(to: \.articles) {
                try await Self.fetchArticles(actorID: actorID, page: page, size: 30)
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
            state.failLoad(error.localizedDescription)
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

    private static func fetchArticles(actorID: Int, page: Int, size: Int) async throws -> [ArticleSummary] {
        let creds = try requireCreds(OneAPI.actorArticlesPath)
        return try await OneClient.actorArticles(
            base: creds.base, token: creds.token, actorID: actorID, page: page, size: size
        )
    }

    private static func fetchPhotos(actorID: Int, page: Int, size: Int) async throws -> [ActorPhoto] {
        let creds = try requireCreds(OneAPI.actorPhotosPath)
        return try await OneClient.actorPhotos(
            base: creds.base, token: creds.token, actorID: actorID, page: page, size: size
        )
    }

    private static func fetchComments(actorID: Int, page: Int, size: Int) async throws -> [CommentItem] {
        let creds = try requireCreds(OneAPI.commentListPath)
        return try await OneClient.commentList(
            base: creds.base, token: creds.token, targetID: actorID, type: 2, page: page, size: size
        )
    }

    private static func requireCreds(_ path: String) throws -> (base: URL, token: String) {
        guard let creds = OneCredentials.pair(tokenPath: path) else {
            throw OneClientError.apiRejected(OneCredentials.readinessError)
        }
        return creds
    }
}
