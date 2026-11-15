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

    var isEmpty: Bool { items.isEmpty }

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
    mutating func beginLoad(force: Bool) -> Bool {
        if force {
            loaded = false
            items = []
            nextPage = 1
            exhausted = false
        }
        guard !isLoading, !loaded else { return false }
        isLoading = true
        error = nil
        return true
    }

    mutating func finishLoad(_ list: [Item], hasMore: Bool? = nil) {
        items = list
        nextPage = 2
        // 有接口明确返回 hasMore 时优先用它；否则按本页条数判断。
        exhausted = hasMore.map { !$0 } ?? (list.count < pageSize)
        loaded = true
        isLoading = false
    }

    mutating func failLoad(_ message: String) {
        error = message
        isLoading = false
    }

    /// 开始加载更多；返回当前页码，`nil` 表示应跳过。
    mutating func beginLoadMore() -> Int? {
        guard loaded, !exhausted else { return nil }
        guard !isLoading, !isLoadingMore else { return nil }
        isLoadingMore = true
        return nextPage
    }

    mutating func finishLoadMore(_ list: [Item], hasMore: Bool? = nil) {
        let existing = Set(items.map(\.id))
        items.append(contentsOf: list.filter { !existing.contains($0.id) })
        nextPage += 1
        exhausted = hasMore.map { !$0 } ?? (list.count < pageSize)
        isLoadingMore = false
    }

    mutating func cancelLoadMore() {
        isLoadingMore = false
    }
}
