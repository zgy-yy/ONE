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

/// `article/detail` 完整稿件（含播放路径；与 one-web `resolvePlayUrls` 字段一致）。
struct ArticleDetail: Decodable, Identifiable {
    let id: Int
    let title: String?
    let thumb: String?
    let author: String?
    let publishedAt: String?
    let summary: String?
    let content: String?
    let videoFile: String?
    let videoHls: String?
    let video: String?
    let previewVideo: String?
    let videos: [ArticleVideoItem]?

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return "ID \(id)"
    }

    var displayBody: String? {
        if let content, !content.isEmpty { return content }
        if let summary, !summary.isEmpty { return summary }
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case id, title, thumb, author, content, video, videos
        case publishedAt = "published_at"
        case summary = "description"
        case videoFile = "video_file"
        case videoHls = "video_hls"
        case previewVideo = "preview_video"
    }
}

struct ArticleVideoItem: Decodable {
    let title: String?
    let videoFile: String?

    enum CodingKeys: String, CodingKey {
        case title
        case videoFile = "video_file"
    }
}

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
