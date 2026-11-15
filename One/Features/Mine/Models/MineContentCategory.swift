import Foundation

/// 「我的」内页：喜欢 / 收藏。
enum MineLibraryPage: String, Hashable {
    case likes
    case favorites
}

/// 喜欢 / 收藏内容分类（接口 `model_id` / `series_category`）。
enum MineContentCategory: Int, CaseIterable, Identifiable, Hashable {
    case all = 0
    case image = 1
    case reading = 2
    case vod = 6
    case film = 3
    case radio = 5
    case album = 101
    case manga = 102

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .all: "全部"
        case .image: "图片"
        case .reading: "阅读"
        case .vod: "点播"
        case .film: "影视"
        case .radio: "电台"
        case .album: "写真"
        case .manga: "漫画"
        }
    }

    /// 文章类 `model_id`；写真 / 漫画为 0，靠 `seriesCategory` 区分。
    var modelID: Int {
        switch self {
        case .all, .album, .manga: 0
        case .image, .reading, .film, .radio, .vod: rawValue
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
}
