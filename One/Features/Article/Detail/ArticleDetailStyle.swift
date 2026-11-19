import Foundation

/// 标准文章详情的展示配置（按内容类型预设，初学者改 UI 只动这里）。
struct ArticleDetailStyle: Hashable {
    var placeholderAspect: CGFloat
    var showsPlay: Bool
    var showsPreview: Bool
    var showsTags: Bool
    var showsDownloadCount: Bool
    /// 日期放在「发行」右侧（影视 / 电台）。
    var dateBesidePublisher: Bool
    /// 演员靠左、发行靠右（点播）。
    var castSpreadEdges: Bool
    /// 日期放在「精彩预览」标题左侧（点播）。
    var dateInPreviewHeader: Bool

    /// 阅读。
    static let reading = ArticleDetailStyle(
        aspect: CoverAspect.square,
        play: false,
        preview: false,
        download: false
    )

    /// 写真 / 漫画章节。
    static let content = ArticleDetailStyle(play: false, preview: false)

    /// 电台：日期在发行右侧。
    static let radio = ArticleDetailStyle(
        play: false,
        preview: false,
        dateBesidePublisher: true
    )

    /// 影视：可播、无预览、日期在发行右侧。
    static let film = ArticleDetailStyle(
        play: true,
        preview: false,
        dateBesidePublisher: true
    )

    /// 点播：可播 + 预览；演员/发行分两侧；日期在预览标题左。
    static let media = ArticleDetailStyle(
        play: true,
        preview: true,
        castSpreadEdges: true,
        dateInPreviewHeader: true
    )

    private init(
        aspect: CGFloat = CoverAspect.landscape,
        play: Bool,
        preview: Bool,
        tags: Bool = true,
        download: Bool = true,
        dateBesidePublisher: Bool = false,
        castSpreadEdges: Bool = false,
        dateInPreviewHeader: Bool = false
    ) {
        self.placeholderAspect = aspect
        self.showsPlay = play
        self.showsPreview = preview
        self.showsTags = tags
        self.showsDownloadCount = download
        self.dateBesidePublisher = dateBesidePublisher
        self.castSpreadEdges = castSpreadEdges
        self.dateInPreviewHeader = dateInPreviewHeader
    }
}
