import SwiftUI

/// 详情可滚动正文：元信息 → 预览/评论 → 标签 → HTML。
struct ArticleDetailBodyView: View {
    let detail: ArticleDetail?
    let summary: ArticleSummary
    var style: ArticleDetailStyle = .media
    var canPlay: Bool = false
    var onPlay: (() -> Void)?
    var onCommentsTap: (() -> Void)?
    var onCollect: (() -> Void)?
    var onLike: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            metaSection

            if let detail {
                previewOrComments(detail)

                if style.showsTags, !detail.displayTags.isEmpty {
                    ArticleDetailTagList(
                        tags: detail.displayTags,
                        category: ContentCategory.forSearch(
                            modelID: summary.modelID,
                            seriesCategory: summary.seriesCategory
                        )
                    )
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
                style: style,
                canPlay: canPlay,
                onPlay: onPlay,
                onCollect: onCollect,
                onLike: onLike
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

    @ViewBuilder
    private func previewOrComments(_ detail: ArticleDetail) -> some View {
        if style.showsPreview {
            if !detail.galleryPaths.isEmpty || onCommentsTap != nil {
                ArticleMultiplePicGallery(
                    paths: detail.galleryPaths,
                    commentCount: detail.commentNumber,
                    onCommentsTap: onCommentsTap,
                    headerDate: style.dateInPreviewHeader
                        ? ArticleFormat.dateOnly(from: detail.publishedAt)
                        : nil
                )
            }
        } else if let onCommentsTap {
            Button(action: onCommentsTap) {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("评论")
                    Text(ArticleFormat.shortCount(detail.commentNumber ?? 0))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("评论 \(detail.commentNumber ?? 0)")
        }
    }
}
