import Foundation

/// 首页日期：`YYYY-MM-DD`。
struct DayDate: Equatable, Hashable, Identifiable {
    var year: Int
    var month: Int
    var day: Int

    var id: String { apiString }

    var apiString: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// 点击日期进入当月 discovery 用：`YYYY-MM`。
    var monthAPIString: String {
        String(format: "%04d-%02d", year, month)
    }

    var displayTitle: String {
        String(format: "%d月%d日", month, day)
    }

    var monthDisplayTitle: String {
        String(format: "%d年%d月", year, month)
    }

    static var today: DayDate {
        let c = Calendar.current
        let now = Date()
        return DayDate(
            year: c.component(.year, from: now),
            month: c.component(.month, from: now),
            day: c.component(.day, from: now)
        )
    }

    var previous: DayDate? {
        shifted(by: -1)
    }

    var next: DayDate? {
        let candidate = shifted(by: 1)
        guard let candidate, candidate <= .today else { return nil }
        return candidate
    }

    /// 从 `daysAgo` 天前到今天（含），旧→新。
    static func range(daysAgo: Int) -> [DayDate] {
        let end = DayDate.today
        var list: [DayDate] = [end]
        var cursor = end
        for _ in 0..<daysAgo {
            guard let prev = cursor.previous else { break }
            list.append(prev)
            cursor = prev
        }
        return list.reversed()
    }

    private func shifted(by days: Int) -> DayDate? {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        guard let date = Calendar.current.date(from: comps),
              let moved = Calendar.current.date(byAdding: .day, value: days, to: date)
        else { return nil }
        let c = Calendar.current
        return DayDate(
            year: c.component(.year, from: moved),
            month: c.component(.month, from: moved),
            day: c.component(.day, from: moved)
        )
    }

    static func <= (lhs: DayDate, rhs: DayDate) -> Bool {
        lhs.apiString <= rhs.apiString
    }
}
