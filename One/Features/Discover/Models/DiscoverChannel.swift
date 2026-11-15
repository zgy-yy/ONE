import Foundation

/// 发现页频道：文章类走 `article/discovery`，写真/漫画走系列列表接口。
enum DiscoverChannel: String, CaseIterable, Identifiable, Hashable {
    case graphic
    case reading
    case film
    case radio
    case album
    case manga

    var id: String { rawValue }

    var title: String {
        switch self {
        case .graphic: "图文"
        case .reading: "阅读"
        case .film: "影视"
        case .radio: "电台"
        case .album: "写真"
        case .manga: "漫画"
        }
    }

    /// 文章频道的 `model_id`；系列频道为 `nil`。
    var articleModelID: Int? {
        switch self {
        case .graphic: 1
        case .reading: 2
        case .film: 3
        case .radio: 5
        case .album, .manga: nil
        }
    }

    var isSeries: Bool {
        self == .album || self == .manga
    }

    /// 系列列表接口路径；非系列频道为 `nil`。
    var seriesListPath: String? {
        switch self {
        case .album: OneAPI.seriesAlbumListPath
        case .manga: OneAPI.seriesMangaListPath
        default: nil
        }
    }
}
