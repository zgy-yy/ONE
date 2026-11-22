import SwiftUI

/// 已登录「我的」：顶图 + 毛玻璃账号卡 + 喜欢 / 收藏 / 关注 Tab。
struct ProfileView: View {
    let user: OneUser
    var onLogout: () -> Void

    @State private var libraryTab: LibraryTab = .likes

    private let bannerHeight: CGFloat = 152
    private let headerCorner: CGFloat = 20

    private enum LibraryTab: String, CaseIterable, Hashable {
        case likes = "喜欢"
        case favorites = "收藏"
        case followed = "关注"
    }

    var body: some View {
        VStack(spacing: 0) {
            profileHeader
            libraryTabBar

            Group {
                switch libraryTab {
                case .likes:
                    MineLikesPanel()
                case .favorites:
                    MineFavoritesPanel()
                case .followed:
                    MineFollowedActorsPanel()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
    }

    private var profileHeader: some View {
        ZStack(alignment: .bottom) {
            profileBannerBackground

            accountCard
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
    }

    /// 顶部装饰图（清晰展示；模糊仅用在账号卡 `ultraThinMaterial`）。
    private var profileBannerBackground: some View {
        Image("ProfileTopBackground")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: bannerHeight + headerCorner)
            .clipped()
            .accessibilityHidden(true)
    }

    private var accountCard: some View {
        HStack(alignment: .center, spacing: 14) {
            UserAvatarImage(path: user.avatarPath, size: 58)

            Text(user.displayName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("退出", action: onLogout)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemFill), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: headerCorner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: headerCorner, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    }

    private var libraryTabBar: some View {
        SlidingCapsuleSegmented(
            items: LibraryTab.allCases,
            title: \.rawValue,
            selection: $libraryTab
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}