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

    /// 可滑动的日期窗口（约三个月，旧→新；最右为今天）。
    let days: [DayDate] = DayDate.range(daysAgo: 90)

    var selectedDay: DayDate = .today

    private var caches: [String: HomeDayCache] = [:]
    /// 正在请求中的日期，避免翻页时 `onChange` 与 `.task` 重复打接口。
    private var inFlight: Set<String> = []
    /// 日列表下拉刷新（`refreshable` 取消后仍保持 loading）。
    private var dayPullRefreshing: Set<String> = []

    private init() {}

    func cache(for day: DayDate) -> HomeDayCache {
        caches[day.apiString] ?? HomeDayCache()
    }

    func isDayPullRefreshing(_ day: DayDate) -> Bool {
        dayPullRefreshing.contains(day.apiString)
    }

    func pullToRefresh(_ day: DayDate) async {
        let key = day.apiString
        dayPullRefreshing.insert(key)
        await Task.detached { @MainActor in
            defer { HomeSession.shared.dayPullRefreshing.remove(key) }
            await HomeSession.shared.load(day, force: true)
        }.value
    }

    /// 跳到指定日（月份列表点选后回到首页用）；超出滑动窗口时夹到最近可滑日期。
    func jumpToDay(_ day: DayDate) {
        selectedDay = selectableDay(matching: day)
        prepareLoad(selectedDay)
    }

    private func selectableDay(matching day: DayDate) -> DayDate {
        if days.contains(day) { return day }
        guard let first = days.first, let last = days.last else { return .today }
        if day.apiString < first.apiString { return first }
        if day.apiString > last.apiString { return last }
        // 窗口内但未收录（理论上不会）：取不晚于目标日的最近一天
        return days.last(where: { $0.apiString <= day.apiString }) ?? last
    }

    /// 翻页时立刻标记 loading，保证「先切过去」就能看到加载态。
    func prepareLoad(_ day: DayDate) {
        var cache = caches[day.apiString] ?? HomeDayCache()
        guard !cache.loaded else { return }
        cache.isLoading = true
        cache.error = nil
        caches[day.apiString] = cache
    }

    func load(_ day: DayDate, force: Bool = false) async {
        let key = day.apiString
        var cache = caches[key] ?? HomeDayCache()

        if !force, cache.loaded { return }
        if !force, inFlight.contains(key) {
            prepareLoad(day)
            return
        }

        if force {
            cache.loaded = false
            cache.articles = []
            cache.topText = nil
        }

        inFlight.insert(key)
        cache.isLoading = true
        cache.error = nil
        caches[key] = cache
        defer { inFlight.remove(key) }

        do {
            let payload = try await OneClient.articleDay(publishedAt: day.apiString)
            cache.articles = payload.articles
            cache.topText = payload.topText
            cache.loaded = true
            cache.isLoading = false
            cache.error = nil
            caches[key] = cache
        } catch {
            if error.isRequestCancellation {
                if !dayPullRefreshing.contains(key) {
                    var latest = caches[key] ?? cache
                    latest.isLoading = false
                    caches[key] = latest
                }
                return
            }
            var latest = caches[key] ?? cache
            latest.isLoading = false
            latest.error = error.localizedDescription
            caches[key] = latest
        }
    }
}
