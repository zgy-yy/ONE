import SwiftUI

/// 单日内容页（嵌在左右滑动的 `TabView` 里）。
struct HomeDayPage: View {
    let day: DayDate
    @Bindable private var session = HomeSession.shared

    private var cache: HomeDayCache {
        session.cache(for: day)
    }

    var body: some View {
        AsyncPage(
            isLoading: cache.isLoading,
            error: cache.error,
            isEmpty: cache.articles.isEmpty,
            loadingTitle: "加载中…",
            emptyIcon: "sun.max",
            emptyTitle: "这一天暂无内容",
            retry: { Task { await session.load(day, force: true) } }
        ) {
            List {
                ForEach(cache.articles) { article in
                    ArticleListRow(article: article, showsAuthor: true)
                        .hiddenNavigationLink(value: article)
                        .styledListRow()
                }
            }
            .plainContentList()
        }
        .task(id: day.apiString) {
            await session.load(day)
        }
    }
}
