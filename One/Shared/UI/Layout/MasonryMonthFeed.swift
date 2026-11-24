import SwiftUI

// MARK: - 按月瀑布流列表

/// 月份标题 + 文章混排的 `ScrollView`（发现图文 / 首页月列表）。
struct MasonryMonthFeed<Footer: View, Card: View>: View {
    let sections: [ArticleMonthSection]
    var columns: Int = 2
    var gridSpacing: CGFloat = 10
    var stickyThreshold: CGFloat = 8
    var showsFloatingMonthBar = true
    var anchorMonth: String?
    var onAnchorMonthMissing: (() -> Void)?
    var onVisibleMonthChange: ((String?) -> Void)?
    @ViewBuilder var footer: () -> Footer
    @ViewBuilder var card: (ArticleSummary) -> Card

    @State private var floatingMonth: String?
    @State private var monthAnchors: [String: CGFloat] = [:]

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(sections) { section in
                            // 锚点须在 `LazyVStack` 直子层；标题仍放在瀑布流里。
                            Color.clear
                                .frame(height: 0)
                                .id(section.month)
                            MasonryLayout(columns: columns, spacing: gridSpacing) {
                                MasonryMonthLabel(monthAPIString: section.month)
                                ForEach(section.articles) { article in
                                    card(article)
                                }
                            }
                        }
                        footer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 16)
                }
                .coordinateSpace(name: MasonryMonthCoordinateSpace.name)
                .onPreferenceChange(MonthAnchorPreferenceKey.self) { anchors in
                    monthAnchors = anchors
                    publishVisibleMonth(
                        MasonryMonthSticky.visibleMonth(anchors: anchors, threshold: stickyThreshold)
                    )
                }

                if showsFloatingMonthBar,
                   let floatingMonth,
                   MasonryMonthSticky.shouldShowFloatingBar(
                    anchors: monthAnchors,
                    month: floatingMonth,
                    threshold: stickyThreshold
                   ) {
                    MasonryFloatingMonthBar(monthAPIString: floatingMonth)
                }
            }
            .onAppear {
                publishVisibleMonth(floatingMonth ?? sections.first?.month)
                scrollToAnchorMonth(anchorMonth, proxy: proxy)
            }
            .onChange(of: sections.map(\.month)) { _, _ in
                if monthAnchors.isEmpty {
                    publishVisibleMonth(floatingMonth ?? sections.first?.month)
                }
                scrollToAnchorMonth(anchorMonth, proxy: proxy)
            }
            .onChange(of: anchorMonth) { _, month in
                scrollToAnchorMonth(month, proxy: proxy)
            }
        }
    }

    private func publishVisibleMonth(_ month: String?) {
        floatingMonth = month
        onVisibleMonthChange?(month)
    }

    private func scrollToAnchorMonth(_ month: String?, proxy: ScrollViewProxy) {
        guard let month, !month.isEmpty else { return }
        if sections.contains(where: { $0.month == month }) {
            Task { @MainActor in
                await Task.yield()
                proxy.scrollTo(month, anchor: .top)
            }
        } else {
            onAnchorMonthMissing?()
        }
    }
}

// MARK: - 月份标签

/// 瀑布流里的橙色月份标题。
struct MasonryMonthLabel: View {
    let monthAPIString: String

    var body: some View {
        Text(MonthYear.sectionTitle(forAPIString: monthAPIString))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(MonthFeedStyle.titleColor)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, MonthFeedStyle.monthPadding)
            .monthAnchorTracking(monthAPIString: monthAPIString)
    }
}

private struct MasonryFloatingMonthBar: View {
    let monthAPIString: String

    var body: some View {
        Text(MonthYear.sectionTitle(forAPIString: monthAPIString))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(MonthFeedStyle.titleColor)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial)
    }
}

private enum MonthFeedStyle {
    static let titleColor = Color.orange
    static let monthPadding: CGFloat = 14
}

// MARK: - 滚动吸顶 / 锚点

private enum MasonryMonthCoordinateSpace {
    static let name = "masonryMonthScroll"
}

private struct MonthAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private enum MasonryMonthSticky {
    private static let floatHidePadding: CGFloat = 2

    static func visibleMonth(anchors: [String: CGFloat], threshold: CGFloat) -> String? {
        guard !anchors.isEmpty else { return nil }
        let crossed = anchors.filter { $0.value <= threshold }
        if let month = crossed.max(by: { $0.value < $1.value })?.key {
            return month
        }
        return anchors.min(by: { $0.value < $1.value })?.key
    }

    static func shouldShowFloatingBar(
        anchors: [String: CGFloat],
        month: String,
        threshold: CGFloat
    ) -> Bool {
        guard let y = anchors[month] else { return false }
        return y < threshold - floatHidePadding
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