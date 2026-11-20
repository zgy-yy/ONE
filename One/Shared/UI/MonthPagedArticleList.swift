import SwiftUI

/// 按月分段文章列表：下拉刷新、月份滚动锚定、触底加载更多。
struct MonthPagedArticleList<SectionBody: View>: View {
    let sections: [ArticleMonthSection]
    let publishedAt: String
    let loadingMore: Bool
    let exhausted: Bool
    let onRefresh: @Sendable () async -> Void
    /// 锚定月不在当前分区里时（需 force 重载）。
    let onAnchorMonthMissing: () -> Void
    @ViewBuilder var sectionBody: (ArticleMonthSection) -> SectionBody

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(sections) { section in
                    Section {
                        sectionBody(section)
                    } header: {
                        ArticleMonthSectionHeader(monthAPIString: section.month)
                            .id(section.month)
                    }
                }
                Section {
                    AppUI.listLoadMoreFooter(loadingMore: loadingMore, exhausted: exhausted)
                }
            }
            .plainContentList(onRefresh: onRefresh)
            .onChange(of: publishedAt) { _, month in
                if sections.contains(where: { $0.month == month }) {
                    scrollToMonth(month, proxy: proxy)
                } else {
                    onAnchorMonthMissing()
                }
            }
        }
    }

    private func scrollToMonth(_ month: String, proxy: ScrollViewProxy) {
        guard sections.contains(where: { $0.month == month }) else { return }
        Task { @MainActor in
            proxy.scrollTo(month, anchor: .top)
        }
    }
}
