import Foundation

/// 容忍接口里「数字 / 字符串」混用。
enum JSONFlex {
    static func int<K: CodingKey>(_ c: KeyedDecodingContainer<K>, _ key: K) -> Int? {
        if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return value }
        if let text = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if let value = try? c.decodeIfPresent(Double.self, forKey: key) { return Int(value) }
        return nil
    }

    static func string<K: CodingKey>(_ c: KeyedDecodingContainer<K>, _ key: K) -> String? {
        if let text = try? c.decodeIfPresent(String.self, forKey: key) { return text }
        if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return String(value) }
        if let value = try? c.decodeIfPresent(Double.self, forKey: key) {
            return String(Int(value))
        }
        return nil
    }
}

/// 忽略 `data` 具体内容（发短信等只校验外层 `code`）。
struct IgnoredJSON: Decodable {
    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer() {
            if (try? single.decodeNil()) == true { return }
            if (try? single.decode(Bool.self)) != nil { return }
            if (try? single.decode(Int.self)) != nil { return }
            if (try? single.decode(Double.self)) != nil { return }
            if (try? single.decode(String.self)) != nil { return }
            return
        }
        if var array = try? decoder.unkeyedContainer() {
            while !array.isAtEnd { _ = try? array.decode(IgnoredJSON.self) }
            return
        }
        _ = try? decoder.container(keyedBy: AnyKey.self)
    }

    private struct AnyKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }
}
