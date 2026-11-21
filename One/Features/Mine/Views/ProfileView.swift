import SwiftUI

/// 已登录「我的」：顶图 + 资料区 + 喜欢 / 收藏 Tab。
struct ProfileView: View {
    let user: OneUser
    var onLogout: () -> Void

    @State private var libraryTab: LibraryTab = .likes

    private let bannerHeight: CGFloat = 220

    private enum LibraryTab: String, CaseIterable, Identifiable {
        case likes = "喜欢"
        case favorites = "收藏"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            profileBanner
            userSection
            libraryTabBar

            Group {
                switch libraryTab {
                case .likes:
                    MineLikesPanel()
                case .favorites:
                    MineFavoritesPanel()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
    }

    private var profileBanner: some View {
        Image("ProfileTopBackground")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: bannerHeight)
            .clipped()
            .accessibilityHidden(true)
    }

    private var userSection: some View {
        HStack(spacing: 14) {
            UserAvatarImage(path: user.avatarPath, size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline.weight(.semibold))
                Text(user.displayMobile)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button("退出", action: onLogout)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    private var libraryTabBar: some View {
        HStack(spacing: 0) {
            ForEach(LibraryTab.allCases) { tab in
                Button {
                    libraryTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(libraryTab == tab ? .semibold : .regular))
                        .foregroundStyle(libraryTab == tab ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(alignment: .bottom) {
                            if libraryTab == tab {
                                Capsule()
                                    .fill(Color.accentColor)
                                    .frame(height: 2)
                                    .padding(.horizontal, 24)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

}