import Foundation

/// `article/detail` 完整稿件（含播放相对路径）。
struct ArticleDetail: Decodable, Identifiable {
    let id: Int
    let title: String?
    /// 点播长标题（播放器下方优先展示）。
    let videoName: String?
    let thumb: String?
    let author: String?
    let actor: String?
    /// 番号。
    let number: String?
    let publishedAt: String?
    let summary: String?
    let content: String?
    let videoFile: String?
    let videoHls: String?
    /// H.265 HLS（优先于 `video_hls`）。
    let videoHlsH265: String?
    let video: String?
    let previewVideo: String?
    let videos: [ArticleVideoItem]?
    let multiplePic: [String]?
    let coin: Int?
    let originalCoin: Int?
    let length: String?
    let vol: Int?
    let size: String?
    let quality: String?
    var likeNumber: Int?
    var collectionNumber: Int?
    let views: Int?
    let downloadCount: Int?
    let shareNumber: Int?
    /// 评论数：主字段 `reply_counts`，兼容若干旧名。
    let commentNumber: Int?
    /// 仅 `0` / `1`：是否已喜欢（可本地切换）。
    var isLike: Int?
    /// 仅 `0` / `1`：是否已收藏（可本地切换）。
    var isCollected: Int?
    let tagList: [ArticleDetailTag]?

    var isLiked: Bool { isLike == 1 }
    var hasCollected: Bool { isCollected == 1 }

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return "ID \(id)"
    }

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
        case videoHlsH265 = "video_hls_h265"
        case previewVideo = "preview_video"
        case multiplePic = "multiple_pic"
        case coin
        case originalCoin = "original_coin"
        case length, vol, size, quality
        case likeNumber = "like_number"
        case collectionNumber = "collection_number"
        case views
        case downloadCount = "download_count"
        case shareNumber = "share_number"
        case replyCounts = "reply_counts"
        case commentNumber = "comment_number"
        case commentNum = "comment_num"
        case commentCount = "comment_count"
        case isLike = "is_like"
        case isCollected = "is_collected"
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
        videoHlsH265 = try c.decodeIfPresent(String.self, forKey: .videoHlsH265)
        video = try c.decodeIfPresent(String.self, forKey: .video)
        previewVideo = try c.decodeIfPresent(String.self, forKey: .previewVideo)
        videos = try c.decodeIfPresent([ArticleVideoItem].self, forKey: .videos)
        multiplePic = try c.decodeIfPresent([String].self, forKey: .multiplePic)
        coin = JSONFlex.int(c, .coin)
        originalCoin = JSONFlex.int(c, .originalCoin)
        length = JSONFlex.string(c, .length)
        vol = JSONFlex.int(c, .vol)
        size = try c.decodeIfPresent(String.self, forKey: .size)
        quality = try c.decodeIfPresent(String.self, forKey: .quality)
        likeNumber = JSONFlex.int(c, .likeNumber)
        collectionNumber = JSONFlex.int(c, .collectionNumber)
        views = JSONFlex.int(c, .views)
        downloadCount = JSONFlex.int(c, .downloadCount)
        shareNumber = JSONFlex.int(c, .shareNumber)
        isLike = JSONFlex.int(c, .isLike)
        isCollected = JSONFlex.int(c, .isCollected)
        tagList = try c.decodeIfPresent([ArticleDetailTag].self, forKey: .tagList)
        commentNumber =
            JSONFlex.int(c, .replyCounts)
            ?? JSONFlex.int(c, .commentNumber)
            ?? JSONFlex.int(c, .commentNum)
            ?? JSONFlex.int(c, .commentCount)
    }
}

struct ArticleDetailTag: Decodable, Identifiable, Hashable {
    let id: Int
    let slug: String?

    var displayName: String {
        let name = slug?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "标签 \(id)" : name
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
