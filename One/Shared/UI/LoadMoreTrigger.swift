import Foundation

// MARK: - 列表「滑到底」触发加载更多

extension RandomAccessCollection where Element: Identifiable {
    /// 是否为集合末项（用于 `onAppear` 触发加载更多）。
    ///
    /// 例：`guard items.isLastItem(item) else { return }`
    func isLastItem(_ element: Element) -> Bool {
        last?.id == element.id
    }
}

extension Array where Element == ArticleMonthSection {
    /// 是否为「最后一个月份分区」的最后一篇文章。
    ///
    /// 点播 / 首页按月列表共用，避免各页手写尾项判断。
    func isTailArticle(_ article: ArticleSummary, in section: ArticleMonthSection) -> Bool {
        guard let tail = last, tail.month == section.month else { return false }
        return tail.articles.last?.id == article.id
    }
}
