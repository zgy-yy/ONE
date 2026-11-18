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

    /// 顶栏用：日数字，如 `03`。
    var dayNumberTitle: String {
        String(format: "%02d", day)
    }

    /// 顶栏用：`nov.2026`。
    var monthYearTitle: String {
        "\(Self.englishMonthAbbr[month]).\(year)"
    }

    var monthDisplayTitle: String {
        String(format: "%d年%d月", year, month)
    }

    private static let englishMonthAbbr = [
        "", "jan", "feb", "mar", "apr", "may", "jun",
        "jul", "aug", "sep", "oct", "nov", "dec",
    ]

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// 从 `YYYY-MM-DD` 或带时间的字符串解析（取前 10 位日期）。
    init?(apiString: String) {
        let trimmed = apiString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 else { return nil }
        let stamp = String(trimmed.prefix(10))
        let parts = stamp.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]),
              month >= 1, month <= 12,
              day >= 1, day <= 31
        else { return nil }
        self.init(year: year, month: month, day: day)
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
