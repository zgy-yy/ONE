import SwiftUI

/// 点播行：封面底标题（作者旁时长）；下方金额 / 收藏 / 喜欢 / 日期。
struct VodArticleRow: View {
    let article: ArticleSummary
    var aspectRatio: CGFloat = CoverAspect.landscape
    var showsDate: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // 封面（含 GIF）不抢手势，交给外层 `hiddenNavigationLink` 进详情。
            cover
                .allowsHitTesting(false)
            metaBar
        }
        .padding(.vertical, 2)
    }

    private var cover: some View {
        OneCoverImage(
            path: article.thumb,
            aspectRatio: aspectRatio,
            cornerRadius: 8
        )
        .overlay(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(article.displayTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if article.author?.nonEmpty != nil || article.length?.nonEmpty != nil {
                    HStack(spacing: 8) {
                        if let author = article.author?.nonEmpty {
                            Text(author).lineLimit(1)
                        }
                        if let length = article.length?.nonEmpty {
                            MetaIconText(systemImage: "clock", text: length)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { CoverBottomFade() }
        }
    }

    private var metaBar: some View {
        HStack(spacing: 14) {
            priceBlock
            Spacer(minLength: 0)
            Image(systemName: "bookmark")
                .onTapGesture(perform: ArticleRowActions.favorite)
            if let likes = article.likeNumber {
                MetaIconText.likes(likes)
                    .onTapGesture(perform: ArticleRowActions.like)
            }
            if showsDate, let date = ArticleFormat.dateOnly(from: article.publishedAt) {
                Text(date).foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
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
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
            }
        }
    }
}
