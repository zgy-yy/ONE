import Foundation
import Observation

/// 搜索：热词 + 关键词 + 分类分页。
@MainActor
@Observable
final class SearchSession {
    static let shared = SearchSession()

    var category: ContentCategory = .all {
        didSet {
            guard oldValue != category else { return }
            results.reset()
            if !committedKeyword.isEmpty {
                Task { await load(force: true) }
            }
        }
    }

    /// 输入框文案。
    var draftKeyword = ""
    /// 已提交搜索的关键词。
    private(set) var committedKeyword = ""
    private(set) var results = PagedListState<SearchHit>(pageSize: 20)
    private(set) var hotWords: [SearchHotWord] = []
    private(set) var isLoadingHotWords = false
    private(set) var hotWordsError: String?

    private init() {}

    func loadHotWordsIfNeeded() async {
        if !hotWords.isEmpty || isLoadingHotWords { return }
        await loadHotWords(force: false)
    }

    func loadHotWords(force: Bool = false) async {
        if !force, !hotWords.isEmpty { return }
        guard !isLoadingHotWords else { return }
        isLoadingHotWords = true
        hotWordsError = nil
        defer { isLoadingHotWords = false }

        do {
            hotWords = try await OneClient.articleHotWords()
        } catch {
            hotWordsError = error.localizedDescription
        }
    }

    func search(keyword: String) {
        draftKeyword = keyword
        submit()
    }

    /// 从详情标签等入口：关键词 + 分类一次到位，避免 `category` `didSet` 用旧词多请求一次。
    func openSearch(keyword: String, category: ContentCategory) {
        let text = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draftKeyword = text
        committedKeyword = text
        if self.category != category {
            self.category = category
        } else {
            results.reset()
            Task { await load(force: true) }
        }
    }

    func submit() {
        let keyword = draftKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        committedKeyword = keyword
        results.reset()
        guard !keyword.isEmpty else { return }
        Task { await load(force: true) }
    }

    func clearResults() {
        draftKeyword = ""
        committedKeyword = ""
        results.reset()
    }

    func load(force: Bool = false) async {
        let keyword = committedKeyword
        guard !keyword.isEmpty else {
            results.reset()
            return
        }

        var feed = results
        guard feed.beginLoad(force: force) else {
            results = feed
            return
        }
        results = feed

        do {
            let list = try await fetch(keyword: keyword, page: 1)
            feed.finishLoad(list)
            results = feed
        } catch {
            feed.failLoad(error)
            results = feed
        }
    }

    func loadMore() async {
        let keyword = committedKeyword
        guard !keyword.isEmpty else { return }

        var feed = results
        guard let page = feed.beginLoadMore() else {
            results = feed
            return
        }
        results = feed

        do {
            let list = try await fetch(keyword: keyword, page: page)
            feed.finishLoadMore(list)
            results = feed
        } catch {
            feed.cancelLoadMore()
            results = feed
        }
    }

    private func fetch(keyword: String, page: Int) async throws -> [SearchHit] {
        try await OneClient.articleSearch(
            keyword: keyword,
            modelID: category.modelID,
            seriesCategory: category.seriesCategory,
            page: page,
            size: results.pageSize
        )
    }
}
