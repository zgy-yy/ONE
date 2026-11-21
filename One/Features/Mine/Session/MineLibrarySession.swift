import Foundation
import Observation

/// 我的喜欢 / 收藏数据（`MineLibrarySession.shared`）。
@MainActor
@Observable
final class MineLibrarySession {
    static let shared = MineLibrarySession()

    // MARK: - 筛选

    var likeCategory: ContentCategory = .all {
        didSet {
            guard oldValue != likeCategory else { return }
            likes.reset()
        }
    }

    var folderSort = CollectFolderSort() {
        didSet {
            guard oldValue != folderSort else { return }
            folders = []
        }
    }

    /// 当前打开的收藏夹（`my/favorites` 的 `user_collect_folder_id`）。
    private(set) var selectedFolderID: Int = 0

    // MARK: - 状态

    private(set) var likes = PagedListState<UserLikeItem>(pageSize: 50)
    private(set) var favorites = PagedListState<FavoriteItem>(pageSize: 20)
    private(set) var folders: [CollectFolder] = []
    private(set) var isLoadingFolders = false
    private(set) var foldersError: String?

    private init() {}

    func reset() {
        likeCategory = .all
        folderSort = CollectFolderSort()
        selectedFolderID = 0
        likes.reset()
        favorites.reset()
        folders = []
        foldersError = nil
    }

    // MARK: - 喜欢

    func loadLikes(force: Bool = false) async {
        var feed = likes
        guard feed.beginLoad(force: force) else {
            likes = feed
            return
        }
        likes = feed

        do {
            let payload = try await OneClient.userLikeList(
                modelID: likeCategory.modelID,
                seriesCategory: likeCategory.seriesCategory
            )
            feed.finishLoad(payload.items, hasMore: payload.hasMore)
            likes = feed
        } catch {
            feed.failLoad(error)
            likes = feed
        }
    }

    func unlikeItem(_ item: UserLikeItem) async {
        let summary = item.asArticleSummary
        let seed = ArticleReactionStore.State(summary)
        await ArticleReactionStore.shared.toggle(.like, articleID: summary.id, seed: seed)
        guard !ArticleReactionStore.shared.displayState(for: summary).isLiked else { return }
        var feed = likes
        feed.removeAll { $0.id == item.id }
        likes = feed
    }

    // MARK: - 收藏夹列表

    var defaultCollectFolder: CollectFolder? {
        folders.first(where: \.isDefault) ?? folders.first(where: { $0.id == 0 }) ?? folders.first
    }

    var defaultCollectFolderID: Int { defaultCollectFolder?.id ?? 0 }

    var defaultCollectFolderName: String { defaultCollectFolder?.displayName ?? "默认收藏夹" }

    func loadFolders(force: Bool = false) async {
        if !force, !folders.isEmpty { return }
        guard !isLoadingFolders else { return }
        isLoadingFolders = true
        foldersError = nil
        defer { isLoadingFolders = false }

        do {
            folders = try await OneClient.collectFolderList(
                sortDim: folderSort.dimension.rawValue,
                sortDesc: folderSort.sortDesc
            )
        } catch {
            foldersError = error.localizedDescription
        }
    }

    func createCollectFolder(name: String) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw OneClientError.apiRejected("请输入收藏夹名称")
        }
        try await OneClient.createCollectFolder(folderName: trimmed)
        await loadFolders(force: true)
    }

    // MARK: - 夹内收藏

    /// 切换收藏夹时绑定 `folderID` 并清空缓存；同一夹重复进入（如从详情返回）不重置。
    func enterFolder(id: Int) {
        guard selectedFolderID != id else { return }
        selectedFolderID = id
        favorites.reset()
    }

    /// 取消收藏后从当前夹内列表移除（不整页刷新）。
    func removeFavorite(articleID: Int) {
        var feed = favorites
        feed.removeAll { $0.id == articleID }
        favorites = feed
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

    private func fetchFavorites(page: Int) async throws -> FavoritesPayload {
        try await OneClient.favorites(
            modelID: ContentCategory.all.modelID,
            seriesCategory: ContentCategory.all.seriesCategory,
            page: page,
            size: favorites.pageSize,
            folderID: selectedFolderID
        )
    }
}