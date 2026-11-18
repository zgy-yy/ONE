import SwiftUI

/// 单日内容页（嵌在左右滑动的 `TabView` 里）。
///
/// 翻页后本页先出现；未加载完时显示 loading，不挡切换手势。
struct HomeDayPage: View {
    let day: DayDate
    @Bindable private var session = HomeSession.shared

    private var cache: HomeDayCache {
        session.cache(for: day)
    }

    /// 尚未成功加载、也没有错误时，一律当 loading（避免先闪「暂无内容」）。
    private var showsLoading: Bool {
        cache.isLoading || (!cache.loaded && cache.error == nil)
    }

    var body: some View {
        AsyncPage(
            isLoading: showsLoading,
            error: cache.error,
            isEmpty: cache.articles.isEmpty,
            loadingTitle: "加载中…",
            emptyIcon: "sun.max",
            emptyTitle: "这一天暂无内容",
            retry: { Task { await session.load(day, force: true) } }
        ) {
            List {
                ForEach(cache.articles) { article in
                    VodArticleRow(article: article)
                        .hiddenNavigationLink(value: article)
                        .styledListRow()
                }
            }
            .plainContentList()
        }
        .task(id: day.apiString) {
            session.prepareLoad(day)
            await session.load(day)
        }
    }
}
