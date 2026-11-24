import Foundation
import Observation

/// 某一天的首页缓存。
struct HomeDayCache {
    var articles: [ArticleSummary] = []
    var topText: String?
    var error: String?
    var loaded = false
    /// 正在请求 `article/day`（去重 + loading）。
    var isLoading = false
}

/// 首页：按日缓存 `article/day`，支持左右翻页。
@MainActor
@Observable
final class HomeSession {
    static let shared = HomeSession()

    /// 可滑动的日期窗口（约三个月，旧→新；最右为今天）。
    let days: [DayDate] = DayDate.range(daysAgo: 90)

    var selectedDay: DayDate = .today

    private var caches: [String: HomeDayCache] = [:]

    private init() {}

    func cache(for day: DayDate) -> HomeDayCache {
        caches[day.apiString] ?? HomeDayCache()
    }

    /// 无缓存 / 请求中 / 未成功且无错误 → 显示 loading。
    func isDayLoading(_ day: DayDate) -> Bool {
        guard let cache = caches[day.apiString] else { return true }
        if cache.isLoading { return true }
        if cache.loaded { return false }
        return cache.error == nil
    }

    func pullToRefresh(_ day: DayDate) async {
        await Task.detached { @MainActor in
            await HomeSession.shared.load(day, force: true)
        }.value
    }

    /// 跳到指定日（月份列表点选后回到首页用）；超出滑动窗口时夹到最近可滑日期。
    func jumpToDay(_ day: DayDate) {
        selectedDay = selectableDay(matching: day)
    }

    private func selectableDay(matching day: DayDate) -> DayDate {
        if days.contains(day) { return day }
        guard let first = days.first, let last = days.last else { return .today }
        if day.apiString < first.apiString { return first }
        if day.apiString > last.apiString { return last }
        // 窗口内但未收录（理论上不会）：取不晚于目标日的最近一天
        return days.last(where: { $0.apiString <= day.apiString }) ?? last
    }

    /// 翻页、进 Tab、子页出现：异步拉取（loading 由 `isDayLoading` 推导）。
    func requestLoad(_ day: DayDate, force: Bool = false) {
        Task.detached { @MainActor in
            await HomeSession.shared.load(day, force: force)
        }
    }

    func load(_ day: DayDate, force: Bool = false) async {
        let key = day.apiString
        var cache = caches[key] ?? HomeDayCache()

        if !force, cache.loaded || cache.isLoading { return }

        if force {
            cache.loaded = false
            cache.articles = []
            cache.topText = nil
        }

        cache.isLoading = true
        cache.error = nil
        caches[key] = cache

        do {
            let payload = try await OneClient.articleDay(publishedAt: day.apiString)
            var latest = caches[key] ?? cache
            latest.articles = payload.articles
            latest.topText = payload.topText
            latest.loaded = true
            latest.error = nil
            latest.isLoading = false
            caches[key] = latest
        } catch {
            if error.isRequestCancellation {
                var latest = caches[key] ?? cache
                latest.isLoading = false
                caches[key] = latest
                return
            }
            var latest = caches[key] ?? cache
            latest.isLoading = false
            latest.error = error.localizedDescription
            caches[key] = latest
        }
    }
}
