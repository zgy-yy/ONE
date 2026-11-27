import SwiftUI

/// 封面互动叠层：右上播放量，左下收藏 / 喜欢（底部暗色渐变）。
struct CoverEngagementBar: View {
    let article: ArticleSummary
    var horizontalPadding: CGFloat = 12
    var verticalPadding: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                if let views = article.views {
                    CoverStatLabel(icon: "eye", text: ArticleFormat.shortCount(views))
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, verticalPadding)
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                ArticleCollectLikeMeta(article: article, onDarkOverlay: true, itemSpacing: 6)
                    .font(ArticleRowTypography.CoverBar.reactions)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity)
            .background { CoverBottomFade() }
        }
    }
}

/// 封面叠字：图标 + 数字（浅白）。
struct CoverStatLabel: View {
    let icon: String
    let text: String
    var font: Font = ArticleRowTypography.CoverBar.views

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(font)
        .foregroundStyle(.white.opacity(0.9))
    }
}
