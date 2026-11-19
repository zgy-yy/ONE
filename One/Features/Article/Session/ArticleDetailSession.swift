import Foundation
import Observation

/// 负责拉取一篇稿件的详情、播放地址，以及评论列表。
@MainActor
@Observable
final class ArticleDetailSession {
    private(set) var detail: ArticleDetail?
    private(set) var playURL: URL?
    private(set) var isLoading = false
    private(set) var error: String?

    private(set) var comments = PagedListState<CommentItem>(pageSize: 10)

    /// 评论排序：最新 `created_at` / 最热 `likes`。
    var commentSort: CommentSort = .createdAt {
        didSet {
            guard oldValue != commentSort else { return }
            comments.reset()
        }
    }

    private var loadedArticleID: Int?

    /// 播放页旋转返回可能导致详情 View 重建；用静态缓存避免重复打接口。
    private static var cache: [Int: Cached] = [:]

    private struct Cached {
        let detail: ArticleDetail
        let playURL: URL?
    }

    func load(articleID: Int) async {
        if loadedArticleID != articleID {
            comments.reset()
            commentSort = .createdAt
            loadedArticleID = articleID
        }

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

        // detail 固定走 token_one（见 TokensSession.oneToken / OneCredentials）
        do {
            let article = try await OneClient.articleDetail(articleID: articleID)
            let url = ArticlePlayURL.resolvedURL(detail: article, videoCDN: TokensSession.shared.oneVideoCDN)
            detail = article
            playURL = url
            Self.cache[articleID] = Cached(detail: article, playURL: url)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadComments(force: Bool = false) async {
        guard let articleID = loadedArticleID ?? detail?.id else { return }
        var feed = comments
        guard feed.beginLoad(force: force) else {
            comments = feed
            return
        }
        comments = feed

        do {
            feed.finishLoad(try await fetchComments(articleID: articleID, page: 1))
            comments = feed
        } catch {
            feed.failLoad(error.localizedDescription)
            comments = feed
        }
    }

    func loadMoreComments() async {
        guard let articleID = loadedArticleID ?? detail?.id else { return }
        var feed = comments
        guard let page = feed.beginLoadMore() else { return }
        comments = feed

        do {
            feed.finishLoadMore(try await fetchComments(articleID: articleID, page: page))
            comments = feed
        } catch {
            feed.cancelLoadMore()
            comments = feed
        }
    }

    private func fetchComments(articleID: Int, page: Int) async throws -> [CommentItem] {
        try await OneClient.commentList(
            targetID: articleID,
            type: CommentTargetType.article,
            page: page,
            size: 10,
            sorting: commentSort.rawValue
        )
    }

    func loadReplies(for comment: CommentItem) async -> [CommentItem] {
        guard let articleID = loadedArticleID ?? detail?.id else { return comment.replies }
        return await OneClient.commentReplies(
            targetID: articleID,
            type: CommentTargetType.article,
            parent: comment
        )
    }
}
