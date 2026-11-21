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

    /// 无系统右箭头的库条目跳转：系列或文章（适合 `List` 行）。
    @ViewBuilder
    func libraryNavigation(isSeries: Bool, article: ArticleSummary, series: SeriesSummary) -> some View {
        if isSeries {
            hiddenNavigationLink(value: series)
        } else {
            hiddenNavigationLink(value: article)
        }
    }

    /// 网格 / 卡片等：显式 `NavigationLink` 包裹内容（`ScrollView` 内 hidden link 常无效）。
    @ViewBuilder
    func libraryNavigationLink<Label: View>(
        isSeries: Bool,
        article: ArticleSummary,
        series: SeriesSummary,
        @ViewBuilder label: () -> Label
    ) -> some View {
        if isSeries {
            NavigationLink(value: series, label: label)
        } else {
            NavigationLink(value: article, label: label)
        }
    }
}
