import Foundation

/// `article/discovery` 的 `data`：文章数组，或 `{ "info": [...] }`。
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

/// `article/day` 的 `data`。
struct ArticleDayPayload: Decodable {
    let articleTopText: String?
    let info: [ArticleSummary]?

    var articles: [ArticleSummary] { info ?? [] }

    var topText: String? {
        articleTopText?.nonEmpty
    }

    enum CodingKeys: String, CodingKey {
        case info
        case articleTopText = "article_top_text"
    }
}
