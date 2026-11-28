import SwiftUI

/// 详情页共用控件；各内容类型在自己的 Detail 文件里组合排版。
struct ArticleDetailTitle: View {
    let detail: ArticleDetail

    var body: some View {
        Text(detail.displayVideoName)
            .font(.title2.weight(.semibold))
    }
}

struct ArticleDetailPlayDownloadRow: View {
    let canPlay: Bool
    let videoDownloadOptions: [ArticlePlayURL.DownloadOption]
    var onPlay: (() -> Void)?
    var onPickDownload: ((ArticlePlayURL.DownloadOption) -> Void)?

    @State private var showsDownloadQualityPicker = false

    private var showsDownloadButton: Bool {
        onPickDownload != nil && !videoDownloadOptions.isEmpty
    }

    var body: some View {
        if onPlay != nil || showsDownloadButton {
            HStack(spacing: 12) {
                if let onPlay {
                    Button(action: onPlay) {
                        Label("播放", systemImage: "play.fill")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(!canPlay)
                    .opacity(canPlay ? 1 : 0.45)
                }

                if showsDownloadButton {
                    downloadButton
                }
            }
        }
    }

    private var downloadButton: some View {
        Button {
            showsDownloadQualityPicker = true
        } label: {
            Label("下载", systemImage: "arrow.down.circle")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .confirmationDialog(
            "选择下载清晰度",
            isPresented: $showsDownloadQualityPicker,
            titleVisibility: .visible
        ) {
            ForEach(videoDownloadOptions) { option in
                Button(option.title) {
                    onPickDownload?(option)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("原画体积更大；标清更省空间。")
        }
    }
}

struct ArticleDetailPriceNumberRow: View {
    let detail: ArticleDetail

    var body: some View {
        let number = ArticleFormat.nonEmpty(detail.number)
        let current = detail.coin
        let original = detail.originalCoin
        let showsPrice = current != nil || original != nil

        if number != nil || showsPrice {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                if showsPrice {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        if let current {
                            Text("¥\(current)")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.orange)
                        }
                        if let original, original != current {
                            HStack(spacing: 4) {
                                Text("原价")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Text("¥\(original)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .strikethrough(true, color: .secondary)
                            }
                        }
                    }
                }
                Spacer(minLength: 8)
                if let number {
                    Text(number)
                        .font(.subheadline.weight(.medium))
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
        }
    }
}

struct ArticleDetailDateLabel: View {
    let date: String

    var body: some View {
        ArticleDetailIconLabel(systemImage: ArticleDetailSymbol.date, text: date)
    }
}

/// 时长 / 大小 / 分辨率：固定从左依次排列。
struct ArticleDetailVideoSpecsRow: View {
    let detail: ArticleDetail

    private var items: [(icon: String, text: String)] {
        var list: [(String, String)] = []
        if let value = ArticleFormat.nonEmpty(detail.length) {
            list.append((ArticleDetailSymbol.duration, value))
        }
        if let value = ArticleFormat.nonEmpty(detail.size) {
            list.append((ArticleDetailSymbol.fileSize, value))
        }
        if let value = ArticleFormat.nonEmpty(detail.quality) {
            list.append((ArticleDetailSymbol.quality, value))
        }
        return list
    }

    var body: some View {
        if !items.isEmpty {
            HStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    ArticleDetailIconLabel(systemImage: item.icon, text: item.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
    }
}

struct ArticleDetailCollectLikeRow: View {
    let article: ArticleSummary
    let detail: ArticleDetail
    var onCollect: (() -> Void)?
    var onLike: (() -> Void)?

    var body: some View {
        HStack(spacing: 20) {
            ArticleDetailEngagementButton(
                kind: .collect,
                article: article,
                detail: detail,
                action: onCollect
            )
            ArticleDetailEngagementButton(
                kind: .like,
                article: article,
                detail: detail,
                action: onLike
            )
        }
    }
}

struct ArticleDetailDownloadShareStats: View {
    let detail: ArticleDetail
    var showsDownload = true

    var body: some View {
        HStack(spacing: 16) {
            if showsDownload, let count = detail.downloadCount {
                statLabel(ArticleDetailSymbol.download, count: count)
            }
            if let count = detail.shareNumber {
                statLabel(ArticleDetailSymbol.share, count: count)
            }
        }
    }

    private func statLabel(_ symbol: String, count: Int) -> some View {
        ArticleDetailIconLabel(systemImage: symbol, text: ArticleFormat.shortCount(count))
            .monospacedDigit()
    }
}

struct ArticleDetailCommentRow: View {
    let count: Int?
    let action: () -> Void

    var body: some View {
        HStack {
            ArticleDetailCommentButton(count: count ?? 0, action: action)
            Spacer(minLength: 0)
        }
    }
}

struct ArticleDetailSupplementaryContent: View {
    let summary: ArticleSummary
    let detail: ArticleDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !detail.displayTags.isEmpty {
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
}
