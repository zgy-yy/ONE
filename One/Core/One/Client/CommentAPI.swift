import Foundation

/// 评论相关接口。
extension OneClient {
    /// `type=1` 文章 / `type=2` 演员。
    static func commentList(
        targetID: Int,
        type: Int,
        page: Int,
        size: Int = 10,
        sorting: String = "likes",
        commentID: Int = 0
    ) async throws -> [CommentItem] {
        try await postComments(
            path: OneAPI.commentListPath,
            targetID: targetID,
            type: type,
            page: page,
            size: size,
            sorting: sorting,
            commentID: commentID
        )
    }

    /// 展开楼中楼；失败则回退已有预览。
    static func commentReplies(
        targetID: Int,
        type: Int,
        parent: CommentItem
    ) async -> [CommentItem] {
        let list = (try? await postComments(
            path: OneAPI.commentListFullPath,
            targetID: targetID,
            type: type,
            page: 1,
            size: 10,
            sorting: "likes",
            commentID: parent.id
        )) ?? []
        let replies = list.first(where: { $0.id == parent.id })?.replies ?? []
        return replies.isEmpty ? parent.replies : replies
    }

    private static func postComments(
        path: String,
        targetID: Int,
        type: Int,
        page: Int,
        size: Int,
        sorting: String,
        commentID: Int
    ) async throws -> [CommentItem] {
        let envelope = try await post(
            OneApiEnvelope<CommentListPayload>.self,
            path: path,
            data: [
                "article_id": String(targetID),
                "comment_id": String(commentID),
                "page": String(page),
                "size": String(size),
                "type": String(type),
                "sorting": sorting,
            ]
        )
        return try unwrap(envelope)?.list ?? []
    }
}
