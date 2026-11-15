import SwiftUI

/// 已登录用户资料 + 喜欢 / 收藏入口。
struct ProfileView: View {
    let user: OneUser
    var onLogout: () -> Void

    @Bindable private var library = MineLibrarySession.shared

    var body: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                accountIcons
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 12, trailing: 12))
            }

            Section("内容") {
                NavigationLink(value: MineLibraryPage.likes) {
                    Label("喜欢", systemImage: "heart.fill")
                }
                NavigationLink(value: MineLibraryPage.favorites) {
                    Label("收藏", systemImage: "star.fill")
                }
            }

            if let loggedAt = user.loggedAt?.nonEmpty {
                Section {
                    HStack {
                        Label("最近登录", systemImage: "clock")
                        Spacer()
                        Text(loggedAt)
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }

            Section {
                Button("退出登录", role: .destructive, action: onLogout)
            }
        }
        .task {
            await library.loadRecordCounts()
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            UserAvatarImage(path: user.avatarPath, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.title3.weight(.semibold))
                Text(user.displayMobile)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    /// 积分 / 钱包 / 等级 / VIP 做成一行图标。
    private var accountIcons: some View {
        HStack(spacing: 0) {
            accountIcon(system: "bitcoinsign.circle.fill", title: "积分", value: "\(user.integral ?? 0)")
            accountIcon(system: "yensign.circle.fill", title: "钱包", value: "\(user.wallet ?? 0)")
            accountIcon(system: "flame.fill", title: "活跃", value: "\(user.activeLevel ?? 0)")
            accountIcon(system: "crown.fill", title: "VIP", value: "\(user.vipLevel ?? 0)")
            if let counts = library.recordCounts {
                accountIcon(system: "gift.fill", title: "中奖", value: "\(counts.winRecordCount ?? 0)")
            }
        }
    }

    private func accountIcon(system: String, title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: system)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(height: 24)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
