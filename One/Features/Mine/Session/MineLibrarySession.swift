import Foundation
import Observation

/// 我的喜欢 / 收藏数据。
@MainActor
@Observable
final class MineLibrarySession {
    static let shared = MineLibrarySession()

    var likeCategory: ContentCategory = .all {
        didSet {
            guard oldValue != likeCategory else { return }
            likes.reset()
        }
    }

    var favoriteCategory: ContentCategory = .all {
        didSet {
            guard oldValue != favoriteCategory else { return }
            favorites.reset()
        }
    }

    var selectedFolderID: Int = 0 {
        didSet {
            guard oldValue != selectedFolderID else { return }
            favorites.reset()
        }
    }

    private(set) var likes = PagedListState<UserLikeItem>(pageSize: 50)
    private(set) var favorites = PagedListState<FavoriteItem>(pageSize: 20)
    private(set) var folders: [CollectFolder] = []
    private(set) var isLoadingFolders = false
    private(set) var foldersError: String?
    private(set) var recordCounts: MyRecordCounts?

    private init() {}

    /// 退出登录时清空缓存。
    func reset() {
        likeCategory = .all
        favoriteCategory = .all
        selectedFolderID = 0
        likes.reset()
        favorites.reset()
        folders = []
        foldersError = nil
        recordCounts = nil
    }

    // MARK: - Likes

    func loadLikes(force: Bool = false) async {
        var feed = likes
        guard feed.beginLoad(force: force) else {
            likes = feed
            return
        }
        likes = feed

        do {
            let payload = try await fetchLikes()
            feed.finishLoad(payload.items, hasMore: payload.hasMore)
            likes = feed
        } catch {
            feed.failLoad(error)
            likes = feed
        }
    }

    // MARK: - Folders / Favorites

    func loadFolders(force: Bool = false) async {
        if !force, !folders.isEmpty { return }
        guard !isLoadingFolders else { return }
        isLoadingFolders = true
        foldersError = nil
        defer { isLoadingFolders = false }

        do {
            folders = try await OneClient.collectFolderList()
            if !folders.contains(where: { $0.id == selectedFolderID }) {
                selectedFolderID = folders.first?.id ?? 0
            }
        } catch {
            foldersError = error.localizedDescription
        }
    }

    func loadFavorites(force: Bool = false) async {
        var feed = favorites
        guard feed.beginLoad(force: force) else {
            favorites = feed
            return
        }
        favorites = feed

        do {
            let payload = try await fetchFavorites(page: 1)
            feed.finishLoad(payload.items, hasMore: payload.canLoadMore)
            favorites = feed
        } catch {
            feed.failLoad(error)
            favorites = feed
        }
    }

    func loadMoreFavorites() async {
        var feed = favorites
        guard let page = feed.beginLoadMore() else { return }
        favorites = feed

        do {
            let payload = try await fetchFavorites(page: page)
            feed.finishLoadMore(payload.items, hasMore: payload.canLoadMore)
            favorites = feed
        } catch {
            feed.cancelLoadMore()
            favorites = feed
        }
    }

    func loadRecordCounts() async {
        recordCounts = try? await OneClient.myRecordCounts()
    }

    // MARK: - Private

    private func fetchLikes() async throws -> UserLikeListPayload {
        try await OneClient.userLikeList(
            modelID: likeCategory.modelID,
            seriesCategory: likeCategory.seriesCategory
        )
    }

    private func fetchFavorites(page: Int) async throws -> FavoritesPayload {
        try await OneClient.favorites(
            modelID: favoriteCategory.modelID,
            seriesCategory: favoriteCategory.seriesCategory,
            page: page,
            size: favorites.pageSize,
            folderID: selectedFolderID
        )
    }
}
