import SwiftUI

/// 启动页：拉取 Token 与 ONE 线路，成功后进入主界面。
///
/// - `@Bindable`：配合 `@Observable` 类（如 `TokensSession`），属性变化时界面自动更新。
/// - `.task { }`：视图出现时执行一次异步任务（离开视图会取消）。
/// - `async let`：并行发起两个网络请求，再一起 `await` 等待完成。
struct EntryView: View {
    /// 与父视图 `ContentView` 双向绑定，用于切换到主界面。
    @Binding var enteredMain: Bool

    /// 全局单例，管理壳配置与 JWT（见 `TokensSession`）。
    @Bindable private var tokensSession = TokensSession.shared
    /// 全局单例，管理业务 API 基址（见 `OneSession`）。
    @Bindable private var oneSession = OneSession.shared

    /// 任一路径仍在加载时显示转圈。
    private var isBootstrapping: Bool {
        tokensSession.isLoading || oneSession.isLoading
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("One")
                .font(.largeTitle.bold())
            if isBootstrapping {
                ProgressView()
            }
            VStack(spacing: 8) {
                Text(tokensSession.statusSummary)
                Text(oneSession.statusSummary)
            }
            .font(.footnote)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            if showRetry {
                Button("重试") {
                    Task { await bootstrap(force: true) }
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .fillPage()
        .task {
            await bootstrap(force: false)
        }
        .onChange(of: tokensSession.isLoading) { _, _ in
            tryEnterMainIfReady()
        }
        .onChange(of: oneSession.isLoading) { _, _ in
            tryEnterMainIfReady()
        }
    }

    /// 加载结束且存在错误时显示重试按钮。
    private var showRetry: Bool {
        !isBootstrapping && (tokensSession.lastError != nil || oneSession.lastError != nil)
    }

    /// `force == false` 时若已有缓存可跳过；`true` 时强制重新请求。
    private func bootstrap(force: Bool) async {
        if force {
            async let tokens: Void = tokensSession.refresh()
            async let one: Void = oneSession.refresh()
            _ = await (tokens, one)
        } else {
            async let tokens: Void = tokensSession.prepare()
            async let one: Void = oneSession.prepare()
            _ = await (tokens, one)
        }
        tryEnterMainIfReady()
    }

    /// 两路都就绪：有 token 且 ONE 基址可用 → 动画进入主页。
    private func tryEnterMainIfReady() {
        guard !tokensSession.isLoading, !oneSession.isLoading else { return }
        let hasTokens = tokensSession.tokenOne != nil || tokensSession.tokenOneVisitor != nil
        guard hasTokens, oneSession.baseURL != nil else { return }
        withAnimation {
            enteredMain = true
        }
    }
}

#Preview {
    EntryView(enteredMain: .constant(false))
}
