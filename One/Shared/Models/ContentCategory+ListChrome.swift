import Foundation

extension ContentCategory {
    /// 首页日更作者行前缀（如「出品 / 张三」）。
    var homeAuthorPrefix: String? {
        switch self {
        case .vod, .film: "出品"
        case .reading: "文"
        case .album, .manga: "图"
        case .radio: "主播"
        default: nil
        }
    }

    /// 封面左上角角标用的 SF Symbol。
    var coverVolumeBadgeIcon: String {
        switch self {
        case .vod: "play.rectangle"
        case .reading: "book"
        case .film: "film"
        case .radio: "radio"
        case .album: "photo"
        case .manga: "books.vertical"
        case .graphic: "photo.on.rectangle.angled"
        default: "doc"
        }
    }
}

extension ArticleSummary {
    /// 列表展示用分类（含写真 / 漫画细分）。
    var listCategory: ContentCategory {
        ContentCategory.forSearch(modelID: modelID, seriesCategory: seriesCategory)
    }

    /// 首页日更作者文案：`前缀 / 姓名`。
    func homeAuthorLine() -> String? {
        guard let name = author?.nonEmpty else { return nil }
        guard let prefix = listCategory.homeAuthorPrefix else { return name }
        return "\(prefix) / \(name)"
    }
}