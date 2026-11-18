import SwiftUI

/// 发现「图文」单元格：4:3 封面 + 日期（列表里每行放两个）。
struct GraphicArticleRow: View {
    let article: ArticleSummary

    var body: some View {
        VStack(spacing: 8) {
            OneCoverImage(
                path: article.thumb,
                aspectRatio: CoverAspect.fourThree,
                cornerRadius: 8
            )

            if let date = ArticleFormat.dateOnly(from: article.publishedAt) {
                Text(date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.vertical, 2)
    }
}
