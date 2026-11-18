import SwiftUI

/// 发现「电台」：封面标识 + 底栏标题播放；下方作者 / 收藏 / 喜欢 / 日期。
struct RadioArticleRow: View {
    let article: ArticleSummary
    var showsDate: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            cover
            metaRow
        }
        .padding(.vertical, 2)
    }

    private var cover: some View {
        OneCoverImage(
            path: article.thumb,
            aspectRatio: CoverAspect.landscape,
            cornerRadius: 8
        )
        .overlay(alignment: .topLeading) {
            HStack(spacing: 4) {
                Image(systemName: "radio")
                if let vol = article.vol { Text("第\(vol)期") }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.black.opacity(0.45), in: Capsule())
            .padding(8)
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 10) {
                Text(article.displayTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .onTapGesture(perform: ArticleRowActions.play)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background { CoverBottomFade() }
        }
    }

    private var metaRow: some View {
        HStack(spacing: 14) {
            if let author = article.author?.nonEmpty {
                Text(author).lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "bookmark")
                .onTapGesture(perform: ArticleRowActions.favorite)
            if let likes = article.likeNumber {
                MetaIconText.likes(likes)
                    .onTapGesture(perform: ArticleRowActions.like)
            }
            if showsDate, let date = ArticleFormat.dateOnly(from: article.publishedAt) {
                Text(date)
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}
