import Foundation

/// 拼接「基址 + 相对 path」为绝对 URL（壳 / ONE 共用）。
enum APIURL {
    static func join(base: String, path: String) -> URL {
        let trimmedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let root = base.hasSuffix("/") ? base : base + "/"
        guard let url = URL(string: trimmedPath, relativeTo: URL(string: root)!)?.absoluteURL else {
            preconditionFailure("Invalid URL base=\(base) path=\(path)")
        }
        return url
    }
}
