import SwiftUI

/// 按月分段文章列表：月份滚动锚定、触底加载更多（下拉刷新由外层 `.refreshable`）。
struct MonthPagedArticleList<SectionBody: View>: View {
    let sections: [ArticleMonthSection]
    let publishedAt: String
    let loadingMore: Bool
    let exhausted: Bool
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
            .plainContentList()
            .onAppear {
                scrollToMonthIfPresent(publishedAt, proxy: proxy)
            }
            .onChange(of: sections.map(\.month)) { _, _ in
                scrollToMonthIfPresent(publishedAt, proxy: proxy)
            }
            .onChange(of: publishedAt) { _, month in
                scrollToMonthIfPresent(month, proxy: proxy)
            }
        }
    }

    private func scrollToMonthIfPresent(_ month: String, proxy: ScrollViewProxy) {
        guard sections.contains(where: { $0.month == month }) else {
            onAnchorMonthMissing()
            return
        }
        Task { @MainActor in
            await Task.yield()
            proxy.scrollTo(month, anchor: .top)
        }
    }
}
