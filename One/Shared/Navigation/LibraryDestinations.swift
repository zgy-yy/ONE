import SwiftUI

extension View {
    /// 文章详情目的地。
    func articleDetailDestination() -> some View {
        navigationDestination(for: ArticleSummary.self) { ArticleDetailView(article: $0) }
    }

    /// 系列详情目的地。
    func seriesDetailDestination() -> some View {
        navigationDestination(for: SeriesSummary.self) { SeriesDetailView(series: $0) }
    }

    /// 文章 + 系列详情（搜索 / 我的 等库列表页）。
    func libraryDetailDestinations() -> some View {
        articleDetailDestination()
            .seriesDetailDestination()
    }

    /// 无系统右箭头的库条目跳转：系列或文章。
    @ViewBuilder
    func libraryNavigation(isSeries: Bool, article: ArticleSummary, series: SeriesSummary) -> some View {
        if isSeries {
            hiddenNavigationLink(value: series)
        } else {
            hiddenNavigationLink(value: article)
        }
    }
}
