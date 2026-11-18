import SwiftUI

/// 系列详情：大封面顶到安全区外 + 章节列表。
struct SeriesDetailView: View {
    @State private var session: SeriesDetailSession

    init(series: SeriesSummary) {
        _session = State(initialValue: SeriesDetailSession(series: series))
    }

    var body: some View {
        DetailLoadGate(
            isLoading: session.isLoading,
            error: session.error,
            hasContent: session.detail != nil,
            loadingTitle: "加载章节…",
            retry: { Task { await session.load(force: true) } }
        ) {
            contentLayout
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task(id: session.series.id) {
            await session.load()
        }
    }

    private var contentLayout: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    chapters
                }
                .frame(width: geo.size.width, alignment: .leading)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    private var header: some View {
        OneCoverImage(
            path: session.coverPath,
            aspectRatio: CoverAspect.landscape,
            cornerRadius: 0
        )
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let author = session.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                }

                Text(session.isFinished ? "已完结" : "连载中")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(session.isFinished ? Color.white.opacity(0.75) : Color.accentColor)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { CoverBottomFade(opacity: 0.65) }
        }
    }

    private var chapters: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("章节 · \(session.chapters.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            if session.chapters.isEmpty {
                Text("暂无章节")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            } else {
                ForEach(session.chapters) { chapter in
                    SeriesChapterRow(chapter: chapter)
                        .hiddenNavigationLink(value: chapter.asArticleSummary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                }
            }
        }
        .padding(.bottom, 16)
    }
}
