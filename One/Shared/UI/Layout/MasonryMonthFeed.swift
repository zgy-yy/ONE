import SwiftUI

// MARK: - 按月瀑布流列表

/// 首页月列表：月份标题与文章混排，并将当前可见月份同步给导航栏。
struct MasonryMonthFeed<Footer: View, Card: View>: View {
    let sections: [ArticleMonthSection]
    let onVisibleMonthChange: (String) -> Void
    @ViewBuilder var footer: () -> Footer
    @ViewBuilder var card: (ArticleSummary) -> Card

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                MasonryLayout {
                    ForEach(masonryItems) { item in
                        switch item {
                        case .month(let month):
                            MasonryLayoutCell(kind: .month) {
                                MasonryMonthLabel(monthAPIString: month)
                            }
                        case .article(let article):
                            MasonryLayoutCell(kind: .article) {
                                card(article)
                            }
                        }
                    }
                }
                footer()
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
        }
        .coordinateSpace(name: MasonryMonthCoordinateSpace.name)
        .onChange(of: sections.first?.month, initial: true) { _, month in
            if let month {
                onVisibleMonthChange(month)
            }
        }
        .onPreferenceChange(MonthAnchorPreferenceKey.self) { anchors in
            if let month = visibleMonth(in: anchors) {
                onVisibleMonthChange(month)
            }
        }
    }

    private var masonryItems: [MasonryFeedItem] {
        sections.flatMap { section in
            [MasonryFeedItem.month(section.month)] + section.articles.map(MasonryFeedItem.article)
        }
    }

    private func visibleMonth(in anchors: [String: CGFloat]) -> String? {
        anchors.filter { $0.value <= 8 }.max(by: { $0.value < $1.value })?.key
            ?? anchors.min(by: { $0.value < $1.value })?.key
    }
}

// MARK: - 月份标签

/// 瀑布流里的橙色月份标题。
private struct MasonryMonthLabel: View {
    let monthAPIString: String

    var body: some View {
        Text(MonthYear.sectionTitle(forAPIString: monthAPIString))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.orange)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14)
            .monthAnchorTracking(monthAPIString: monthAPIString)
    }
}

// MARK: - 可见月份追踪

private enum MasonryMonthCoordinateSpace {
    static let name = "masonryMonthScroll"
}

private struct MonthAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private enum MasonryFeedItem: Identifiable {
    case month(String)
    case article(ArticleSummary)

    var id: String {
        switch self {
        case .month(let month): "month-\(month)"
        case .article(let article): "article-\(article.id)"
        }
    }
}

private extension View {
    func monthAnchorTracking(monthAPIString: String) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: MonthAnchorPreferenceKey.self,
                    value: [
                        monthAPIString: geometry.frame(
                            in: .named(MasonryMonthCoordinateSpace.name)
                        ).minY
                    ]
                )
            }
        }
    }
}
