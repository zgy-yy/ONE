import Foundation

/// 点播列表排序（接口字段 `sort`）。
enum VodArticleSort: String, CaseIterable, Identifiable, Hashable {
    case likeNumber = "like_number"
    case publishedAt = "published_at"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .likeNumber: "点赞"
        case .publishedAt: "时间"
        }
    }
}

/// 列表筛选月份 `YYYY-MM`。
struct MonthYear: Equatable {
    var year: Int
    var month: Int

    var apiString: String {
        String(format: "%04d-%02d", year, month)
    }

    static var now: MonthYear {
        let calendar = Calendar.current
        let date = Date()
        return MonthYear(
            year: calendar.component(.year, from: date),
            month: calendar.component(.month, from: date)
        )
    }

    init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    init?(apiString: String) {
        let parts = apiString.split(separator: "-")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]) else { return nil }
        self.init(year: year, month: month)
    }

    static func clamped(year: Int, month: Int) -> MonthYear {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        var y = min(max(year, currentYear - 5), currentYear)
        var m = month
        let months = MonthYear(year: y, month: 1).selectableMonths
        if !months.contains(m), let last = months.last { m = last }
        if y == currentYear { m = min(m, currentMonth) }
        return MonthYear(year: y, month: m)
    }

    static var selectableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...currentYear).reversed()
    }

    var selectableMonths: [Int] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        if year < currentYear { return Array(1...12) }
        if year == currentYear { return Array(1...currentMonth) }
        return []
    }
}
