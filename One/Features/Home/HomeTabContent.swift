import SwiftUI

/// 首页 Tab：展示 Token / ONE 线路状态，可手动重新拉取（调试用）。
///
/// 正式产品里首页通常是业务内容；这里保留网络状态方便学习排错。
struct HomeTabContent: View {
    @Bindable private var tokensSession = TokensSession.shared
    @Bindable private var oneSession = OneSession.shared

    var body: some View {
        VStack(spacing: 12) {
            Text(tokensSession.statusSummary)
                .font(.footnote)
                .multilineTextAlignment(.center)
            Text(oneSession.statusSummary)
                .font(.footnote)
                .multilineTextAlignment(.center)
            Button(tokensSession.isLoading || oneSession.isLoading ? "拉取中…" : "重新拉取") {
                Task {
                    async let tokens: Void = tokensSession.refresh()
                    async let one: Void = oneSession.refresh()
                    _ = await (tokens, one)
                }
            }
            .disabled(tokensSession.isLoading || oneSession.isLoading)
        }
        .padding()
    }
}

#Preview {
    HomeTabContent()
}
