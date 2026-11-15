import SwiftUI

/// 演员详情：资料、可折叠简介、作品 / 写真 / 评论。
struct ActorDetailView: View {
    let actor: ActorSummary

    @State private var session = ActorDetailSession()
    @State private var descExpanded = false
    @State private var segment: ActorDetailSegment = .articles

    private let photoColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    private let articleColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

    var body: some View {
        Group {
            if session.isLoading, session.detail == nil {
                AppUI.loading("加载演员…")
            } else if let error = session.error, session.detail == nil {
                AppUI.loadFailure(message: error) {
                    Task { await session.load(actorID: actor.id) }
                }
            } else {
                contentScroll
            }
        }
        .fillPage()
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: ArticleSummary.self) { ArticleDetailView(article: $0) }
        .task(id: actor.id) {
            descExpanded = false
            segment = .articles
            await session.load(actorID: actor.id)
        }
        .onChange(of: segment) { _, value in
            Task { await session.loadSegment(value, actorID: actor.id) }
        }
    }

    private var contentScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                statsRow
                infoSection
                if let desc = session.detail?.displayDesc {
                    descSection(desc)
                }
                segmentPicker
                mediaSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            ActorAvatarImage(path: session.detail?.imagePath ?? actor.imagePath)
                .frame(width: 110)

            VStack(alignment: .leading, spacing: 6) {
                Text(session.detail?.displayName ?? actor.displayName)
                    .font(.title3.weight(.semibold))
                if let japanese = session.detail?.japaneseName?.nonEmpty {
                    Text(japanese).font(.subheadline).foregroundStyle(.secondary)
                }
                if let alias = session.detail?.aliasName?.nonEmpty {
                    Text(alias).font(.caption).foregroundStyle(.tertiary)
                }
                if let nickname = session.detail?.nickname?.nonEmpty {
                    Text("昵称 \(nickname)").font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            ForEach(ActorDetailSegment.allCases) { item in
                Button { segment = item } label: {
                    stat(item.rawValue, count(for: item), selected: segment == item)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func count(for segment: ActorDetailSegment) -> Int? {
        switch segment {
        case .articles: session.detail?.articleNum
        case .photos: session.detail?.photoNum
        case .comments: session.detail?.commentNum
        }
    }

    private func stat(_ title: String, _ value: Int?, selected: Bool) -> some View {
        VStack(spacing: 4) {
            Text("\(value ?? 0)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(selected ? Color.accentColor : Color.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(selected ? Color.accentColor : Color.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Info / Desc

    @ViewBuilder
    private var infoSection: some View {
        let rows = infoRows
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("资料").font(.headline)
                ForEach(rows, id: \.0) { title, value in
                    HStack(alignment: .firstTextBaseline) {
                        Text(title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 72, alignment: .leading)
                        Text(value)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var infoRows: [(String, String)] {
        var rows: [(String, String)] = []
        let d = session.detail
        if let v = d?.height?.nonEmpty { rows.append(("身高", "\(v) cm")) }
        if let v = d?.bustWaistHip?.nonEmpty { rows.append(("三围", v)) }
        if let v = d?.cupSize?.nonEmpty { rows.append(("罩杯", v)) }
        if let v = d?.birthDate?.nonEmpty { rows.append(("生日", v)) }
        if let v = d?.age?.nonEmpty { rows.append(("年龄", v)) }
        return rows
    }

    private func descSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("简介").font(.headline)
            Text(text)
                .font(.body)
                .lineLimit(descExpanded ? nil : 3)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(descExpanded ? "收起" : "展开全部") {
                withAnimation(.easeInOut(duration: 0.2)) { descExpanded.toggle() }
            }
            .font(.subheadline.weight(.medium))
        }
    }

    private var segmentPicker: some View {
        Picker("内容", selection: $segment) {
            ForEach(ActorDetailSegment.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Media

    @ViewBuilder
    private var mediaSection: some View {
        switch segment {
        case .articles: articlesSection
        case .photos: photosSection
        case .comments: commentsSection
        }
    }

    private var articlesSection: some View {
        AsyncSection(
            isLoading: session.articles.isLoading,
            error: session.articles.error,
            isEmpty: session.articles.isEmpty,
            loadingTitle: "加载作品…",
            emptyTitle: "暂无作品",
            retry: { Task { await session.retry(.articles, actorID: actor.id) } }
        ) {
            LazyVGrid(columns: articleColumns, spacing: 10) {
                ForEach(session.articles.items) { article in
                    NavigationLink(value: article) { articleCard(article) }
                        .buttonStyle(.plain)
                        .onAppear { loadMoreIfNeeded(article.id, in: .articles) }
                }
            }
            AppUI.loadMoreFooter(
                loadingMore: session.articles.isLoadingMore,
                exhausted: session.articles.exhausted
            )
        }
    }

    private func articleCard(_ article: ArticleSummary) -> some View {
        OneCoverImage(path: article.thumb)
            .overlay(alignment: .bottom) {
                Text(article.displayTitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background {
                        LinearGradient(
                            colors: [.black.opacity(0.65), .black.opacity(0)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var photosSection: some View {
        AsyncSection(
            isLoading: session.photos.isLoading,
            error: session.photos.error,
            isEmpty: session.photos.isEmpty,
            loadingTitle: "加载写真…",
            emptyTitle: "暂无写真",
            retry: { Task { await session.retry(.photos, actorID: actor.id) } }
        ) {
            LazyVGrid(columns: photoColumns, spacing: 8) {
                ForEach(session.photos.items) { photo in
                    ActorAvatarImage(path: photo.imagePath)
                        .onAppear { loadMoreIfNeeded(photo.id, in: .photos) }
                }
            }
            AppUI.loadMoreFooter(
                loadingMore: session.photos.isLoadingMore,
                exhausted: session.photos.exhausted
            )
        }
    }

    private var commentsSection: some View {
        AsyncSection(
            isLoading: session.comments.isLoading,
            error: session.comments.error,
            isEmpty: session.comments.isEmpty,
            loadingTitle: "加载评论…",
            emptyTitle: "暂无评论",
            retry: { Task { await session.retry(.comments, actorID: actor.id) } }
        ) {
            LazyVStack(alignment: .leading, spacing: 14) {
                ForEach(session.comments.items) { comment in
                    commentRow(comment)
                        .onAppear { loadMoreIfNeeded(comment.id, in: .comments) }
                }
                AppUI.loadMoreFooter(
                    loadingMore: session.comments.isLoadingMore,
                    exhausted: session.comments.exhausted
                )
            }
        }
    }

    private func commentRow(_ comment: CommentItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(comment.displayAuthor).font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                if let likes = comment.likes, likes > 0 {
                    Label("\(likes)", systemImage: "hand.thumbsup")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            if !comment.displayText.isEmpty {
                Text(comment.displayText)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let created = comment.createdAt?.nonEmpty {
                Text(created).font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func loadMoreIfNeeded(_ id: Int, in segment: ActorDetailSegment) {
        let isLast: Bool = switch segment {
        case .articles: session.articles.items.last?.id == id
        case .photos: session.photos.items.last?.id == id
        case .comments: session.comments.items.last?.id == id
        }
        guard isLast else { return }
        Task { await session.loadMore(segment, actorID: actor.id) }
    }
}
