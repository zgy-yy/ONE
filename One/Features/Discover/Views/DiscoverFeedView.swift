import SwiftUI

/// 单个发现频道的文章列表。
struct DiscoverFeedView: View {
    let channel: DiscoverChannel
    @Bindable private var session = DiscoverSession.shared

    private var articles: [ArticleSummary] { session.articles(for: channel) }

    private var loadToken: String {
        "\(channel.rawValue)-\(session.feedFetchKey)"
    }

    var body: some View {
        Group {
            if session.isLoading(channel), articles.isEmpty {
                AppUI.loading("加载\(channel.title)…")
            } else if let error = session.error(for: channel), articles.isEmpty {
                AppUI.loadFailure(message: error) {
                    Task { await session.load(channel: channel, force: true) }
                }
            } else if articles.isEmpty {
                AppUI.emptyState(icon: "circle.slash", title: "无内容")
            } else {
                articleList
            }
        }
        .fillPage()
        .task(id: loadToken) { await session.load(channel: channel) }
    }

    private var articleList: some View {
        List {
            ForEach(articles) { article in
                articleRow(article)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background {
                        NavigationLink(value: article) { EmptyView() }
                            .opacity(0)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(.secondarySystemGroupedBackground))
                    .onAppear {
                        guard articles.last?.id == article.id else { return }
                        Task { await session.loadMore(channel: channel) }
                    }
            }
            listFooter
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var listFooter: some View {
        if session.isLoadingMore(channel) {
            ProgressView()
                .listFooterRow()
        } else if session.showsEndFooter(channel) {
            Text("没有更多了")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .listFooterRow()
        }
    }

    private func articleRow(_ article: ArticleSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            OneCoverImage(path: article.thumb)
            article.rowMeta
        }
        .padding(.vertical, 4)
    }
}
