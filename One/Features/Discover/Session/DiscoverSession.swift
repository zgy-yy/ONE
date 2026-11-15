import Foundation
import Observation

/// 发现页：按频道（`model_id`）+ 发布年月 + 排序分页拉取。
@MainActor
@Observable
final class DiscoverSession {
    static let shared = DiscoverSession()

    private(set) var loading: Set<Int> = []
    private(set) var loadingMore: Set<Int> = []

    var listPublishedAt: String = MonthYear.now.apiString {
        didSet {
            guard oldValue != listPublishedAt else { return }
            feeds = [:]
        }
    }

    var listSort: VodArticleSort = .publishedAt {
        didSet {
            guard oldValue != listSort else { return }
            feeds = [:]
        }
    }

    var feedFetchKey: String {
        "\(listPublishedAt)-\(listSort.rawValue)"
    }

    private var feeds: [Int: Feed] = [:]
    private let pageSize = 20

    private struct Feed {
        var articles: [ArticleSummary] = []
        var nextPage = 1
        var loaded = false
        var exhausted = false
        var error: String?
    }

    private init() {}

    func articles(for channel: DiscoverChannel) -> [ArticleSummary] {
        feeds[channel.rawValue]?.articles ?? []
    }

    func error(for channel: DiscoverChannel) -> String? {
        feeds[channel.rawValue]?.error
    }

    func isLoading(_ channel: DiscoverChannel) -> Bool {
        loading.contains(channel.rawValue)
    }

    func isLoadingMore(_ channel: DiscoverChannel) -> Bool {
        loadingMore.contains(channel.rawValue)
    }

    func showsEndFooter(_ channel: DiscoverChannel) -> Bool {
        guard let feed = feeds[channel.rawValue], feed.loaded else { return false }
        return feed.exhausted
    }

    func load(channel: DiscoverChannel, force: Bool = false) async {
        let key = channel.rawValue
        if force { feeds[key] = nil }
        guard !loading.contains(key), feeds[key]?.loaded != true else { return }

        loading.insert(key)
        defer { loading.remove(key) }

        feeds[key] = Feed()
        await fetchPage(channel: channel, page: 1, append: false)
    }

    func loadMore(channel: DiscoverChannel) async {
        let key = channel.rawValue
        guard let feed = feeds[key], feed.loaded, !feed.exhausted else { return }
        guard !loading.contains(key), !loadingMore.contains(key) else { return }

        loadingMore.insert(key)
        defer { loadingMore.remove(key) }
        await fetchPage(channel: channel, page: feed.nextPage, append: true)
    }

    private func fetchPage(channel: DiscoverChannel, page: Int, append: Bool) async {
        let key = channel.rawValue
        guard let creds = OneCredentials.pair(tokenPath: OneAPI.discoveryPath) else {
            if !append {
                var feed = feeds[key] ?? Feed()
                feed.error = OneCredentials.readinessError
                feeds[key] = feed
            }
            return
        }

        let request = DiscoveryRequest.discoverList(
            modelID: channel.rawValue,
            publishedAt: listPublishedAt,
            sort: listSort.rawValue,
            page: page,
            size: pageSize
        )

        do {
            let list = try await OneClient.articleDiscovery(
                base: creds.base,
                token: creds.token,
                request: request
            )
            var feed = feeds[key] ?? Feed()
            feed.error = nil
            feed.loaded = true
            if append {
                let existing = Set(feed.articles.map(\.id))
                feed.articles.append(contentsOf: list.filter { !existing.contains($0.id) })
            } else {
                feed.articles = list
            }
            feed.nextPage = page + 1
            feed.exhausted = list.count < pageSize
            feeds[key] = feed
        } catch {
            if !append {
                var feed = feeds[key] ?? Feed()
                feed.error = error.localizedDescription
                feeds[key] = feed
            }
        }
    }
}
