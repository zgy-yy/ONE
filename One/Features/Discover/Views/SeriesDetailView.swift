import SwiftUI

/// 系列详情：封面信息 + 章节列表。
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
            chapterList
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: session.series.id) {
            await session.load()
        }
    }

    private var chapterList: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                if session.chapters.isEmpty {
                    Text("暂无章节")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .styledListRow()
                } else {
                    ForEach(session.chapters) { chapter in
                        chapterRow(chapter)
                            .hiddenNavigationLink(value: chapter.asArticleSummary)
                            .styledListRow()
                    }
                }
            } header: {
                Text("章节 · \(session.chapters.count)")
            }
        }
        .plainContentList()
    }

    private var header: some View {
        LeadingMediaHeader {
            OneCoverImage(path: session.coverPath)
        } info: {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.title)
                    .font(.title3.weight(.semibold))

                if let author = session.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(session.isFinished ? "已完结" : "连载中")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(session.isFinished ? Color.secondary : Color.accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func chapterRow(_ chapter: SeriesChapter) -> some View {
        HStack(spacing: 12) {
            OneCoverImage(path: chapter.imagePath)
                .frame(width: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.displayTitle)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)

                if let published = chapter.publishedAt?.nonEmpty {
                    Text(published)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
