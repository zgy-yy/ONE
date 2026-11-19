import SwiftUI

/// 封面下方的固定元信息（片名、播放、价格、演职员、规格、统计）。
struct ArticleDetailMetaSection: View {
    let detail: ArticleDetail
    var style: ArticleDetailStyle = .media
    var canPlay: Bool = false
    var onPlay: (() -> Void)?
    var onCollect: (() -> Void)?
    var onLike: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
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
                spreadEdges: style.castSpreadEdges
            )
            DetailVideoSpecsRow(detail: detail)
            DetailMetricsRow(
                detail: detail,
                showsDownloadCount: style.showsDownloadCount,
                showsDate: !style.dateBesidePublisher && !style.dateInPreviewHeader,
                onCollect: onCollect,
                onLike: onLike
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

// MARK: - 演员 + 发行（影视：日期在发行右；点播：演员/发行分两侧）

private struct DetailCastRow: View {
    let detail: ArticleDetail
    var showsDate = false
    var spreadEdges = false

    var body: some View {
        let actor = ArticleFormat.nonEmpty(detail.actor)
        let author = ArticleFormat.nonEmpty(detail.author)
        let date = showsDate ? ArticleFormat.dateOnly(from: detail.publishedAt) : nil

        if actor != nil || author != nil || date != nil {
            HStack(alignment: .center, spacing: 12) {
                if let actor {
                    ArticleDetailIconLabel(prefix: "演员", systemImage: "person.fill", text: actor, emphasized: true)
                        .frame(maxWidth: spreadEdges ? .infinity : nil, alignment: .leading)
                }
                if let author {
                    ArticleDetailIconLabel(prefix: "发行", systemImage: "building.2.fill", text: author)
                        .frame(
                            maxWidth: spreadEdges ? .infinity : nil,
                            alignment: spreadEdges ? .trailing : .leading
                        )
                }
                if let date {
                    Spacer(minLength: 8)
                    ArticleDetailIconLabel(systemImage: "calendar", text: date)
                }
            }
        }
    }
}

// MARK: - 时长 / 大小 / 分辨率

private struct DetailVideoSpecsRow: View {
    let detail: ArticleDetail

    private var items: [(icon: String, text: String)] {
        var list: [(String, String)] = []
        if let v = ArticleFormat.nonEmpty(detail.length) { list.append(("clock", v)) }
        if let v = ArticleFormat.nonEmpty(detail.size) { list.append(("internaldrive", v)) }
        if let v = ArticleFormat.nonEmpty(detail.quality) { list.append(("4k.tv", v)) }
        return list
    }

    var body: some View {
        if !items.isEmpty {
            HStack(spacing: 16) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    ArticleDetailIconLabel(systemImage: item.icon, text: item.text)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
    }
}

// MARK: - 日期 / 收藏 / 喜欢 / 下载 / 分享

private struct DetailMetricsRow: View {
    let detail: ArticleDetail
    var showsDownloadCount: Bool = true
    var showsDate: Bool = true
    var onCollect: (() -> Void)?
    var onLike: (() -> Void)?

    var body: some View {
        HStack(spacing: 20) {
            if showsDate, let date = ArticleFormat.dateOnly(from: detail.publishedAt) {
                ArticleDetailIconLabel(systemImage: "calendar", text: date)
            }

            reactionButton(
                systemImage: detail.hasCollected ? "bookmark.fill" : "bookmark",
                text: ArticleFormat.shortCount(detail.collectionNumber ?? 0),
                active: detail.hasCollected,
                action: onCollect
            )

            reactionButton(
                systemImage: detail.isLiked ? "heart.fill" : "heart",
                text: ArticleFormat.shortCount(detail.likeNumber ?? 0),
                active: detail.isLiked,
                action: onLike
            )

            if showsDownloadCount, let n = detail.downloadCount {
                ArticleDetailIconLabel(
                    systemImage: "arrow.down.circle",
                    text: ArticleFormat.shortCount(n)
                )
                .monospacedDigit()
            }

            if let n = detail.shareNumber {
                ArticleDetailIconLabel(
                    systemImage: "square.and.arrow.up",
                    text: ArticleFormat.shortCount(n)
                )
                .monospacedDigit()
            }
        }
    }

    @ViewBuilder
    private func reactionButton(
        systemImage: String,
        text: String,
        active: Bool,
        action: (() -> Void)?
    ) -> some View {
        let label = ArticleDetailIconLabel(systemImage: systemImage, text: text, active: active)
            .monospacedDigit()
        if let action {
            Button(action: action) { label }
                .buttonStyle(.plain)
        } else {
            label
        }
    }
}