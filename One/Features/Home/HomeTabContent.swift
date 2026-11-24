import SwiftUI

/// 首页：左右滑动切换日期；点日期进当月 discovery。
///
/// 日期从左到右为旧→新；向右滑到「下一个」日期时先完成翻页，再在目标页显示 loading。
/// 用横向分页 `ScrollView` 而不是 page `TabView`，避免子页被裁在 Tab 安全区之上。
struct HomeTabContent: View {
    @Bindable private var session = HomeSession.shared

    var body: some View {
        NavigationStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(session.days) { day in
                        HomeDayPage(day: day)
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(day)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: selectedDayScrollID)
            .fillPage()
            .safeAreaInset(edge: .top, spacing: 0) {
                HomeDayBar(
                    day: session.selectedDay,
                    topText: session.cache(for: session.selectedDay).topText
                )
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: DayDate.self) { day in
                HomeMonthArticlesView(day: day)
            }
            .libraryDetailDestinations()
            .onChange(of: session.selectedDay) { _, day in
                session.requestLoad(day)
            }
            .task {
                session.requestLoad(session.selectedDay)
            }
        }
    }

    /// `scrollPosition` 需要 `Optional` id。
    private var selectedDayScrollID: Binding<DayDate?> {
        Binding(
            get: { session.selectedDay },
            set: { newValue in
                guard let newValue, newValue != session.selectedDay else { return }
                session.selectedDay = newValue
            }
        )
    }
}

#Preview {
    HomeTabContent()
}
