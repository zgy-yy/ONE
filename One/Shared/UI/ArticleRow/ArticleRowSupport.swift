import SwiftUI

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
    var font: Font = .caption

    var body: some View {
        if let date = ArticleFormat.dateOnly(from: publishedAt) {
            Text(date)
                .font(font)
                .foregroundStyle(.tertiary)
        }
    }
}

/// 列表行收藏 / 喜欢 / 播放入口（待接真实接口）。
nonisolated enum ArticleRowActions {
    static func favorite() {}
    static func like() {}
    static func play() {}
}
