import Foundation
import Observation

/// 搜索：热词 + 关键词 + 分类分页。
@MainActor
@Observable
final class SearchSession {
    static let shared = SearchSession()

    var category: SearchCategory = .all {
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

        guard let creds = OneCredentials.pair(tokenPath: OneAPI.articleHotWordsPath) else {
            hotWordsError = OneCredentials.readinessError
            return
        }

        do {
            hotWords = try await OneClient.articleHotWords(base: creds.base, token: creds.token)
        } catch {
            hotWordsError = error.localizedDescription
        }
    }

    func search(keyword: String) {
        draftKeyword = keyword
        submit()
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
            feed.failLoad(error.localizedDescription)
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
        guard let creds = OneCredentials.pair(tokenPath: OneAPI.articleSearchPath) else {
            throw OneClientError.apiRejected(OneCredentials.readinessError)
        }
        return try await OneClient.articleSearch(
            base: creds.base,
            token: creds.token,
            keyword: keyword,
            modelID: category.modelID,
            seriesCategory: category.seriesCategory,
            page: page,
            size: results.pageSize
        )
    }
}
