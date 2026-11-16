import Foundation

/// 列表筛选月份 `YYYY-MM`。
struct MonthYear: Equatable {
    /// 接口允许的最早月份。
    static let earliest = MonthYear(year: 2019, month: 11)

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

        let y = min(max(year, MonthYear.earliest.year), currentYear)
        var m = month

        if y == MonthYear.earliest.year {
            m = max(m, MonthYear.earliest.month)
        }
        if y == currentYear {
            m = min(m, currentMonth)
        }

        let months = MonthYear(year: y, month: m).selectableMonths
        if !months.contains(m), let nearest = months.min(by: { abs($0 - m) < abs($1 - m) }) {
            m = nearest
        }

        return MonthYear(year: y, month: m)
    }

    static var selectableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(MonthYear.earliest.year...currentYear).reversed()
    }

    /// 上一月；不早于 `earliest` 时返回 `nil`。
    var previous: MonthYear? {
        var calendar = Calendar.current
        calendar.timeZone = .current
        guard let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let prev = calendar.date(byAdding: .month, value: -1, to: start) else { return nil }
        let candidate = MonthYear(
            year: calendar.component(.year, from: prev),
            month: calendar.component(.month, from: prev)
        )
        let min = MonthYear.earliest
        if candidate.year < min.year { return nil }
        if candidate.year == min.year, candidate.month < min.month { return nil }
        return candidate
    }

    var displayTitle: String {
        "\(year)年\(month)月"
    }

    /// 列表分区头：把接口月份 `YYYY-MM` 格式化为展示文案。
    static func sectionTitle(forAPIString apiMonth: String) -> String {
        MonthYear(apiString: apiMonth)?.displayTitle ?? apiMonth
    }

    var selectableMonths: [Int] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())

        if year == MonthYear.earliest.year {
            if year == currentYear {
                return Array(MonthYear.earliest.month...currentMonth)
            }
            return Array(MonthYear.earliest.month...12)
        }
        if year < currentYear { return Array(1...12) }
        if year == currentYear { return Array(1...currentMonth) }
        return []
    }
}
