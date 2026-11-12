import Foundation

/// 壳服务 IP 列表（多线路容灾）。
enum TokensTargets {
    static let bases: [String] = [
        "http://202.95.22.200:6868",
        "http://202.95.22.201:6868",
        "http://202.95.22.202:6868",
        "http://198.44.248.102:6868",
        "http://38.46.10.6:6868",
    ]
}

/// 把「基址 + 相对 path」拼成合法 `URL`（壳与 ONE 共用）。
enum TokensAPIPath {
    static func join(base: String, path: String) -> URL {
        let trimmedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let root = base.hasSuffix("/") ? base : base + "/"
        guard let url = URL(string: trimmedPath, relativeTo: URL(string: root)!)?.absoluteURL else {
            preconditionFailure("Invalid URL base=\(base) path=\(path)")
        }
        return url
    }
}
