import Foundation

/// 从 splash 的 JSON 树里递归查找 `one_img` / `one_video` CDN 根地址。
enum TokensCDN {
    struct Bases: Sendable {
        var oneImg = ""
        var oneVideo = ""
    }

    static func extract(from config: SplashConfig?) -> Bases {
        var bases = Bases()
        guard let config else { return bases }
        if let splash = config.splash {
            walk(splash, bases: &bases)
        }
        if let host = config.host {
            walk(.array(host), bases: &bases)
        }
        return bases
    }

    private static func walk(_ value: JSONValue, bases: inout Bases) {
        switch value {
        case .object(let dict):
            for (key, child) in dict {
                if case .string(let text) = child, text.hasPrefix("http") {
                    applyHostKey(key, url: text, bases: &bases)
                }
                walk(child, bases: &bases)
            }
        case .array(let items):
            for item in items {
                if case .object(let record) = item {
                    let name =
                        string(in: record, keys: ["name", "key", "type"]) ?? ""
                    let url =
                        string(in: record, keys: ["host", "url", "value", "token"]) ?? ""
                    if !name.isEmpty, !url.isEmpty {
                        applyHostKey(name, url: url, bases: &bases)
                    }
                }
                walk(item, bases: &bases)
            }
        default:
            break
        }
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
