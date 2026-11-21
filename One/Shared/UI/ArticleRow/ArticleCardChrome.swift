import SwiftUI

/// 首页等「上文案、下封面」一体卡片：文案区毛玻璃 + 外缘统一圆角。
struct ArticleCardChrome<TextContent: View, CoverContent: View>: View {
    var cornerRadius: CGFloat = 8
    @ViewBuilder var text: () -> TextContent
    @ViewBuilder var cover: () -> CoverContent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            text()
                .articleCardTextBackdrop()
            cover()
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// 发现 / 点播等「上封面、下文案」：衬底与封面无缝衔接，外缘统一圆角。
struct ArticleCardChromeCoverTop<TextContent: View, CoverContent: View>: View {
    var cornerRadius: CGFloat = 8
    @ViewBuilder var cover: () -> CoverContent
    @ViewBuilder var text: () -> TextContent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cover()
            text()
                .articleCardTextBackdrop()
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// 首页日更分类名（居中一行）。
func articleCardCategoryTitle(_ title: String) -> some View {
    Text(title)
        .font(ArticleRowTypography.HomeFeedCard.category)
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
}

extension View {
    /// 列表卡片文案区的毛玻璃衬底（不改变块级排列，只加衬底与内边距）。
    func articleCardTextBackdrop(
        horizontal: CGFloat = 12,
        vertical: CGFloat = 10
    ) -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
            .background(.ultraThinMaterial)
    }
}