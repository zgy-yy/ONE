import SwiftUI

/// 启动页：并行拉 Token 与 ONE 线路，成功后进入主界面。
struct EntryView: View {
    @Binding var enteredMain: Bool

    @Bindable private var tokensSession = TokensSession.shared
    @Bindable private var oneSession = OneSession.shared

    private var isBootstrapping: Bool {
        tokensSession.isLoading || oneSession.isLoading
    }

    private var showRetry: Bool {
        !isBootstrapping && (tokensSession.lastError != nil || oneSession.lastError != nil)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("One")
                .font(.largeTitle.bold())

            if isBootstrapping {
                ProgressView()
            }

            #if DEBUG
            VStack(spacing: 8) {
                Text(tokensSession.statusSummary)
                Text(oneSession.statusSummary)
            }
            .font(.footnote)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            #endif

            if showRetry {
                Button("重试") {
                    Task { await bootstrap(force: true) }
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .fillPage()
        .task { await bootstrap(force: false) }
        .onChange(of: tokensSession.isLoading) { _, _ in tryEnterMainIfReady() }
        .onChange(of: oneSession.isLoading) { _, _ in tryEnterMainIfReady() }
    }

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

    private func tryEnterMainIfReady() {
        guard !tokensSession.isLoading, !oneSession.isLoading else { return }
        let hasTokens = tokensSession.tokenOne != nil || tokensSession.tokenOneVisitor != nil
        guard hasTokens, oneSession.baseURL != nil else { return }
        withAnimation { enteredMain = true }
    }
}

#Preview {
    EntryView(enteredMain: .constant(false))
}
