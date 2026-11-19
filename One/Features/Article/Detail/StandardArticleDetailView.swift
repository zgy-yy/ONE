import SwiftUI

/// 标准文章详情（阅读 / 写真漫画 / 电台 / 点播影视）：封面 + 正文配置 + 评论 sheet。
struct StandardArticleDetailView: View {
    let article: ArticleSummary
    let style: ArticleDetailStyle

    @State private var session = ArticleDetailSession()
    @State private var showsComments = false

    var body: some View {
        ArticleDetailChrome(article: article, session: session) {
            ArticleDetailScrollLayout(
                coverPath: session.detail?.thumb ?? article.thumb,
                placeholderAspect: style.placeholderAspect
            ) {
                ArticleDetailBodyView(
                    detail: session.detail,
                    summary: article,
                    canPlay: style.showsPlay && session.playURL != nil,
                    showsPreview: style.showsPreview,
                    showsTags: style.showsTags,
                    showsDownloadCount: style.showsDownloadCount,
                    onPlay: style.showsPlay
                        ? { if let url = session.playURL { ArticleVideoPresenter.present(url: url) } }
                        : nil,
                    onCommentsTap: { showsComments = true }
                )
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
        }
        .sheet(isPresented: $showsComments) {
            ArticleCommentsSheet(session: session, isPresented: $showsComments)
        }
    }
}
