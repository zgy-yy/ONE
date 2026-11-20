import Foundation

/// 通用分页列表状态（首屏 / 加载更多 / 错误 / 到底）。
struct PagedListState<Item: Identifiable> where Item.ID: Hashable {
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var error: String?
    private(set) var exhausted = false
    private(set) var loaded = false
    private(set) var nextPage = 1

    let pageSize: Int

    init(pageSize: Int) {
        self.pageSize = pageSize
    }

    /// 当前是否没有任何条目（首屏空态判断用）。
    var isEmpty: Bool { items.isEmpty }

    /// 清空列表并重置分页游标（换筛选条件时调用）。
    mutating func reset() {
        items = []
        isLoading = false
        isLoadingMore = false
        error = nil
        exhausted = false
        loaded = false
        nextPage = 1
    }

    /// 开始首屏加载；返回 `false` 表示应跳过。
    ///
    /// `force` 且已有数据时保留 `items`，避免卸掉 List 导致下拉刷新请求被取消。
    mutating func beginLoad(force: Bool) -> Bool {
        if force {
            guard !isLoading, !isLoadingMore else { return false }
            nextPage = 1
            exhausted = false
            loaded = false
            isLoading = true
            error = nil
            return true
        }
        guard !isLoading, !loaded else { return false }
        isLoading = true
        error = nil
        return true
    }

    /// 首屏成功：写入本页数据，并决定是否还有下一页。
    mutating func finishLoad(_ list: [Item], hasMore: Bool? = nil) {
        items = list
        nextPage = 2
        // 有接口明确返回 hasMore 时优先用它；否则按本页条数判断。
        exhausted = hasMore.map { !$0 } ?? (list.count < pageSize)
        loaded = true
        isLoading = false
    }

    /// 首屏失败：保存错误文案，结束 loading。已有列表时忽略取消。
    mutating func failLoad(_ error: Error) {
        isLoading = false
        if error.isRequestCancellation, !items.isEmpty { return }
        self.error = error.localizedDescription
    }

    /// 开始加载更多；返回当前页码，`nil` 表示应跳过。
    mutating func beginLoadMore() -> Int? {
        guard loaded, !exhausted else { return nil }
        guard !isLoading, !isLoadingMore else { return nil }
        isLoadingMore = true
        return nextPage
    }

    /// 加载更多成功：去重追加，并推进页码。
    mutating func finishLoadMore(_ list: [Item], hasMore: Bool? = nil) {
        let existing = Set(items.map(\.id))
        items.append(contentsOf: list.filter { !existing.contains($0.id) })
        nextPage += 1
        exhausted = hasMore.map { !$0 } ?? (list.count < pageSize)
        isLoadingMore = false
    }

    /// 加载更多失败：仅结束 loadingMore，保留已有列表。
    mutating func cancelLoadMore() {
        isLoadingMore = false
    }
}
