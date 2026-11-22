import SwiftUI

// 列表卡片约定（初学者速览）：
// - `ArticleRow/*Row.swift`：发现页各体裁单行
// - `../Reactions/ArticleCollectLikeMeta.swift`：列表收藏 + 喜欢
// - `GraphicArticleCard` / `HomeGraphicArticleView`：图文竖卡（文案在 `GraphicCardTextBlock`）
// - `ArticleCardChrome`：毛玻璃文案 + 封面一体（首页日更横卡等）
// - `../Layout/MasonryLayout` + `MasonryMonthFeed`：两列瀑布流与按月列表

/// 列表行文字层级（阅读 / 影视 / 点播 / 电台 / 系列共用）。
enum ArticleRowTypography {
    /// 主标题（信息列 / 封面叠字）。
    static let title: Font = .body.weight(.medium)
    /// 影视行右侧标题（比 `title` 略小）。
    static let filmTitle: Font = .subheadline.weight(.medium)
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
    /// 横图封面角标「第 N 期」。
    static let coverVolume: Font = .system(size: 10, weight: .medium)

    /// 图文竖卡（首页瀑布流 / 发现图文）。
    enum GraphicCard {
        static let title = ArticleRowTypography.cardTitle
        static let author = ArticleRowTypography.metaSmall
        static let summary = ArticleRowTypography.summary
        static let views = ArticleRowTypography.summary
        static let reactions = ArticleRowTypography.metaSmall
        static let date = ArticleRowTypography.metaSmall
    }

    /// 首页日更横卡（毛玻璃文案区）。
    enum HomeFeedCard {
        static let category = ArticleRowTypography.metaSmall
        static let title = ArticleRowTypography.filmTitle
        static let body = ArticleRowTypography.summary
    }

    /// 横图封面底栏叠字。
    enum CoverBar {
        static let views = ArticleRowTypography.summary
        static let reactions = ArticleRowTypography.metaSmall
        static let volume = ArticleRowTypography.summary
    }
}

/// 横图封面左上角：品类图标 + 期数（影视 / 电台统一样式）。
struct CoverCategoryVolumeBadge: View {
    let systemImage: String
    let vol: Int?
    /// 为 `false` 时仅叠在封面上，无胶囊衬底（如「我的喜欢」）。
    var showsBackdrop: Bool = true

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(showsBackdrop ? 0 : 0.45), radius: 2, x: 0, y: 1)
            if let vol {
                Text("第\(vol)期")
                    .font(ArticleRowTypography.coverVolume)
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
        .padding(.horizontal, showsBackdrop ? 7 : 0)
        .padding(.vertical, showsBackdrop ? 4 : 0)
        .background {
            if showsBackdrop {
                Capsule().fill(.black.opacity(0.32))
            }
        }
        .padding(8)
    }
}

/// 图标 + 文案，列表 meta 共用。
struct MetaIconText: View {
    let systemImage: String
    let text: String
    var active = false
    var isLoading = false
    /// 封面暗色渐变上：未点亮用白字，不用灰色。
    var onDarkOverlay = false

    private let iconSlotWidth: CGFloat = 14

    var body: some View {
        HStack(spacing: 4) {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(onDarkOverlay ? .white : nil)
                } else {
                    Image(systemName: systemImage)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(active ? Color.orange : inactiveColor)
                }
            }
            .frame(width: iconSlotWidth, height: iconSlotWidth, alignment: .center)
            Text(text)
                .lineLimit(1)
                .foregroundStyle(active ? activeTextColor : inactiveColor)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var inactiveColor: Color {
        onDarkOverlay ? Color.white.opacity(0.92) : Color.secondary
    }

    private var activeTextColor: Color {
        onDarkOverlay ? Color.white : Color.primary
    }

    static func likes(
        _ count: Int,
        active: Bool = false,
        isLoading: Bool = false,
        onDarkOverlay: Bool = false
    ) -> MetaIconText {
        MetaIconText(
            systemImage: active ? "heart.fill" : "heart",
            text: ArticleFormat.shortCount(count),
            active: active,
            isLoading: isLoading,
            onDarkOverlay: onDarkOverlay
        )
    }

    static func likesText(
        _ raw: String,
        active: Bool = false,
        isLoading: Bool = false,
        onDarkOverlay: Bool = false
    ) -> MetaIconText {
        let text = Int(raw).map(ArticleFormat.shortCount) ?? raw
        return MetaIconText(
            systemImage: active ? "heart.fill" : "heart",
            text: text,
            active: active,
            isLoading: isLoading,
            onDarkOverlay: onDarkOverlay
        )
    }

    static func collect(
        count: Int? = nil,
        active: Bool = false,
        isLoading: Bool = false,
        onDarkOverlay: Bool = false
    ) -> MetaIconText {
        MetaIconText(
            systemImage: active ? "bookmark.fill" : "bookmark",
            text: count.map(ArticleFormat.shortCount) ?? "",
            active: active,
            isLoading: isLoading,
            onDarkOverlay: onDarkOverlay
        )
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
