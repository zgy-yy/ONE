import Foundation

/// 标准文章详情的展示配置（按内容类型预设，初学者改 UI 只动这里）。
struct ArticleDetailStyle: Hashable {
    var placeholderAspect: CGFloat
    var showsPlay: Bool
    var showsPreview: Bool
    var showsTags: Bool
    var showsDownloadCount: Bool
    /// 日期放在「出品」右侧（电台）。
    var dateBesidePublisher: Bool
    /// 演员靠左、出品靠右（点播）。
    var castSpreadEdges: Bool
    /// 日期放在「精彩预览」标题左侧（点播）。
    var dateInPreviewHeader: Bool
    /// 期数居左、出品居右（影视）。
    var volumeBesidePublisher: Bool
    /// 上：日期 + 下载/分享；下：收藏/喜欢/评论（影视）。
    var splitEngagementRows: Bool
    /// 下载/分享居左、收藏/喜欢居右（点播）。
    var spreadDownloadEngagement: Bool
    /// 时长 / 大小 / 分辨率均分一行（点播）。
    var evenVideoSpecs: Bool
    /// 日期居左、出品居右（写真 / 漫画）。
    var dateBeforePublisher: Bool
    /// 收藏 / 喜欢 / 评论同一行（写真 / 漫画）。
    var commentsInMetricsRow: Bool

    /// 阅读。
    static let reading = ArticleDetailStyle(
        aspect: CoverAspect.square,
        play: false,
        preview: false,
        download: false
    )

    /// 写真 / 漫画章节。
    static let content = ArticleDetailStyle(
        play: false,
        preview: false,
        download: false,
        dateBeforePublisher: true,
        commentsInMetricsRow: true
    )

    /// 电台：日期在出品右侧。
    static let radio = ArticleDetailStyle(
        play: false,
        preview: false,
        dateBesidePublisher: true
    )

    /// 影视：可播、无预览；期数左 / 出品右；统计分两行。
    static let film = ArticleDetailStyle(
        play: true,
        preview: false,
        volumeBesidePublisher: true,
        splitEngagementRows: true
    )

    /// 点播：可播 + 预览；演员/出品分两侧；日期在预览标题左。
    static let media = ArticleDetailStyle(
        play: true,
        preview: true,
        castSpreadEdges: true,
        dateInPreviewHeader: true,
        spreadDownloadEngagement: true,
        evenVideoSpecs: true
    )

    private init(
        aspect: CGFloat = CoverAspect.landscape,
        play: Bool,
        preview: Bool,
        tags: Bool = true,
        download: Bool = true,
        dateBesidePublisher: Bool = false,
        castSpreadEdges: Bool = false,
        dateInPreviewHeader: Bool = false,
        volumeBesidePublisher: Bool = false,
        splitEngagementRows: Bool = false,
        spreadDownloadEngagement: Bool = false,
        evenVideoSpecs: Bool = false,
        dateBeforePublisher: Bool = false,
        commentsInMetricsRow: Bool = false
    ) {
        self.placeholderAspect = aspect
        self.showsPlay = play
        self.showsPreview = preview
        self.showsTags = tags
        self.showsDownloadCount = download
        self.dateBesidePublisher = dateBesidePublisher
        self.castSpreadEdges = castSpreadEdges
        self.dateInPreviewHeader = dateInPreviewHeader
        self.volumeBesidePublisher = volumeBesidePublisher
        self.splitEngagementRows = splitEngagementRows
        self.spreadDownloadEngagement = spreadDownloadEngagement
        self.evenVideoSpecs = evenVideoSpecs
        self.dateBeforePublisher = dateBeforePublisher
        self.commentsInMetricsRow = commentsInMetricsRow
    }
}
