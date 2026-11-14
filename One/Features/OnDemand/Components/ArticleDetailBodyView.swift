import SwiftUI

/// 点播详情可滚动正文（元信息 → 预览 → 标签 → 正文）。
struct ArticleDetailBodyView: View {
    let detail: ArticleDetail?
    let summary: ArticleSummary
    var canPlay: Bool = false
    var onPlay: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            metaSection

            if let detail {
                if !detail.galleryPaths.isEmpty {
                    ArticleMultiplePicGallery(paths: detail.galleryPaths)
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
