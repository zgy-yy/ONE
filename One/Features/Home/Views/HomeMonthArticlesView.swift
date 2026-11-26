import SwiftUI

/// 点击首页日期后：竖图两列 Masonry，按月分段，下滑加载更早月份。
/// 点击某一项回到首页对应发布日，而不是进文章详情。
struct HomeMonthArticlesView: View {
    let day: DayDate
    @State private var session: HomeMonthSession
    @State private var navigationMonthTitle: String
    @Bindable private var homeSession = HomeSession.shared
    @Environment(\.dismiss) private var dismiss

    init(day: DayDate) {
        self.day = day
        _session = State(initialValue: HomeMonthSession(monthAPIString: day.monthAPIString))
        _navigationMonthTitle = State(initialValue: day.monthDisplayTitle)
    }

    private var hasNoContent: Bool {
        !session.hasContent
    }

    var body: some View {
        AsyncPage(
            isLoading: session.isLoading,
            error: session.error,
            isEmpty: hasNoContent,
            loadingTitle: "加载\(day.monthDisplayTitle)…",
            emptyIcon: "calendar",
            emptyTitle: "暂无内容",
            retry: { Task { await session.load(force: true) } }
        ) {
            MasonryMonthFeed(
                sections: session.sections,
                onVisibleMonthChange: { monthAPI in
                    navigationMonthTitle = MonthYear.sectionTitle(forAPIString: monthAPI)
                }
            ) {
                loadMoreFooter
            } card: { article in
                Button {
                    jumpToDay(for: article)
                } label: {
                    HomeGraphicArticleView(article: article)
                }
                .buttonStyle(.plain)
            }
        }
        .refreshable {
            await session.pullToRefresh()
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(navigationMonthTitle)
                    .font(.headline)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: navigationMonthTitle)
            }
        }
        .task {
            await session.load()
        }
    }

    @ViewBuilder
    private var loadMoreFooter: some View {
        loadMoreSentinel
        AppUI.loadMoreFooter(
            loadingMore: session.isLoadingMore,
            exhausted: session.showsLoadMoreEnd
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    /// 真正滑到列表底部才触发加载更多。
    private var loadMoreSentinel: some View {
        Color.clear
            .frame(height: 1)
            .onAppear {
                Task { await session.loadMore() }
            }
    }

    /// 用文章的 `published_at` 回到首页对应日。
    private func jumpToDay(for article: ArticleSummary) {
        guard let raw = article.publishedAt?.nonEmpty,
              let target = DayDate(apiString: raw)
        else { return }
        homeSession.jumpToDay(target)
        dismiss()
    }
}
