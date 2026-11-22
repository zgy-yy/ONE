import SwiftUI

/// 封面下方的固定元信息（片名、播放、价格、演职员、规格、统计）。
struct ArticleDetailMetaSection: View {
    let summary: ArticleSummary
    let detail: ArticleDetail
    var style: ArticleDetailStyle = .media
    var canPlay: Bool = false
    var onPlay: (() -> Void)?
    var onCollect: (() -> Void)?
    var onLike: (() -> Void)?
    var onCommentsTap: (() -> Void)?

    private let rowSpacing: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            Text(detail.displayVideoName)
                .font(.title2.weight(.semibold))

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

            DetailPriceNumberRow(detail: detail)
            DetailCastRow(
                detail: detail,
                showsDate: style.dateBesidePublisher,
                dateBeforePublisher: style.dateBeforePublisher,
                volumeBesidePublisher: style.volumeBesidePublisher,
                spreadEdges: style.castSpreadEdges
            )
            DetailVideoSpecsRow(detail: detail, evenDistribution: style.evenVideoSpecs)
            DetailMetricsRow(
                article: summary,
                detail: detail,
                showsDownloadCount: style.showsDownloadCount,
                showsDate: !style.dateBesidePublisher && !style.dateInPreviewHeader && !style.dateBeforePublisher,
                splitEngagementRows: style.splitEngagementRows,
                spreadDownloadEngagement: style.spreadDownloadEngagement,
                commentsInMetricsRow: style.commentsInMetricsRow,
                onCollect: onCollect,
                onLike: onLike,
                onCommentsTap: onCommentsTap
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 价格 + 番号

private struct DetailPriceNumberRow: View {
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

// MARK: - 演员 + 出品

private struct DetailCastRow: View {
    let detail: ArticleDetail
    var showsDate = false
    var dateBeforePublisher = false
    var volumeBesidePublisher = false
    var spreadEdges = false

    var body: some View {
        let actor = ArticleFormat.nonEmpty(detail.actor)
        let author = ArticleFormat.nonEmpty(detail.author)
        let publisherDate = showsDate ? ArticleFormat.dateOnly(from: detail.publishedAt) : nil
        let leadingDate = dateBeforePublisher ? ArticleFormat.dateOnly(from: detail.publishedAt) : nil
        let vol = volumeBesidePublisher ? detail.vol : nil

        if volumeBesidePublisher {
            filmCastBlock(actor: actor, author: author, vol: vol)
        } else if dateBeforePublisher {
            contentCastBlock(actor: actor, author: author, date: leadingDate)
        } else if actor != nil || author != nil || publisherDate != nil {
            defaultCastRow(actor: actor, author: author, date: publisherDate)
        }
    }

    @ViewBuilder
    private func contentCastBlock(actor: String?, author: String?, date: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let actor {
                ArticleDetailIconLabel.actor(actor)
            }
            if date != nil || author != nil {
                HStack(alignment: .center, spacing: 12) {
                    if let date {
                        dateLabel(date)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let author {
                        ArticleDetailIconLabel.publisher(author)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func filmCastBlock(actor: String?, author: String?, vol: Int?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let actor {
                ArticleDetailIconLabel.actor(actor)
            }
            if vol != nil || author != nil {
                HStack(alignment: .center, spacing: 12) {
                    if let vol {
                        ArticleDetailIconLabel.volumeIssue(vol)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let author {
                        ArticleDetailIconLabel.publisher(author)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func defaultCastRow(actor: String?, author: String?, date: String?) -> some View {
        HStack(alignment: .center, spacing: 12) {
            if let actor {
                ArticleDetailIconLabel.actor(actor)
                    .frame(maxWidth: spreadEdges ? .infinity : nil, alignment: .leading)
            }
            if let author {
                ArticleDetailIconLabel.publisher(author)
                    .frame(
                        maxWidth: spreadEdges ? .infinity : nil,
                        alignment: spreadEdges ? .trailing : .leading
                    )
            }
            if let date {
                Spacer(minLength: 8)
                dateLabel(date)
            }
        }
    }

    private func dateLabel(_ date: String) -> some View {
        ArticleDetailIconLabel(systemImage: ArticleDetailSymbol.date, text: date)
    }
}

// MARK: - 时长 / 大小 / 分辨率

private struct DetailVideoSpecsRow: View {
    let detail: ArticleDetail
    var evenDistribution = false

    private var items: [(icon: String, text: String)] {
        var list: [(String, String)] = []
        if let v = ArticleFormat.nonEmpty(detail.length) { list.append((ArticleDetailSymbol.duration, v)) }
        if let v = ArticleFormat.nonEmpty(detail.size) { list.append((ArticleDetailSymbol.fileSize, v)) }
        if let v = ArticleFormat.nonEmpty(detail.quality) { list.append((ArticleDetailSymbol.quality, v)) }
        return list
    }

    var body: some View {
        if !items.isEmpty {
            HStack(spacing: evenDistribution ? 0 : 16) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    ArticleDetailIconLabel(systemImage: item.icon, text: item.text)
                        .frame(maxWidth: evenDistribution ? .infinity : nil, alignment: .center)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
    }
}

// MARK: - 互动与统计

private struct DetailMetricsRow: View {
    let article: ArticleSummary
    let detail: ArticleDetail
    var showsDownloadCount: Bool = true
    var showsDate: Bool = true
    var splitEngagementRows = false
    var spreadDownloadEngagement = false
    var commentsInMetricsRow = false
    var onCollect: (() -> Void)?
    var onLike: (() -> Void)?
    var onCommentsTap: (() -> Void)?

    var body: some View {
        if splitEngagementRows {
            VStack(alignment: .leading, spacing: 10) {
                filmStatsRow
                filmEngagementRow
            }
        } else if spreadDownloadEngagement {
            vodMetricsRow
        } else if commentsInMetricsRow {
            contentEngagementRow
        } else {
            inlineMetricsRow
        }
    }

    @ViewBuilder
    private var contentEngagementRow: some View {
        HStack(spacing: 20) {
            collectButton
            likeButton
            if let onCommentsTap {
                ArticleDetailCommentButton(count: detail.commentNumber ?? 0, action: onCommentsTap)
            }
        }
    }

    private var vodMetricsRow: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 16) {
                if showsDownloadCount, let n = detail.downloadCount {
                    statLabel(ArticleDetailSymbol.download, count: n)
                }
                if let n = detail.shareNumber {
                    statLabel(ArticleDetailSymbol.share, count: n)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                collectButton
                likeButton
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var inlineMetricsRow: some View {
        HStack(spacing: 20) {
            if showsDate, let date = ArticleFormat.dateOnly(from: detail.publishedAt) {
                ArticleDetailIconLabel(systemImage: ArticleDetailSymbol.date, text: date)
            }
            collectButton
            likeButton
            if showsDownloadCount, let n = detail.downloadCount {
                statLabel(ArticleDetailSymbol.download, count: n)
            }
            if let n = detail.shareNumber {
                statLabel(ArticleDetailSymbol.share, count: n)
            }
        }
    }

    private var filmStatsRow: some View {
        HStack(spacing: 16) {
            if let date = ArticleFormat.dateOnly(from: detail.publishedAt) {
                ArticleDetailIconLabel(systemImage: ArticleDetailSymbol.date, text: date)
            }
            Spacer(minLength: 8)
            if showsDownloadCount, let n = detail.downloadCount {
                statLabel(ArticleDetailSymbol.download, count: n)
            }
            if let n = detail.shareNumber {
                statLabel(ArticleDetailSymbol.share, count: n)
            }
        }
    }

    @ViewBuilder
    private var filmEngagementRow: some View {
        HStack(spacing: 20) {
            collectButton
            likeButton
            Spacer(minLength: 0)
            if let onCommentsTap {
                ArticleDetailCommentButton(count: detail.commentNumber ?? 0, action: onCommentsTap)
            }
        }
    }

    @ViewBuilder
    private var collectButton: some View {
        ArticleDetailEngagementButton(
            kind: .collect,
            article: article,
            detail: detail,
            action: onCollect
        )
    }

    @ViewBuilder
    private var likeButton: some View {
        ArticleDetailEngagementButton(
            kind: .like,
            article: article,
            detail: detail,
            action: onLike
        )
    }

    private func statLabel(_ symbol: String, count: Int) -> some View {
        ArticleDetailIconLabel(systemImage: symbol, text: ArticleFormat.shortCount(count))
            .monospacedDigit()
    }
}