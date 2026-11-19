import SwiftUI

/// 列表行文字层级（阅读 / 影视 / 点播 / 电台 / 系列共用）。
enum ArticleRowTypography {
    /// 主标题（信息列 / 封面叠字）。
    static let title: Font = .body.weight(.medium)
    /// 竖图卡片标题。
    static let cardTitle: Font = .caption.weight(.medium)
    /// 简介。
    static let summary: Font = .caption
    /// 作者 / 喜欢等 meta。
    static let meta: Font = .subheadline
    /// 更次要的 meta（系列状态等）。
    static let metaSmall: Font = .caption2
    /// 日期。
    static let date: Font = .caption
}

/// 图标 + 文案，列表 meta 共用。
struct MetaIconText: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
    }

    static func likes(_ count: Int) -> MetaIconText {
        MetaIconText(systemImage: "heart", text: ArticleFormat.shortCount(count))
    }

    static func likesText(_ raw: String) -> MetaIconText {
        let text = Int(raw).map(ArticleFormat.shortCount) ?? raw
        return MetaIconText(systemImage: "heart", text: text)
    }
}

/// 有值才显示的发布日（年月日）。
struct ArticleDateText: View {
    let publishedAt: String?
    var font: Font = ArticleRowTypography.date

    var body: some View {
        if let date = ArticleFormat.dateOnly(from: publishedAt) {
            Text(date)
                .font(font)
                .foregroundStyle(.tertiary)
        }
    }
}
