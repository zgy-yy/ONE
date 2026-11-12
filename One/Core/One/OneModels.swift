import Foundation

/// 接口路径常量、通用响应壳 `OneApiEnvelope`、列表/分类模型。
enum OneAPI {
    /// 相对 `OneTargets.bases`（已含 `v2.5`）
    static let demandTagListPath = "navigation/getDemandTagList"
    static let discoveryPath = "article/discovery"

    static func isSuccess(code: Int?) -> Bool {
        code == 200 || code == 400
    }
}

struct OneApiEnvelope<T: Decodable>: Decodable {
    let code: Int?
    let message: String?
    let data: T?
}

struct DemandTag: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?
}

/// 列表项摘要；`Identifiable` 供 SwiftUI `List` 使用。
struct ArticleSummary: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let thumb: String?
    let author: String?
    /// 接口多为 `"2026-11-05 03:23:00"` 字符串。
    let publishedAt: String?
    let modelID: Int?
    let summary: String?

    enum CodingKeys: String, CodingKey {
        case id, title, thumb, author
        case publishedAt = "published_at"
        case modelID = "model_id"
        case summary = "description"
    }
}

/// `data` 为文章数组，或 `{ "info": [...] }`。
struct DiscoveryListPayload: Decodable {
    let articles: [ArticleSummary]

    private struct InfoWrapper: Decodable {
        let info: [ArticleSummary]?
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let list = try? container.decode([ArticleSummary].self) {
            articles = list
            return
        }
        let wrapped = try container.decode(InfoWrapper.self)
        articles = wrapped.info ?? []
    }
}
