import Foundation

/// `article/search` 列表项。
struct SearchHit: Decodable, Identifiable, Hashable {
    let id: Int
    let modelID: Int?
    let thumb: String?
    let thumbnail: String?
    let title: String?
    let subtitle: String?
    let publishedAt: String?

    var displayTitle: String {
        title?.nonEmpty ?? "内容 \(id)"
    }

    var imagePath: String? {
        ImagePath.preferred(thumb: thumb, thumbnail: thumbnail)
    }

    /// 接口 `subtitle` 一般为作者。
    var author: String? { subtitle }

    /// 搜索里写真 / 漫画条目的 `model_id`。
    var opensAsSeries: Bool { modelID == ContentCategory.ModelID.series }

    var asArticleSummary: ArticleSummary {
        ArticleSummary(
            id: id,
            title: title,
            thumb: imagePath,
            author: subtitle,
            publishedAt: publishedAt,
            modelID: modelID,
            summary: subtitle
        )
    }

    var asSeriesSummary: SeriesSummary {
        SeriesSummary(
            id: id,
            title: title,
            author: subtitle,
            thumb: thumb,
            thumbnail: thumbnail
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, thumb, thumbnail, title, subtitle
        case modelID = "model_id"
        case publishedAt = "published_at"
    }
}
