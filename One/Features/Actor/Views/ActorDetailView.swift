import SwiftUI

/// 演员详情：大封面 + 导航栏标题；资料在昵称下；作品/写真/评论选项卡带 icon 与数量。
struct ActorDetailView: View {
    let actor: ActorSummary

    @State private var session = ActorDetailSession()
    @State private var showsFullDesc = false
    @State private var segment: ActorDetailSegment = .articles
    @State private var photoViewerIndex: Int?
    @State private var photoViewerSelection = 0

    private let photoColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    private let articleColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
    /// 详情封面宽度（竖图 3:4，再大一点更醒目）。
    private let coverWidth: CGFloat = 176

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

    private var header: some View {
        LeadingMediaHeader(mediaWidth: coverWidth) {
            // 详情用原图 thumb，比列表 thumbnail 更清晰
            ActorAvatarImage(
                path: session.detail?.coverImagePath
                    ?? ImagePath.full(thumb: actor.thumb, thumbnail: actor.thumbnail)
            )
        } info: {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(nameRows, id: \.label) { row in
                    nameRow(icon: row.icon, label: row.label, value: row.value)
                }
                if let detail = session.detail {
                    HStack(spacing: 6) {
                        Image(systemName: detail.hasCollected ? "bookmark.fill" : "bookmark")
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(detail.hasCollected ? Color.orange : Color.secondary)
                        Text(detail.hasCollected ? "已收藏" : "未收藏")
                            .font(.subheadline)
                            .foregroundStyle(detail.hasCollected ? Color.primary : Color.secondary)
                    }
                    .padding(.top, 2)
                }
                infoLines
            }
        }
    }

    private struct NameRow: Hashable {
        let icon: String
        let label: String
        let value: String
    }

    private var nameRows: [NameRow] {
        let d = session.detail
        return [
            .init(icon: "textformat", label: "中文名", value: orDash(d?.mainName ?? actor.displayName)),
            .init(icon: "globe.asia.australia", label: "日文名", value: orDash(d?.japaneseName)),
            .init(icon: "sparkles", label: "昵称", value: orDash(d?.nickname)),
            .init(icon: "bookmark", label: "别名", value: orDash(d?.aliasName)),
        ]
    }

    private func nameRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 14, alignment: .center)
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 40, alignment: .leading)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }

    private var infoLines: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(infoRows, id: \.label) { row in
                nameRow(icon: row.icon, label: row.label, value: row.value)
            }
        }
        .padding(.top, 2)
    }

    private var infoRows: [NameRow] {
        let d = session.detail
        let height = d?.height?.nonEmpty.map { "\($0) cm" }
        return [
            .init(icon: "arrow.up.and.down", label: "身高", value: height ?? "-"),
            .init(icon: "rectangle.split.3x1", label: "三围", value: orDash(d?.bustWaistHip)),
            .init(icon: "mug", label: "罩杯", value: orDash(d?.cupSize)),
            .init(icon: "birthday.cake", label: "生日", value: orDash(d?.birthDate)),
            .init(icon: "person.badge.clock", label: "年龄", value: orDash(d?.age)),
        ]
    }

    private func orDash(_ value: String?) -> String {
        value?.nonEmpty ?? "-"
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
        HStack(spacing: 0) {
            ForEach(ActorDetailSegment.allCases) { item in
                Button {
                    segment = item
                } label: {
                    segmentTabLabel(item)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func segmentTabLabel(_ item: ActorDetailSegment) -> some View {
        let selected = segment == item
        let count = count(for: item) ?? 0
        return VStack(spacing: 4) {
            Image(systemName: item.systemImage)
                .font(.body.weight(.semibold))
            Text("\(item.rawValue) \(ArticleFormat.shortCount(count))")
                .font(.caption.weight(.medium))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(selected ? Color.accentColor : Color.secondary)
        .padding(.vertical, 2)
        .accessibilityLabel("\(item.rawValue) \(count)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func count(for segment: ActorDetailSegment) -> Int? {
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
            LazyVStack(alignment: .leading, spacing: 14) {
                ForEach(session.comments.items) { comment in
                    CommentRow(
                        comment: comment,
                        loadReplies: { parent in
                            await session.loadReplies(for: parent, actorID: actor.id)
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
