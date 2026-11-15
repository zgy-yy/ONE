import Foundation
import Observation

/// 某一天的首页缓存。
struct HomeDayCache {
    var articles: [ArticleSummary] = []
    var topText: String?
    var isLoading = false
    var error: String?
    var loaded = false
}

/// 首页：按日缓存 `article/day`，支持左右翻页。
@MainActor
@Observable
final class HomeSession {
    static let shared = HomeSession()

    /// 可滑动的日期窗口（约三个月）。
    let days: [DayDate] = DayDate.range(daysAgo: 90)

    var selectedDay: DayDate = .today

    private var caches: [String: HomeDayCache] = [:]

    private init() {}

    func cache(for day: DayDate) -> HomeDayCache {
        caches[day.apiString] ?? HomeDayCache()
    }

    func load(_ day: DayDate, force: Bool = false) async {
        var cache = caches[day.apiString] ?? HomeDayCache()
        if !force, cache.loaded { return }
        guard !cache.isLoading else { return }

        cache.isLoading = true
        cache.error = nil
        caches[day.apiString] = cache

        guard let creds = OneCredentials.pair(tokenPath: OneAPI.articleDayPath) else {
            cache.isLoading = false
            cache.error = OneCredentials.readinessError
            caches[day.apiString] = cache
            return
        }

        do {
            let payload = try await OneClient.articleDay(
                base: creds.base,
                token: creds.token,
                publishedAt: day.apiString
            )
            cache.articles = payload.articles
            cache.topText = payload.topText
            cache.loaded = true
            cache.isLoading = false
            caches[day.apiString] = cache
        } catch {
            cache.isLoading = false
            cache.error = error.localizedDescription
            caches[day.apiString] = cache
        }
    }
}
