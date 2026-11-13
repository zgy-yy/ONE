import Foundation
import Observation

/// 单篇稿件详情：拉 `article/detail` 并解析播放地址。
@MainActor
@Observable
final class ArticleDetailSession {
    private(set) var detail: ArticleDetail?
    private(set) var playURL: URL?
    private(set) var isLoading = false
    private(set) var error: String?

    func load(articleID: Int) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        detail = nil
        playURL = nil
        defer { isLoading = false }

        guard let creds = OneCredentials.pair(tokenPath: OneAPI.detailPath) else {
            error = OneCredentials.readinessError
            return
        }

        do {
            let article = try await OneClient.articleDetail(base: creds.base, token: creds.token, articleID: articleID)
            detail = article
            playURL = ArticlePlayURL.resolvedURL(detail: article, videoCDN: TokensSession.shared.oneVideoCDN)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
