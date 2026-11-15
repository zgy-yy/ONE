import Foundation

/// 详情页常用的字符串、数字展示（避免在 View 里重复写判断）。
enum ArticleFormat {
    /// 去掉首尾空白；空字符串当作「没有值」返回 `nil`。
    static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// `2026-11-05 03:23:00` → 只保留日期部分。
    static func dateOnly(from publishedAt: String?) -> String? {
        guard let raw = nonEmpty(publishedAt) else { return nil }
        if let space = raw.firstIndex(of: " ") {
            return String(raw[..<space])
        }
        return raw
    }

    /// 大数字缩写成「1.2万」「3.5M」。
    static func shortCount(_ n: Int) -> String {
        if n >= 1_000_000 {
            return String(format: "%.1fM", Double(n) / 1_000_000)
        }
        if n >= 10_000 {
            return String(format: "%.1f万", Double(n) / 10_000)
        }
        return "\(n)"
    }
}