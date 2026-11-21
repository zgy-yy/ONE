import Foundation

/// 评论相关接口。
extension OneClient {
    /// `comment/listV254`：`type` 1 文章 / 2 演员。
    static func commentList(
        targetID: Int,
        type: Int,
        page: Int,
        size: Int = 10,
        sorting: String = "likes"
    ) async throws -> [CommentItem] {
        let envelope = try await post(
            OneApiEnvelope<CommentListPayload>.self,
            path: OneAPI.commentListPath,
            data: [
                "article_id": String(targetID),
                "comment_id": "0",
                "page": String(page),
                "size": String(size),
                "type": String(type),
                "sorting": sorting,
            ]
        )
        return try unwrap(envelope)?.list ?? []
    }

    /// `comment/detailWithGroup`：按主楼 ID 分页拉回复。
    static func commentReplies(
        parent: CommentItem,
        sorting: String = "likes"
    ) async -> [CommentItem] {
        let parentID = parent.id
        let preview = parent.replies
        let expected = max(parent.replyCount ?? 0, preview.count)

        if expected > 0, preview.count >= expected { return preview }

        let pageSize = 20
        var all: [CommentItem] = []
        var seen = Set<Int>()
        var page = 1

        while page <= 15 {
            let list: [CommentItem]
            do {
                let envelope = try await post(
                    OneApiEnvelope<CommentListPayload>.self,
                    path: OneAPI.commentDetailWithGroupPath,
                    data: [
                        "comment_id": String(parentID),
                        "page": String(page),
                        "size": String(pageSize),
                        "sorting": sorting,
                    ]
                )
                list = try unwrap(envelope)?.list ?? []
            } catch {
                list = []
            }

            guard !list.isEmpty else { break }

            let batch = list.filter { item in
                item.id != parentID && seen.insert(item.id).inserted
            }
            all.append(contentsOf: batch)

            if expected > 0, all.count >= expected { break }
            if batch.isEmpty { break }
            page += 1
        }

        return all.count > preview.count ? all : preview
    }
}