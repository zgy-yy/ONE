import Foundation

/// 某个月份下已加载的文章分页状态。
struct ArticleMonthSection: Identifiable, Equatable {
    let month: String
    var articles: [ArticleSummary]
    var nextPage: Int
    var monthExhausted: Bool

    var id: String { month }
}

/// 单个分类：从锚定月份向下串联更早月份。
struct TagsArticles {
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

    mutating func mergePage(
        month: String,
        list: [ArticleSummary],
        page: Int,
        pageSize: Int,
        newSection: Bool
    ) {
        error = nil
        loaded = true
        let exhausted = list.count < pageSize

        if newSection {
            appendSection(month: month, items: unique(list, except: flatItems), page: page, exhausted: exhausted)
            return
        }

        guard let index = sections.firstIndex(where: { $0.month == month }) else {
            mergePage(month: month, list: list, page: page, pageSize: pageSize, newSection: true)
            return
        }

        let existing = sections[index].articles
        sections[index].articles.append(contentsOf: unique(list, except: existing))
        sections[index].nextPage = page + 1
        sections[index].monthExhausted = exhausted
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
