import Foundation

/// 拼接 CDN 绝对 URL：`base + 相对路径`（已是 http 则原样返回）。
enum OneCDN {
    static func join(base: String, path: String) -> String {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPath.isEmpty { return "" }
        if trimmedPath.lowercased().hasPrefix("http://") || trimmedPath.lowercased().hasPrefix("https://") {
            return trimmedPath
        }
        let root = base.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !root.isEmpty else { return trimmedPath }
        let pathPart = trimmedPath.hasPrefix("/") ? trimmedPath : "/\(trimmedPath)"
        return root + pathPart
    }
}
