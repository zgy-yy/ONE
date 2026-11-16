import Foundation
import Observation

/// 演员页：最新 / 最热 / 主分类列表。
@MainActor
@Observable
final class ActorSession {
    static let shared = ActorSession()

    private(set) var navigations: [ActorNavigation] = []
    private(set) var isLoading = false
    private(set) var lastError: String?

    /// 各分类已选标签（多选 → `tag_ids`）。
    private(set) var selectedTagIDs: [Int: Set<Int>] = [:]

    private var feeds: [String: PagedListState<ActorSummary>] = [:]
    private let navigationPageSize = 30
    private let spotlightPageSize = 9

    private init() {}

    // MARK: - 分类

    func loadIfNeeded() async {
        guard navigations.isEmpty, !isLoading else { return }
        await refresh()
    }

    func refresh(force: Bool = false) async {
        if !force, !navigations.isEmpty { return }

        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            navigations = try await OneClient.actorMainNavigations()
            if force {
                feeds = [:]
                selectedTagIDs = [:]
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - 标签

    func selectedTags(for navigationID: Int) -> Set<Int> {
        selectedTagIDs[navigationID] ?? []
    }

    func isTagSelected(navigationID: Int, tagID: Int) -> Bool {
        selectedTags(for: navigationID).contains(tagID)
    }

    func toggleTag(navigationID: Int, tagID: Int) {
        var set = selectedTagIDs[navigationID] ?? []
        if set.contains(tagID) { set.remove(tagID) } else { set.insert(tagID) }
        selectedTagIDs[navigationID] = set
    }

    func feedFetchKey(for selection: ActorTabSelection) -> String {
        feedKey(for: selection)
    }

    // MARK: - 列表

    func actors(for selection: ActorTabSelection) -> [ActorSummary] {
        feeds[feedKey(for: selection)]?.items ?? []
    }

    func error(for selection: ActorTabSelection) -> String? {
        feeds[feedKey(for: selection)]?.error
    }

    func isLoadingActors(_ selection: ActorTabSelection) -> Bool {
        feeds[feedKey(for: selection)]?.isLoading == true
    }

    func isLoadingMoreActors(_ selection: ActorTabSelection) -> Bool {
        feeds[feedKey(for: selection)]?.isLoadingMore == true
    }

    func showsEndFooter(_ selection: ActorTabSelection) -> Bool {
        guard let feed = feeds[feedKey(for: selection)], feed.loaded else { return false }
        return feed.exhausted
    }

    func loadActors(selection: ActorTabSelection, force: Bool = false) async {
        let key = feedKey(for: selection)
        var feed = feeds[key] ?? PagedListState(pageSize: pageSize(for: selection))
        guard feed.beginLoad(force: force) else {
            feeds[key] = feed
            return
        }
        feeds[key] = feed
        await fetchPage(selection: selection, page: 1, append: false)
    }

    func loadMoreActors(selection: ActorTabSelection) async {
        let key = feedKey(for: selection)
        guard var feed = feeds[key], let page = feed.beginLoadMore() else { return }
        feeds[key] = feed
        await fetchPage(selection: selection, page: page, append: true)
    }

    // MARK: - Private

    private func sortedTagIDs(for navigationID: Int) -> [Int] {
        selectedTags(for: navigationID).sorted()
    }

    private func feedKey(for selection: ActorTabSelection) -> String {
        switch selection {
        case .newest: return "newest"
        case .hottest: return "hottest"
        case .navigation(let id):
            let tags = sortedTagIDs(for: id).map(String.init).joined(separator: ",")
            return "nav:\(id)|\(tags)"
        }
    }

    private func pageSize(for selection: ActorTabSelection) -> Int {
        switch selection {
        case .newest, .hottest: return spotlightPageSize
        case .navigation: return navigationPageSize
        }
    }

    private func fetchPage(selection: ActorTabSelection, page: Int, append: Bool) async {
        let key = feedKey(for: selection)
        var feed = feeds[key] ?? PagedListState(pageSize: pageSize(for: selection))

        do {
            let list = try await fetchList(selection: selection, page: page)
            if append { feed.finishLoadMore(list) } else { feed.finishLoad(list) }
            feeds[key] = feed
        } catch {
            if append { feed.cancelLoadMore() } else { feed.failLoad(error.localizedDescription) }
            feeds[key] = feed
        }
    }

    private func fetchList(
        selection: ActorTabSelection,
        page: Int
    ) async throws -> [ActorSummary] {
        switch selection {
        case .newest:
            try await OneClient.actorNewActors(page: page, size: spotlightPageSize).list ?? []
        case .hottest:
            try await OneClient.actorHotActors(page: page, size: spotlightPageSize)
        case .navigation(let id):
            try await OneClient.actorMainNavigationActors(
                mainNavigationID: id,
                page: page,
                size: navigationPageSize,
                tagIDs: sortedTagIDs(for: id)
            )
        }
    }
}
