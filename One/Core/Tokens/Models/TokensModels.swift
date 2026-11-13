import Foundation

/// splash 接口对应的 `Codable` 模型（`Codable` = 可编码/解码 JSON）。
struct TokenEntry: Codable, Sendable, Equatable {
    let id: Int?
    let name: String
    let token: String
}

struct SplashConfig: Codable, Sendable {
    let host: [JSONValue]?
    let splash: JSONValue?
    let token: [TokenEntry]?
}

struct SplashEnvelope: Codable, Sendable {
    let code: Int?
    let msg: String?
    let data: SplashConfig?
}

struct TokensResult: Sendable {
    let baseURL: URL
    let envelope: SplashEnvelope
    var tokens: [TokenEntry] { envelope.data?.token ?? [] }
}

/// 结构不固定的 JSON 用递归枚举表示，便于遍历查找 CDN 等字段。
enum JSONValue: Codable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Double.self) {
            self = .number(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode([String: JSONValue].self) {
            self = .object(v)
        } else if let v = try? container.decode([JSONValue].self) {
            self = .array(v)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .number(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}
