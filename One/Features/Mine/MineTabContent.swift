import SwiftUI

/// 「我的」Tab：登录 / 资料 / 喜欢 / 收藏。
struct MineTabContent: View {
    @Bindable private var auth = AuthSession.shared

    var body: some View {
        NavigationStack {
            root
                .fillPage()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: MineLibraryPage.self) { page in
                    switch page {
                    case .likes: MyLikesView()
                    case .favorites: MyFavoritesView()
                    }
                }
                .libraryDetailDestinations()
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
