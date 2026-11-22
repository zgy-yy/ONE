import SwiftUI

/// 「我的」Tab 根：`NavigationStack` + 登录态分发。
///
/// - 未登录 → `LoginView`
/// - 已登录 → `ProfileView`（喜欢 / 收藏 / 关注）
struct MineTabContent: View {
    @Bindable private var auth = AuthSession.shared

    var body: some View {
        NavigationStack {
            root
                .fillPage()
                .toolbar(.hidden, for: .navigationBar)
                .libraryDetailDestinations()
                .navigationDestination(for: CollectFolderRoute.self) {
                    CollectFolderDetailView(route: $0)
                }
                .navigationDestination(for: ActorSummary.self) {
                    ActorDetailView(actor: $0)
                }
        }
    }

    @ViewBuilder
    private var root: some View {
        if let user = auth.user, auth.isLoggedIn {
            ProfileView(user: user) { auth.logout() }
        } else {
            LoginView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

#Preview {
    MineTabContent()
}