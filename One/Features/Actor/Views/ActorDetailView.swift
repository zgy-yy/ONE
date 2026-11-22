import SwiftUI

/// 演员详情：大封面 + 导航栏标题；资料在昵称下；作品/写真/评论选项卡带 icon 与数量。
struct ActorDetailView: View {
    let actor: ActorSummary

    @State private var session: ActorDetailSession
    @State private var showsFullDesc = false
    @State private var segment: ActorDetailSegment = .articles
    @State private var photoViewerIndex: Int?
    @State private var photoViewerSelection = 0
    @State private var collectError: String?

    init(actor: ActorSummary, session: ActorDetailSession? = nil) {
        self.actor = actor
        _session = State(initialValue: session ?? ActorDetailSession())
    }

    private let photoColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    private let articleColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
    /// 详情封面宽度（竖图 3:4）。
    private let coverWidth: CGFloat = 160

    private var displayName: String {
        session.detail?.displayName ?? actor.displayName
    }

    var body: some View {
        DetailLoadGate(
            isLoading: session.isLoading,
            error: session.error,
            hasContent: session.detail != nil,
            loadingTitle: "加载演员…",
            retry: { Task { await session.load(actorID: actor.id) } }
        ) {
            contentScroll
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(displayName)
        .articleDetailDestination()
        .task(id: actor.id) {
            showsFullDesc = false
            segment = .articles
            guard session.detail?.id != actor.id else { return }
            await session.load(actorID: actor.id)
        }
        .sheet(isPresented: $showsFullDesc) {
            if let desc = session.detail?.displayDesc {
                descSheet(desc)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { photoViewerIndex != nil },
            set: { if !$0 { photoViewerIndex = nil } }
        )) {
            FullscreenImageViewer(
                paths: photoViewerPaths,
                selection: $photoViewerSelection
            )
        }
        .onChange(of: segment) { _, value in
            Task { await session.loadSegment(value, actorID: actor.id) }
        }
        .onChange(of: session.articleSort) { _, _ in
            Task { await session.loadSegment(.articles, actorID: actor.id) }
        }
        .alert("收藏失败", isPresented: .init(
            get: { collectError != nil },
            set: { if !$0 { collectError = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            if let collectError { Text(collectError) }
        }
    }

    private var contentScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if let desc = session.detail?.displayDesc {
                    descSection(desc)
                }
                segmentTabs
                mediaSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Header

    /// 详情大图 `thumb`；未加载完成时用列表带入的路径。
    private var headerCoverPath: String? {
        session.detail?.coverImagePath
            ?? ImagePath.full(thumb: actor.thumb, thumbnail: actor.thumbnail)
    }

    private var header: some View {
        ActorDetailProfileHeader(
            coverPath: headerCoverPath,
            coverWidth: coverWidth,
            fields: ActorProfileFields.make(detail: session.detail, actor: actor),
            showsCollect: session.detail != nil,
            isCollected: session.detail?.hasCollected == true,
            isCollecting: session.isCollecting,
            onCollect: { Task { await toggleActorCollect() } }
        )
    }

    private func toggleActorCollect() async {
        collectError = nil
        guard AuthSession.shared.isLoggedIn else {
            collectError = "请先登录"
            return
        }
        do {
            try await session.toggleCollect(actorID: actor.id)
        } catch {
            collectError = error.localizedDescription
        }
    }

    private func descSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("简介").font(.headline)
            Text(text)
                .font(.body)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("展开全部") {
                showsFullDesc = true
            }
            .font(.subheadline.weight(.medium))
        }
    }

    private func descSheet(_ text: String) -> some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .navigationTitle("简介")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { showsFullDesc = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Tabs

    private var segmentTabs: some View {
        ActorDetailSegmentTabs(segment: $segment, count: segmentCount)
    }

    private func segmentCount(_ segment: ActorDetailSegment) -> Int? {
        switch segment {
        case .articles: session.detail?.articleNum
        case .photos: session.detail?.photoNum
        case .comments: session.detail?.commentNum
        }
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ArticleSortPicker(sort: $session.articleSort)
                Spacer(minLength: 0)
            }

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
                            .onAppear {
                                guard session.articles.items.isLastItem(article) else { return }
                                Task { await session.loadMore(.articles, actorID: actor.id) }
                            }
                    }
                }
                AppUI.loadMoreFooter(
                    loadingMore: session.articles.isLoadingMore,
                    exhausted: session.articles.exhausted
                )
            }
        }
    }

    private func articleCard(_ article: ArticleSummary) -> some View {
        OneCoverImage(path: article.thumb, aspectRatio: CoverAspect.landscape)
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

    /// 全屏浏览用的原图路径列表（与网格顺序一致）。
    private var photoViewerPaths: [String] {
        session.photos.items.compactMap(\.fullImagePath)
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
                ForEach(Array(session.photos.items.enumerated()), id: \.element.id) { index, photo in
                    Button {
                        openPhotoViewer(at: index)
                    } label: {
                        ActorAvatarImage(path: photo.imagePath)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        guard session.photos.items.isLastItem(photo) else { return }
                        Task { await session.loadMore(.photos, actorID: actor.id) }
                    }
                }
            }
            AppUI.loadMoreFooter(
                loadingMore: session.photos.isLoadingMore,
                exhausted: session.photos.exhausted
            )
        }
    }

    private func openPhotoViewer(at index: Int) {
        let paths = photoViewerPaths
        guard !paths.isEmpty else { return }
        // 网格 index 与原图列表对齐（跳过没有路径的项）
        let photo = session.photos.items[index]
        guard let full = photo.fullImagePath,
              let viewerIndex = paths.firstIndex(of: full)
        else { return }
        photoViewerSelection = viewerIndex
        photoViewerIndex = viewerIndex
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
            VStack(alignment: .leading, spacing: 14) {
                ForEach(session.comments.items) { comment in
                    CommentRow(
                        comment: comment,
                        loadReplies: { parent, sort in
                            await session.loadReplies(for: parent, sorting: sort)
                        }
                    )
                        .onAppear {
                            guard session.comments.items.isLastItem(comment) else { return }
                            Task { await session.loadMore(.comments, actorID: actor.id) }
                        }
                }
                AppUI.loadMoreFooter(
                    loadingMore: session.comments.isLoadingMore,
                    exhausted: session.comments.exhausted
                )
            }
        }
    }
}

#Preview("演员详情") {
    let session = ActorDetailSession()
    session.configureForPreview(detail: PreviewSamples.Actor.detail)
    return NavigationStack {
        ActorDetailView(actor: PreviewSamples.Actor.summary, session: session)
    }
}
