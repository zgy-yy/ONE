import Foundation
import Observation

/// 文章详情 Session：业务详情 + 播放地址 + 评论 + 喜欢/收藏。
///
/// 喜欢/收藏走 `ArticleReactionStore`，与列表 Row 共享状态。
@MainActor
@Observable
final class ArticleDetailSession {
    private(set) var detail: ArticleDetail?
    private(set) var playURL: URL?
    private(set) var playURLEntries: [ArticlePlayURL.Entry] = []
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var isReacting = false
    private(set) var comments = PagedListState<CommentItem>(pageSize: 10)

    var commentSort: CommentSort = .createdAt {
        didSet {
            guard oldValue != commentSort else { return }
            comments.reset()
        }
    }

    private var loadedArticleID: Int?
    private var reactions: ArticleReactionStore { .shared }

    func load(articleID: Int) async {
        if loadedArticleID != articleID {
            comments.reset()
            commentSort = .createdAt
            loadedArticleID = articleID
        }

        // 同篇已成功则跳过（从播放页返回不重复刷）。
        if detail?.id == articleID, error == nil { return }
        guard !isLoading else { return }

        isLoading = true
        error = nil
        detail = nil
        playURL = nil
        playURLEntries = []
        defer { isLoading = false }

        do {
            // 业务详情（用户 token）与播放详情（token_one + dn）并行。
            async let business = OneClient.articleDetail(articleID: articleID)
            async let play = OneClient.articleDetailForPlay(articleID: articleID)

            var article = try await business
            reactions.merge(into: &article)
            detail = article
            applyPlayURLs(from: (try? await play) ?? article)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleLike() async { await toggleReaction(.like) }
    func toggleCollect() async { await toggleReaction(.collect) }

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
            feed.failLoad(error)
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

    func loadReplies(for comment: CommentItem) async -> [CommentItem] {
        guard let articleID = loadedArticleID ?? detail?.id else { return comment.replies }
        return await OneClient.commentReplies(
            targetID: articleID,
            type: CommentTargetType.article,
            parent: comment
        )
    }

    private func toggleReaction(_ kind: ArticleReactionStore.Kind) async {
        guard var article = detail, !isReacting else { return }
        isReacting = true
        defer { isReacting = false }

        await reactions.toggle(kind, articleID: article.id, seed: .init(article))
        reactions.apply(to: &article)
        detail = article
    }

    private func applyPlayURLs(from article: ArticleDetail) {
        let entries = ArticlePlayURL.allEntries(
            detail: article,
            apiBase: OneSession.shared.baseURL
        )
        playURLEntries = entries
        playURL = entries.first.flatMap { URL(string: $0.url) }
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
}
