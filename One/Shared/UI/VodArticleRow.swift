import SwiftUI

/// 点播风列表行（发现非影视频道、首页日更也复用）：封面 + 衬底一体卡片。
///
/// 标题叠在封面底；下方金额 / 喜欢 / 时长。
struct VodArticleRow: View {
    let article: ArticleSummary
    var aspectRatio: CGFloat = CoverAspect.landscape
    var showsAuthor: Bool = false

    private let cornerRadius: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cover
            metaBar
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .padding(.vertical, 4)
    }

    private var cover: some View {
        OneCoverImage(
            path: article.thumb,
            aspectRatio: aspectRatio,
            cornerRadius: 0
        )
        .overlay(alignment: .bottom) {
            titleBlock
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
    }

    @ViewBuilder
    private var titleBlock: some View {
        if showsAuthor, let author = article.author?.nonEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(article.displayTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(author)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
        } else {
            Text(article.displayTitle)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
    }

    private var metaBar: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            priceBlock
            Spacer(minLength: 0)
            if let likes = article.likeNumber {
                Label("\(likes)", systemImage: "heart.fill")
            }
            if let length = article.length?.nonEmpty {
                Label(length, systemImage: "clock.fill")
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.primary)
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var priceBlock: some View {
        let price = article.coin?.nonEmpty
        let original = article.originalCoin?.nonEmpty
        if price != nil || original != nil {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let price {
                    Text("¥\(price)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                }
                if let original, original != price {
                    Text("¥\(original)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
            }
        }
    }
}
