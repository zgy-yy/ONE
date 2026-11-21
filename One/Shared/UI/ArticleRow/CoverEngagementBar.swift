import SwiftUI

/// 横图封面底栏：左播放量，右收藏 / 喜欢（暗色渐变上）。
struct CoverEngagementBar: View {
    let article: ArticleSummary
    var horizontalPadding: CGFloat = 12
    var verticalPadding: CGFloat = 8

    var body: some View {
        HStack(spacing: 10) {
            if let views = article.views {
                CoverStatLabel(icon: "eye", text: ArticleFormat.shortCount(views))
            }
            Spacer(minLength: 0)
            ArticleCollectLikeMeta(article: article, onDarkOverlay: true, itemSpacing: 6)
                .font(ArticleRowTypography.metaSmall)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity)
        .background { CoverBottomFade() }
    }
}

/// 封面叠字：图标 + 数字（浅白）。
struct CoverStatLabel: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(ArticleRowTypography.summary)
        .foregroundStyle(.white.opacity(0.9))
    }
}