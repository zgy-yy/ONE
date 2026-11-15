import SwiftUI

/// 点击首页日期后：竖图两列网格，按月分段，下滑加载更早月份。
/// 点击某一项回到首页对应发布日，而不是进文章详情。
struct HomeMonthArticlesView: View {
    let day: DayDate
    @State private var session: HomeMonthSession
    @Bindable private var homeSession = HomeSession.shared
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

    init(day: DayDate) {
        self.day = day
        _session = State(initialValue: HomeMonthSession(monthAPIString: day.monthAPIString))
    }

    var body: some View {
        AsyncPage(
            isLoading: session.isLoading,
            error: session.error,
            isEmpty: !session.hasContent,
            loadingTitle: "加载\(day.monthDisplayTitle)…",
            emptyIcon: "calendar",
            emptyTitle: "暂无内容",
            retry: { Task { await session.load(force: true) } }
        ) {
            articleGrid
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(day.monthDisplayTitle)
                    .font(.headline)
            }
        }
        .task {
            await session.load()
        }
    }

    private var articleGrid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
                ForEach(session.sections) { section in
                    Section {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(section.articles) { article in
                                Button {
                                    jumpToDay(for: article)
                                } label: {
                                    articleCard(article)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    guard session.sections.isTailArticle(article, in: section) else { return }
                                    Task { await session.loadMore() }
                                }
                            }
                        }
                    } header: {
                        ArticleMonthSectionHeader(monthAPIString: section.month, pinned: true)
                    }
                }

                AppUI.loadMoreFooter(
                    loadingMore: session.isLoadingMore,
                    exhausted: session.fullyExhausted && session.loaded
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    /// 用文章的 `published_at` 回到首页对应日。
    private func jumpToDay(for article: ArticleSummary) {
        guard let raw = article.publishedAt?.nonEmpty,
              let target = DayDate(apiString: raw)
        else { return }
        homeSession.jumpToDay(target)
        dismiss()
        Task { await homeSession.load(homeSession.selectedDay) }
    }

    private func articleCard(_ article: ArticleSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            OneCoverImage(
                path: article.thumb,
                aspectRatio: article.coverAspectRatio(fallbackModelID: ArticleModelID.graphic)
            )
            Text(article.displayTitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
