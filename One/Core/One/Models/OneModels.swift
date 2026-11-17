import CoreGraphics
import Foundation

struct DemandTag: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?

    /// 点播顶栏「全部」，请求时 `demand_tag_id=0`。
    static let all = DemandTag(id: 0, title: "全部")

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
    let author: String?
    let publishedAt: String?
    let modelID: Int?
    let summary: String?
    /// 现价。
    let coin: String?
    /// 原价（`original_coin`）。
    let originalCoin: String?
    let likeNumber: Int?
    /// 时长，如 `129分钟`。
    let length: String?

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return "ID \(id)"
    }

    /// 图文竖图 3:4，其余 16:9；列表未回传 `model_id` 时用 `fallbackModelID`。
    func coverAspectRatio(fallbackModelID: Int? = nil) -> CGFloat {
        CoverAspect.ratio(modelID: modelID, fallback: fallbackModelID)
    }

    init(
        id: Int,
        title: String?,
        thumb: String?,
        author: String?,
        publishedAt: String?,
        modelID: Int?,
        summary: String?,
        coin: String? = nil,
        originalCoin: String? = nil,
        likeNumber: Int? = nil,
        length: String? = nil
    ) {
        self.id = id
        self.title = title
        self.thumb = thumb
        self.author = author
        self.publishedAt = publishedAt
        self.modelID = modelID
        self.summary = summary
        self.coin = coin
        self.originalCoin = originalCoin
        self.likeNumber = likeNumber
        self.length = length
    }

    enum CodingKeys: String, CodingKey {
        case id, title, thumb, author, coin, length
        case publishedAt = "published_at"
        case modelID = "model_id"
        case summary = "description"
        case originalCoin = "original_coin"
        case likeNumber = "like_number"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        thumb = try c.decodeIfPresent(String.self, forKey: .thumb)
        author = try c.decodeIfPresent(String.self, forKey: .author)
        publishedAt = try c.decodeIfPresent(String.self, forKey: .publishedAt)
        modelID = JSONFlex.int(c, .modelID)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        coin = JSONFlex.string(c, .coin)
        originalCoin = JSONFlex.string(c, .originalCoin)
        likeNumber = JSONFlex.int(c, .likeNumber)
        length = JSONFlex.string(c, .length)
    }
}

/// `article/detail` 完整稿件（含播放路径；与 one-web `resolvePlayUrls` 字段一致）。
struct ArticleDetail: Decodable, Identifiable {
    let id: Int
    let title: String?
    /// 点播长标题（播放器下方优先展示）
    let videoName: String?
    let thumb: String?
    let author: String?
    /// 演员 / 女优
    let actor: String?
    /// 番号
    let number: String?
    let publishedAt: String?
    let summary: String?
    let content: String?
    let videoFile: String?
    let videoHls: String?
    let video: String?
    let previewVideo: String?
    let videos: [ArticleVideoItem]?
    let multiplePic: [String]?
    /// 现价（金币/贝壳，`coin`）
    let coin: String?
    /// 原价（`original_coin`）
    let originalCoin: String?
    /// 时长，如 `129分钟`
    let length: String?
    /// 体积，如 `1.37GB`
    let size: String?
    /// 分辨率，如 `1920x1080`
    let quality: String?
    let likeNumber: Int?
    let collectionNumber: Int?
    let views: Int?
    let downloadCount: Int?
    let shareNumber: Int?
    /// 评论数。详情接口字段为 `reply_counts`（兼容 `comment_number` / `comment_num` / `comment_count`）。
    let commentNumber: Int?
    let tagList: [ArticleDetailTag]?

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return "ID \(id)"
    }

    /// 播放器下方标题：优先 `video_name`，否则回退 `title`。
    var displayVideoName: String {
        if let videoName, !videoName.isEmpty { return videoName }
        return displayTitle
    }

    var displayBody: String? {
        if let content, !content.isEmpty { return content }
        if let summary, !summary.isEmpty { return summary }
        return nil
    }

    var galleryPaths: [String] {
        multiplePic?.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? []
    }

    var displayTags: [ArticleDetailTag] {
        tagList?.filter { !$0.displayName.isEmpty } ?? []
    }

    enum CodingKeys: String, CodingKey {
        case id, title, thumb, author, actor, number, content, video, videos
        case videoName = "video_name"
        case publishedAt = "published_at"
        case summary = "description"
        case videoFile = "video_file"
        case videoHls = "video_hls"
        case previewVideo = "preview_video"
        case multiplePic = "multiple_pic"
        case coin
        case originalCoin = "original_coin"
        case length, size, quality
        case likeNumber = "like_number"
        case collectionNumber = "collection_number"
        case views
        case downloadCount = "download_count"
        case shareNumber = "share_number"
        case replyCounts = "reply_counts"
        case commentNumber = "comment_number"
        case commentNum = "comment_num"
        case commentCount = "comment_count"
        case tagList = "tag_list"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        videoName = try c.decodeIfPresent(String.self, forKey: .videoName)
        thumb = try c.decodeIfPresent(String.self, forKey: .thumb)
        author = try c.decodeIfPresent(String.self, forKey: .author)
        actor = try c.decodeIfPresent(String.self, forKey: .actor)
        number = try c.decodeIfPresent(String.self, forKey: .number)
        publishedAt = try c.decodeIfPresent(String.self, forKey: .publishedAt)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        content = try c.decodeIfPresent(String.self, forKey: .content)
        videoFile = try c.decodeIfPresent(String.self, forKey: .videoFile)
        videoHls = try c.decodeIfPresent(String.self, forKey: .videoHls)
        video = try c.decodeIfPresent(String.self, forKey: .video)
        previewVideo = try c.decodeIfPresent(String.self, forKey: .previewVideo)
        videos = try c.decodeIfPresent([ArticleVideoItem].self, forKey: .videos)
        multiplePic = try c.decodeIfPresent([String].self, forKey: .multiplePic)
        coin = try c.decodeIfPresent(String.self, forKey: .coin)
        originalCoin = try c.decodeIfPresent(String.self, forKey: .originalCoin)
        length = try c.decodeIfPresent(String.self, forKey: .length)
        size = try c.decodeIfPresent(String.self, forKey: .size)
        quality = try c.decodeIfPresent(String.self, forKey: .quality)
        likeNumber = JSONFlex.int(c, .likeNumber)
        collectionNumber = JSONFlex.int(c, .collectionNumber)
        views = JSONFlex.int(c, .views)
        downloadCount = JSONFlex.int(c, .downloadCount)
        shareNumber = JSONFlex.int(c, .shareNumber)
        tagList = try c.decodeIfPresent([ArticleDetailTag].self, forKey: .tagList)
        // 详情主字段是 reply_counts
        commentNumber =
            JSONFlex.int(c, .replyCounts)
            ?? JSONFlex.int(c, .commentNumber)
            ?? JSONFlex.int(c, .commentNum)
            ?? JSONFlex.int(c, .commentCount)
    }
}

/// `article/detail` 的 `tag_list` 项（展示 `slug`）。
struct ArticleDetailTag: Decodable, Identifiable, Hashable {
    let id: Int
    let slug: String?

    var displayName: String {
        let name = slug?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !name.isEmpty { return name }
        return "标签 \(id)"
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
