import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("首页", systemImage: "house.fill") {
                HomeTabContent()
            }
            Tab("影视", systemImage: "film.fill") {
                FilmTabContent()
            }
            Tab("点播", systemImage: "play.rectangle.fill") {
                OnDemandTabContent()
            }
        }
    }
}

private struct HomeTabContent: View {
    @State private var status = "点击拉取 Tokens"

    var body: some View {
        VStack(spacing: 12) {
            Text(status)
                .font(.footnote)
                .multilineTextAlignment(.center)
            Button("拉取 Tokens") {
                Task { await loadTokens() }
            }
        }
        .padding()
    }

    private func loadTokens() async {
        status = "请求中…"
        do {
            let result = try await TokensClient.fetch()
            let code = result.envelope.code.map(String.init) ?? "—"
            let msg = result.envelope.msg ?? ""
            print(result)
            status = "成功 code \(code) \(msg)，token \(result.tokens.count) 条"
        } catch {
            status = error.localizedDescription
        }
    }
}

private struct FilmTabContent: View {
    var body: some View {
        Text("影视")
            .padding()
    }
}

private struct OnDemandTabContent: View {
    var body: some View {
        Text("点播")
            .padding()
    }
}

#Preview {
    MainTabView()
}
