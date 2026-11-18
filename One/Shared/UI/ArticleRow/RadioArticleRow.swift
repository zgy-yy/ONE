import SwiftUI

/// 发现「电台」列表行：封面左上角电台标识 + 期数，封面底标题 + 播放；封面下作者 / 收藏 / 喜欢（无衬底）。
struct RadioArticleRow: View {
    let article: ArticleSummary

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
                if let vol = article.vol {
                    Text("第\(vol)期")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.black.opacity(0.45), in: Capsule())
            .padding(8)
        }
        .overlay(alignment: .bottom) {
            titleRow
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background { CoverBottomFade() }
        }
    }

    private var titleRow: some View {
        HStack(spacing: 10) {
            Text(article.displayTitle)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: ArticleRowActions.play) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
    }

    private var metaRow: some View {
        HStack(spacing: 14) {
            if let author = article.author?.nonEmpty {
                Text(author)
                    .lineLimit(1)
            }
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
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}
