import Foundation

struct DemandTag: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return "标签 \(id)"
    }
}

/// 列表项摘要；`Identifiable` 供 SwiftUI `List` 使用。
struct ArticleSummary: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let thumb: String?

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return "ID \(id)"
    }
    let author: String?
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
