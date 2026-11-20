import SwiftUI

/// 单日内容页（嵌在首页横向分页里）。
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
        session.isDayPullRefreshing(day)
            || cache.isLoading
            || (!cache.loaded && cache.error == nil)
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
                    ArticleRowForModel.view(
                        for: article,
                        showsDate: false,
                        showsDescription: true
                    )
                        // 首页日更条目本身就是单篇（含图文 / 写真章节），直接进详情，不进系列列表。
                        .hiddenNavigationLink(value: article)
                        .styledListRow()
                        // 首页略宽：左右留白小于通用列表。
                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                }
            }
            .plainContentList()
        }
        .refreshable {
            await session.pullToRefresh(day)
        }
        .task(id: day.apiString) {
            session.prepareLoad(day)
            await session.load(day)
        }
    }
}
