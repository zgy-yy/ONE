import Foundation
import Observation

/// 负责拉取一篇稿件的详情，并算出可播放 URL。
@MainActor
@Observable
final class ArticleDetailSession {
    private(set) var detail: ArticleDetail?
    private(set) var playURL: URL?
    private(set) var isLoading = false
    private(set) var error: String?

    /// 播放页旋转返回可能导致详情 View 重建；用静态缓存避免重复打接口。
    private static var cache: [Int: Cached] = [:]

    private struct Cached {
        let detail: ArticleDetail
        let playURL: URL?
    }

    func load(articleID: Int) async {
        if let cached = Self.cache[articleID] {
            detail = cached.detail
            playURL = cached.playURL
                ?? ArticlePlayURL.resolvedURL(detail: cached.detail, videoCDN: TokensSession.shared.oneVideoCDN)
            error = nil
            return
        }
        if detail?.id == articleID, error == nil { return }
        guard !isLoading else { return }

        isLoading = true
        error = nil
        detail = nil
        playURL = nil
        defer { isLoading = false }

        // detail 固定走 token_one（见 TokensSession.oneToken）
        guard let creds = OneCredentials.pair(tokenPath: OneAPI.detailPath) else {
            error = OneCredentials.readinessError
            return
        }

        do {
            let article = try await OneClient.articleDetail(
                base: creds.base,
                token: creds.token,
                articleID: articleID
            )
            let url = ArticlePlayURL.resolvedURL(detail: article, videoCDN: TokensSession.shared.oneVideoCDN)
            detail = article
            playURL = url
            Self.cache[articleID] = Cached(detail: article, playURL: url)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
