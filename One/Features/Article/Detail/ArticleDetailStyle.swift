import Foundation

/// 标准文章详情的展示配置（阅读 / 写真漫画 / 电台 / 点播影视）。
struct ArticleDetailStyle: Hashable {
    var placeholderAspect: CGFloat
    var showsPlay: Bool
    var showsPreview: Bool
    var showsTags: Bool
    var showsDownloadCount: Bool

    /// 阅读：方图占位；无播放 / 预览 / 下载数。
    static let reading = ArticleDetailStyle(
        placeholderAspect: CoverAspect.square,
        showsPlay: false,
        showsPreview: false,
        showsTags: true,
        showsDownloadCount: false
    )

    /// 写真 / 漫画章节、电台：无播放 / 预览。
    static let content = ArticleDetailStyle(
        placeholderAspect: CoverAspect.landscape,
        showsPlay: false,
        showsPreview: false,
        showsTags: true,
        showsDownloadCount: true
    )

    /// 点播 / 影视：完整播放与预览。
    static let media = ArticleDetailStyle(
        placeholderAspect: CoverAspect.landscape,
        showsPlay: true,
        showsPreview: true,
        showsTags: true,
        showsDownloadCount: true
    )
}
