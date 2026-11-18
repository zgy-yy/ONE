import SwiftUI

/// 点播风列表行（发现非影视频道、首页日更也复用）：封面 + 衬底一体卡片。
///
/// 标题叠在封面底；下方金额 / 收藏按钮 / 喜欢 / 时长。
struct VodArticleRow: View {
    let article: ArticleSummary
    var aspectRatio: CGFloat = CoverAspect.landscape

    @Environment(\.colorScheme) private var colorScheme

    private let cornerRadius: CGFloat = 12

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            cover
            metaBar
        }
        .background {
            shape.fill(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.05))
        }
        .overlay {
            shape.strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.06), lineWidth: 1)
        }
        .clipShape(shape)
        .padding(.vertical, 2)
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
                .background { CoverBottomFade() }
        }
    }

    @ViewBuilder
    private var titleBlock: some View {
        if let author = article.author?.nonEmpty {
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
        HStack(alignment: .center, spacing: 14) {
            priceBlock
            Spacer(minLength: 0)
            Button(action: ArticleRowActions.favorite) {
                Image(systemName: "bookmark")
            }
            .buttonStyle(.plain)
            if let likes = article.likeNumber {
                Button(action: ArticleRowActions.like) {
                    MetaIconText(systemImage: "heart", text: "\(likes)")
                }
                .buttonStyle(.plain)
            }
            if let length = article.length?.nonEmpty {
                MetaIconText(systemImage: "clock", text: length)
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var priceBlock: some View {
        if article.coin != nil || article.originalCoin != nil {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let price = article.coin {
                    Text("¥\(price)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.orange)
                }
                if let original = article.originalCoin, original != article.coin {
                    Text("¥\(original)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
            }
        }
    }
}
