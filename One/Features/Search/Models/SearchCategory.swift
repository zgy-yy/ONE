import Foundation

/// 搜索顶部分类（与 ONE `article/search` 的 model_id / series_category 一致）。
enum SearchCategory: String, CaseIterable, Identifiable, Hashable {
    case all
    case graphic
    case vod
    case reading
    case film
    case album
    case manga
    case radio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "全部"
        case .graphic: "图文"
        case .vod: "点播"
        case .reading: "阅读"
        case .film: "影视"
        case .album: "写真"
        case .manga: "漫画"
        case .radio: "电台"
        }
    }

    var modelID: Int {
        switch self {
        case .all: 0
        case .graphic: ArticleModelID.graphic
        case .vod: 6
        case .reading: ArticleModelID.reading
        case .film: ArticleModelID.film
        case .album, .manga: 4
        case .radio: ArticleModelID.radio
        }
    }

    var seriesCategory: Int {
        switch self {
        case .album: 1
        case .manga: 2
        default: 0
        }
    }

    var isSeries: Bool { seriesCategory > 0 }
}
