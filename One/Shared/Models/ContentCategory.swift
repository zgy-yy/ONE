import CoreGraphics
import Foundation

/// App 公用内容分类（对齐接口 `model_id` / `series_category`）。
///
/// 用于：发现频道、搜索筛选、我的喜欢/收藏。
/// 每个分类对应唯一的 `modelID`；写真/漫画再用 `seriesCategory` 细分。
enum ContentCategory: String, CaseIterable, Identifiable, Hashable {
    case all
    case graphic
    case reading
    case vod
    case film
    case radio
    case album
    case manga

    /// 接口 `model_id` 数字约定（改一处全局生效）。
    enum ModelID {
        static let graphic = 1
        static let reading = 2
        static let film = 3
        /// 写真 / 漫画共用。
        static let series = 4
        static let radio = 5
        static let vod = 6
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "全部"
        case .graphic: "图文"
        case .reading: "阅读"
        case .vod: "点播"
        case .film: "影视"
        case .radio: "电台"
        case .album: "写真"
        case .manga: "漫画"
        }
    }

    /// 发现页频道（不含「全部」「点播」）。
    static var discoverCases: [ContentCategory] {
        [.graphic, .reading, .film, .radio, .album, .manga]
    }

    /// 接口 `model_id`（每类一个值）。
    var modelID: Int {
        switch self {
        case .all: 0
        case .graphic: ModelID.graphic
        case .reading: ModelID.reading
        case .film: ModelID.film
        case .album, .manga: ModelID.series
        case .radio: ModelID.radio
        case .vod: ModelID.vod
        }
    }

    /// 写真 = 1，漫画 = 2，其余 0。
    var seriesCategory: Int {
        switch self {
        case .album: 1
        case .manga: 2
        default: 0
        }
    }

    var isSeries: Bool { seriesCategory > 0 }

    /// 库列表等未专用 Row 时的封面比例（图文 4:3，其余 16:9）。
    var coverAspect: CGFloat {
        self == .graphic ? CoverAspect.fourThree : CoverAspect.landscape
    }

    /// 文章类发现接口的 `model_id`；系列频道为 `nil`。
    var articleModelID: Int? {
        switch self {
        case .graphic, .reading, .film, .radio: modelID
        default: nil
        }
    }

    /// 系列列表接口路径；非系列为 `nil`。
    var seriesListPath: String? {
        switch self {
        case .album: OneAPI.seriesAlbumListPath
        case .manga: OneAPI.seriesMangaListPath
        default: nil
        }
    }
}
