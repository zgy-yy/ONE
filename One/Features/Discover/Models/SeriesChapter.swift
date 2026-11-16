import Foundation

/// `series/chapters` 单章。
struct SeriesChapter: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let thumb: String?
    let thumbnail: String?
    let chapter: Int?
    let description: String?
    let publishedAt: String?

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        if let chapter { return "第 \(chapter) 话" }
        return "章节 \(id)"
    }

    var imagePath: String? {
        ImagePath.preferred(thumb: thumb, thumbnail: thumbnail)
    }

    /// 章节 ID 即稿件 ID，可直接打开文章详情。
    var asArticleSummary: ArticleSummary {
        ArticleSummary(
            id: id,
            title: title,
            thumb: thumb,
            author: nil,
            publishedAt: publishedAt,
            modelID: nil,
            summary: description
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, title, thumb, thumbnail, chapter, description
        case publishedAt = "published_at"
    }
}

/// `series/chapters` 的 `data`。
struct SeriesDetail: Decodable {
    let title: String?
    let author: String?
    let thumb: String?
    let end: Int?
    let chapters: [SeriesChapter]?

    var displayTitle: String {
        title?.nonEmpty ?? "系列"
    }

    var isFinished: Bool { end == 1 }

    var chapterList: [SeriesChapter] {
        chapters ?? []
    }
}
