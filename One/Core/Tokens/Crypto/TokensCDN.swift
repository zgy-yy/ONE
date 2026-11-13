import Foundation

/// 从 splash `data.host` 数组解析 `one_img` / `one_video` CDN 根地址。
enum TokensCDN {
    struct Bases: Sendable {
        var oneImg = ""
        var oneVideo = ""
    }

    static func extract(from config: SplashConfig?) -> Bases {
        var bases = Bases()
        guard let host = config?.host else { return bases }
        for item in host {
            guard case .object(let record) = item else { continue }
            let name = string(in: record, keys: ["name", "key", "type"]) ?? ""
            let url = string(in: record, keys: ["host", "url", "value", "token"]) ?? ""
            if !name.isEmpty, !url.isEmpty {
                applyHostKey(name, url: url, bases: &bases)
            }
        }
        return bases
    }

    private static func string(in object: [String: JSONValue], keys: [String]) -> String? {
        for key in keys {
            if case .string(let value) = object[key], !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private static func applyHostKey(_ key: String, url: String, bases: inout Bases) {
        var normalized = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        let k = key.lowercased().replacingOccurrences(of: "flutter.", with: "")
        guard normalized.hasPrefix("http") else { return }
        if k == "one_img" || k.contains("one_img") || k == "oneimg" {
            bases.oneImg = normalized
        }
        if k == "one_video" || k.contains("one_video") || k == "onevideo" {
            bases.oneVideo = normalized
        }
    }
}
