import SwiftUI

/// 首页：左右滑动切换日期；点日期进当月 discovery。
struct HomeTabContent: View {
    @Bindable private var session = HomeSession.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HomeDayBar(
                    day: session.selectedDay,
                    topText: session.cache(for: session.selectedDay).topText
                )
                Divider()

                TabView(selection: $session.selectedDay) {
                    ForEach(session.days) { day in
                        HomeDayPage(day: day)
                            .tag(day)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .fillPage()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: DayDate.self) { day in
                HomeMonthArticlesView(day: day)
            }
            .navigationDestination(for: ArticleSummary.self) { article in
                ArticleDetailView(article: article)
            }
        }
    }
}

#Preview {
    HomeTabContent()
}
