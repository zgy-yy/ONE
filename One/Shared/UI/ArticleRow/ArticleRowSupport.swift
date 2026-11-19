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
    var active = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(active ? Color.orange : Color.secondary)
            Text(text)
                .foregroundStyle(active ? Color.primary : Color.secondary)
        }
    }

    static func likes(_ count: Int, active: Bool = false) -> MetaIconText {
        MetaIconText(
            systemImage: active ? "heart.fill" : "heart",
            text: ArticleFormat.shortCount(count),
            active: active
        )
    }

    static func likesText(_ raw: String, active: Bool = false) -> MetaIconText {
        let text = Int(raw).map(ArticleFormat.shortCount) ?? raw
        return MetaIconText(
            systemImage: active ? "heart.fill" : "heart",
            text: text,
            active: active
        )
    }

    static func collect(count: Int? = nil, active: Bool = false) -> MetaIconText {
        MetaIconText(
            systemImage: active ? "bookmark.fill" : "bookmark",
            text: count.map(ArticleFormat.shortCount) ?? "",
            active: active
        )
    }
}

/// 列表卡片共用：收藏 + 喜欢；与详情共用 `ArticleReactionStore`。
struct ArticleCollectLikeMeta: View {
    let article: ArticleSummary
    var showsCollectCount = false

    @Bindable private var reactions = ArticleReactionStore.shared

    var body: some View {
        let state = reactions.displayState(for: article)
        let busy = reactions.isBusy(article.id)
        let seed = ArticleReactionStore.State(article)

        HStack(spacing: 14) {
            Button {
                Task { await reactions.toggle(.collect, articleID: article.id, seed: seed) }
            } label: {
                if showsCollectCount {
                    MetaIconText.collect(count: state.collectionNumber, active: state.hasCollected)
                } else {
                    Image(systemName: state.hasCollected ? "bookmark.fill" : "bookmark")
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(state.hasCollected ? Color.orange : Color.secondary)
                }
            }
            .buttonStyle(.plain)
            .disabled(busy)

            Button {
                Task { await reactions.toggle(.like, articleID: article.id, seed: seed) }
            } label: {
                MetaIconText.likes(state.likeNumber, active: state.isLiked)
            }
            .buttonStyle(.plain)
            .disabled(busy)
        }
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
