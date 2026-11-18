import SwiftUI

/// 点击首页日期后：竖图两列网格，按月分段，下滑加载更早月份。
/// 点击某一项回到首页对应发布日，而不是进文章详情。
struct HomeMonthArticlesView: View {
    let day: DayDate
    @State private var session: HomeMonthSession
    @Bindable private var homeSession = HomeSession.shared
    @Environment(\.dismiss) private var dismiss

    private let gridSpacing: CGFloat = 10

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
            // 只用一层 LazyVStack：嵌套 LazyVGrid 会在中段滑动时回跳、复用错乱。
            LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
                ForEach(session.sections) { section in
                    Section {
                        sectionRows(section)
                    } header: {
                        ArticleMonthSectionHeader(monthAPIString: section.month, pinned: true)
                    }
                }

                loadMoreSentinel
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

    /// 两列用固定 `HStack` 行，避免 `LazyVGrid` 预取导致中段回跳。
    private func sectionRows(_ section: ArticleMonthSection) -> some View {
        let rows = section.articles.chunked(into: 2)
        return VStack(spacing: gridSpacing) {
            ForEach(rows, id: \.rowID) { row in
                HStack(alignment: .top, spacing: gridSpacing) {
                    ForEach(row) { article in
                        Button {
                            jumpToDay(for: article)
                        } label: {
                            articleCard(article)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    if row.count == 1 {
                        Color.clear
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
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
        Task { await homeSession.load(homeSession.selectedDay) }
    }

    private func articleCard(_ article: ArticleSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            OneCoverImage(
                path: article.thumb,
                aspectRatio: CoverAspect.portrait
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

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0, !isEmpty else { return [] }
        var result: [[Element]] = []
        result.reserveCapacity((count + size - 1) / size)
        var index = startIndex
        while index < endIndex {
            let next = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            result.append(Array(self[index..<next]))
            index = next
        }
        return result
    }
}

private extension Array where Element == ArticleSummary {
    var rowID: Int { first?.id ?? 0 }
}
