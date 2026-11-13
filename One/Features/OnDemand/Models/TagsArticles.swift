import Foundation

/// 单个分类下的列表缓存（分页 + 错误）。
struct TagsArticles {
    var items: [ArticleSummary] = []
    var error: String?
    var nextPage = 2
    var hasMore = true
    var loaded = false

    mutating func recordError(_ message: String) {
        error = message
        loaded = false
    }

    mutating func mergePage(_ list: [ArticleSummary], page: Int, pageSize: Int, append: Bool) {
        error = nil
        loaded = true
        hasMore = list.count >= pageSize
        nextPage = page + 1
        if append {
            let seen = Set(items.map(\.id))
            items.append(contentsOf: list.filter { !seen.contains($0.id) })
        } else {
            items = list
        }
    }
}
