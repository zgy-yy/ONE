import Foundation

/// 列表里的文章摘要（首页 / 发现 / 搜索等）。
struct ArticleSummary: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let thumb: String?
    let thumbnail: String?
    let author: String?
    let publishedAt: String?
    let modelID: Int?
    /// 写真 / 漫画：1 写真，2 漫画。
    let seriesCategory: Int?
    /// 所属系列 id（首页日更里写真/漫画跳转系列详情用）。
    let seriesID: Int?
    let summary: String?
    let coin: Int?
    let originalCoin: Int?
    let likeNumber: Int?
    let collectionNumber: Int?
    /// 播放量 / 浏览量（接口 `views`）。
    let views: Int?
    /// 仅 `0` / `1`：是否已喜欢。
    let isLike: Int?
    /// 仅 `0` / `1`：是否已收藏。
    let isCollected: Int?
    /// 时长文案，如 `129分钟`。
    let length: String?
    /// 分卷 / 集数（接口 `vol`）。
    let vol: Int?

    var isLiked: Bool { isLike == 1 }
    var hasCollected: Bool { isCollected == 1 }

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return "ID \(id)"
    }

    /// `model_id == 4` 时进系列详情（发现 / 搜索）；首页日更仍打开单篇。
    var opensAsSeries: Bool { modelID == ContentCategory.ModelID.series }

    var asSeriesSummary: SeriesSummary {
        SeriesSummary(
            id: seriesID ?? id,
            title: title,
            author: author,
            thumb: thumb,
            thumbnail: thumbnail,
            likeTotal: likeNumber.map(String.init)
        )
    }

    init(
        id: Int,
        title: String?,
        thumb: String?,
        author: String?,
        publishedAt: String?,
        modelID: Int?,
        summary: String?,
        coin: Int? = nil,
        originalCoin: Int? = nil,
        likeNumber: Int? = nil,
        collectionNumber: Int? = nil,
        views: Int? = nil,
        isLike: Int? = nil,
        isCollected: Int? = nil,
        length: String? = nil,
        vol: Int? = nil,
        thumbnail: String? = nil,
        seriesCategory: Int? = nil,
        seriesID: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.thumb = thumb
        self.thumbnail = thumbnail
        self.author = author
        self.publishedAt = publishedAt
        self.modelID = modelID
        self.seriesCategory = seriesCategory
        self.seriesID = seriesID
        self.summary = summary
        self.coin = coin
        self.originalCoin = originalCoin
        self.likeNumber = likeNumber
        self.collectionNumber = collectionNumber
        self.views = views
        self.isLike = isLike
        self.isCollected = isCollected
        self.length = length
        self.vol = vol
    }

    enum CodingKeys: String, CodingKey {
        case id, title, thumb, thumbnail, author, coin, length, vol
        case publishedAt = "published_at"
        case modelID = "model_id"
        case summary = "description"
        case originalCoin = "original_coin"
        case likeNumber = "like_number"
        case collectionNumber = "collection_number"
        case views
        case isLike = "is_like"
        case isCollected = "is_collected"
        case seriesCategory = "series_category"
        case seriesID = "series_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        thumb = try c.decodeIfPresent(String.self, forKey: .thumb)
        thumbnail = try c.decodeIfPresent(String.self, forKey: .thumbnail)
        author = try c.decodeIfPresent(String.self, forKey: .author)
        publishedAt = try c.decodeIfPresent(String.self, forKey: .publishedAt)
        modelID = JSONFlex.int(c, .modelID)
        seriesCategory = JSONFlex.int(c, .seriesCategory)
        seriesID = JSONFlex.int(c, .seriesID)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        coin = JSONFlex.int(c, .coin)
        originalCoin = JSONFlex.int(c, .originalCoin)
        likeNumber = JSONFlex.int(c, .likeNumber)
        collectionNumber = JSONFlex.int(c, .collectionNumber)
        views = JSONFlex.int(c, .views)
        isLike = JSONFlex.int(c, .isLike)
        isCollected = JSONFlex.int(c, .isCollected)
        length = JSONFlex.string(c, .length)
        vol = JSONFlex.int(c, .vol)
    }
}
