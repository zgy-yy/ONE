import SwiftUI

/// 首页：左右滑动切换日期；点日期进当月 discovery。
///
/// 日期从左到右为旧→新；向右滑到「下一个」日期时先完成翻页，再在目标页显示 loading。
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
                // 选中变化时立刻进入 loading，不等页面 `.task` 才开始
                .onChange(of: session.selectedDay) { _, day in
                    session.prepareLoad(day)
                    Task { await session.load(day) }
                }
            }
            .fillPage()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: DayDate.self) { day in
                HomeMonthArticlesView(day: day)
            }
            .navigationDestination(for: ArticleSummary.self) { article in
                ArticleDetailView(article: article)
            }
            .task {
                session.prepareLoad(session.selectedDay)
                await session.load(session.selectedDay)
            }
        }
    }
}

#Preview {
    HomeTabContent()
}
