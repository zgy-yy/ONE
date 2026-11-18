import SwiftUI

/// 封面下方的固定元信息（片名、播放、价格、演职员、规格、统计）。
struct ArticleDetailMetaSection: View {
    let detail: ArticleDetail
    var canPlay: Bool = false
    var onPlay: (() -> Void)?

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
            DetailCastRow(detail: detail)
            DetailVideoSpecsRow(detail: detail)
            DetailMetricsRow(detail: detail)
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

// MARK: - 演员 + 发行

private struct DetailCastRow: View {
    let detail: ArticleDetail

    var body: some View {
        let actor = ArticleFormat.nonEmpty(detail.actor)
        let author = ArticleFormat.nonEmpty(detail.author)

        if actor != nil || author != nil {
            HStack(alignment: .center, spacing: 12) {
                if let actor {
                    ArticleDetailIconLabel(prefix: "演员", systemImage: "person.fill", text: actor, emphasized: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let author {
                    ArticleDetailIconLabel(prefix: "发行", systemImage: "building.2.fill", text: author)
                        .frame(maxWidth: .infinity, alignment: actor == nil ? .leading : .trailing)
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

// MARK: - 日期 / 收藏 / 下载 / 分享

private struct DetailMetricsRow: View {
    let detail: ArticleDetail

    private var items: [(icon: String, text: String)] {
        var list: [(String, String)] = []
        if let date = ArticleFormat.dateOnly(from: detail.publishedAt) {
            list.append(("calendar", date))
        }
        if let n = detail.collectionNumber {
            list.append(("heart", ArticleFormat.shortCount(n)))
        }
        if let n = detail.downloadCount {
            list.append(("arrow.down.circle", ArticleFormat.shortCount(n)))
        }
        if let n = detail.shareNumber {
            list.append(("square.and.arrow.up", ArticleFormat.shortCount(n)))
        }
        return list
    }

    var body: some View {
        if !items.isEmpty {
            HStack(spacing: 20) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    ArticleDetailIconLabel(systemImage: item.icon, text: item.text)
                        .monospacedDigit()
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}