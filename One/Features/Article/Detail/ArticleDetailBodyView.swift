import SwiftUI

/// 详情可滚动正文（元信息 → 可选预览/标签 → 正文）。
struct ArticleDetailBodyView: View {
    let detail: ArticleDetail?
    let summary: ArticleSummary
    var canPlay: Bool = false
    var showsPreview: Bool = true
    var showsTags: Bool = true
    var showsDownloadCount: Bool = true
    var onPlay: (() -> Void)?
    var onCommentsTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            metaSection

            if let detail {
                if showsPreview {
                    if !detail.galleryPaths.isEmpty || onCommentsTap != nil {
                        ArticleMultiplePicGallery(
                            paths: detail.galleryPaths,
                            commentCount: detail.commentNumber,
                            onCommentsTap: onCommentsTap
                        )
                    }
                } else if let onCommentsTap {
                    commentsEntry(count: detail.commentNumber, action: onCommentsTap)
                }

                if showsTags, !detail.displayTags.isEmpty {
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
            ArticleDetailMetaSection(
                detail: detail,
                canPlay: canPlay,
                showsDownloadCount: showsDownloadCount,
                onPlay: onPlay
            )
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(summary.displayTitle)
                    .font(.title2.weight(.semibold))
                if let author = summary.author?.nonEmpty {
                    Text(author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let publishedAt = summary.publishedAt?.nonEmpty {
                    Text(publishedAt)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func commentsEntry(count: Int?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: "bubble.left.and.bubble.right")
                Text("评论")
                Text(ArticleFormat.shortCount(count ?? 0))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("评论 \(count ?? 0)")
    }
}
