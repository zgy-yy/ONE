import Foundation

/// `series/chapters` 单章。
struct SeriesChapter: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let thumb: String?
    let thumbnail: String?
    let author: String?
    let chapter: Int?
    let description: String?
    let publishedAt: String?
    let likeNumber: Int?

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
            author: author,
            publishedAt: publishedAt,
            modelID: ContentCategory.ModelID.series,
            summary: description,
            likeNumber: likeNumber,
            thumbnail: thumbnail
        )
    }

    init(
        id: Int,
        title: String? = nil,
        thumb: String? = nil,
        thumbnail: String? = nil,
        author: String? = nil,
        chapter: Int? = nil,
        description: String? = nil,
        publishedAt: String? = nil,
        likeNumber: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.thumb = thumb
        self.thumbnail = thumbnail
        self.author = author
        self.chapter = chapter
        self.description = description
        self.publishedAt = publishedAt
        self.likeNumber = likeNumber
    }

    enum CodingKeys: String, CodingKey {
        case id, title, thumb, thumbnail, author, chapter, description
        case publishedAt = "published_at"
        case likeNumber = "like_number"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        thumb = try c.decodeIfPresent(String.self, forKey: .thumb)
        thumbnail = try c.decodeIfPresent(String.self, forKey: .thumbnail)
        author = try c.decodeIfPresent(String.self, forKey: .author)
        chapter = JSONFlex.int(c, .chapter)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        publishedAt = try c.decodeIfPresent(String.self, forKey: .publishedAt)
        likeNumber = JSONFlex.int(c, .likeNumber)
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
