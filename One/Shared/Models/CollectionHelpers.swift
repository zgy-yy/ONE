import Foundation

// MARK: - 分块

extension Array {
    /// 按固定长度切成若干段（末段可不足）。
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0, !isEmpty else { return [] }
        var result: [[Element]] = []
        result.reserveCapacity((count + size - 1) / size)
        var index = startIndex
        while index < endIndex {
            let next = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            result.append(Array(self[index..<next]))
            index = next
        }
        return result
    }
}

extension Array where Element == ArticleSummary {
    /// 两列网格行的稳定 `ForEach` id（取行内首篇 id）。
    var rowID: Int { first?.id ?? 0 }
}

// MARK: - 触底加载

extension RandomAccessCollection where Element: Identifiable {
    /// 是否为集合末项（用于 `onAppear` 触发加载更多）。
    func isLastItem(_ element: Element) -> Bool {
        last?.id == element.id
    }
}

extension Array where Element == ArticleMonthSection {
    /// 是否为「最后一个月份分区」的最后一篇文章。
    func isTailArticle(_ article: ArticleSummary, in section: ArticleMonthSection) -> Bool {
        guard let tail = last, tail.month == section.month else { return false }
        return tail.articles.last?.id == article.id
    }
}
