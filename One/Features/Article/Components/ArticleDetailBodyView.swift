import SwiftUI

/// 点播详情可滚动正文（元信息 → 预览标题行 → 标签 → 正文）。
struct ArticleDetailBodyView: View {
    let detail: ArticleDetail?
    let summary: ArticleSummary
    var canPlay: Bool = false
    var onPlay: (() -> Void)?
    var onCommentsTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            metaSection

            if let detail {
                // 无预览图时也保留标题行，方便点「评论」升起卡片
                if !detail.galleryPaths.isEmpty || onCommentsTap != nil {
                    ArticleMultiplePicGallery(
                        paths: detail.galleryPaths,
                        commentCount: detail.commentNumber,
                        onCommentsTap: onCommentsTap
                    )
                }
                if !detail.displayTags.isEmpty {
                    ArticleDetailTagList(tags: detail.displayTags)
                }
                if let html = detail.displayBody {
                    HTMLContentView(html: html)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var metaSection: some View {
        if let detail {
            ArticleDetailMetaSection(detail: detail, canPlay: canPlay, onPlay: onPlay)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(summary.displayTitle)
                    .font(.title2.weight(.semibold))
                if let author = summary.author, !author.isEmpty {
                    Text(author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let publishedAt = summary.publishedAt, !publishedAt.isEmpty {
                    Text(publishedAt)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
