import Foundation

/// 某个月份下已加载的文章分页状态。
struct ArticleMonthSection: Identifiable, Equatable {
    let month: String
    var articles: [ArticleSummary]
    var nextPage: Int
    var monthExhausted: Bool

    var id: String { month }
}

/// 按月串联分页的下一页请求。
struct MonthPageRequest: Equatable {
    let month: String
    let page: Int
    let newSection: Bool
}

/// 按月文章列表状态：从锚定月份向下串联更早月份。
struct MonthArticlesState {
    var sections: [ArticleMonthSection] = []
    var error: String?
    var loaded = false
    var fullyExhausted = false

    var flatItems: [ArticleSummary] {
        sections.flatMap(\.articles)
    }

    var canLoadMore: Bool {
        guard loaded, !fullyExhausted, let tail = sections.last else { return false }
        if !tail.monthExhausted { return true }
        return MonthYear(apiString: tail.month)?.previous != nil
    }

    /// 当前月耗尽后的下一请求（同月下一页，或更早月份第 1 页）。
    var nextPageRequest: MonthPageRequest? {
        guard let tail = sections.last else { return nil }
        if !tail.monthExhausted {
            return MonthPageRequest(month: tail.month, page: tail.nextPage, newSection: false)
        }
        guard let month = MonthYear(apiString: tail.month)?.previous else { return nil }
        return MonthPageRequest(month: month.apiString, page: 1, newSection: true)
    }

    /// 锚定月无数据且已耗尽时，应继续拉更早月份。
    var shouldAdvancePastEmptyTail: Bool {
        guard canLoadMore, let tail = sections.last else { return false }
        return tail.monthExhausted && tail.articles.isEmpty
    }

    mutating func reset() {
        sections = []
        error = nil
        loaded = false
        fullyExhausted = false
    }

    mutating func recordError(_ message: String) {
        error = message
        loaded = false
    }

    /// 已到最早可请求月份且该月耗尽时标记全局结束。
    mutating func markFullyExhaustedIfNeeded() {
        guard let tail = sections.last,
              tail.monthExhausted,
              MonthYear(apiString: tail.month)?.previous == nil
        else { return }
        fullyExhausted = true
    }

    mutating func mergePage(
        month: String,
        list: [ArticleSummary],
        page: Int,
        pageSize: Int,
        newSection: Bool
    ) {
        error = nil
        loaded = true

        if newSection {
            let items = unique(list, except: flatItems)
            // 不足一页，或去重后无新数据 → 该月耗尽。
            let exhausted = list.count < pageSize || items.isEmpty
            appendSection(month: month, items: items, page: page, exhausted: exhausted)
            return
        }

        guard let index = sections.firstIndex(where: { $0.month == month }) else {
            mergePage(month: month, list: list, page: page, pageSize: pageSize, newSection: true)
            return
        }

        let existing = sections[index].articles
        let items = unique(list, except: existing)
        sections[index].articles.append(contentsOf: items)
        sections[index].nextPage = page + 1
        sections[index].monthExhausted = list.count < pageSize || items.isEmpty
    }

    private mutating func appendSection(
        month: String,
        items: [ArticleSummary],
        page: Int,
        exhausted: Bool
    ) {
        sections.append(
            ArticleMonthSection(
                month: month,
                articles: items,
                nextPage: page + 1,
                monthExhausted: exhausted
            )
        )
    }

    private func unique(_ list: [ArticleSummary], except existing: [ArticleSummary]) -> [ArticleSummary] {
        let seen = Set(existing.map(\.id))
        return list.filter { !seen.contains($0.id) }
    }
}
