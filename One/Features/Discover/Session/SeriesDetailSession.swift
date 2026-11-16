import Foundation
import Observation

/// 系列详情：拉取章节列表。
@MainActor
@Observable
final class SeriesDetailSession {
    let series: SeriesSummary

    private(set) var detail: SeriesDetail?
    private(set) var isLoading = false
    private(set) var error: String?

    init(series: SeriesSummary) {
        self.series = series
    }

    var title: String { detail?.displayTitle ?? series.displayTitle }
    var author: String? { detail?.author?.nonEmpty ?? series.author?.nonEmpty }
    var coverPath: String? { detail?.thumb?.nonEmpty ?? series.imagePath }
    var isFinished: Bool { detail?.isFinished ?? series.isFinished }
    var chapters: [SeriesChapter] { detail?.chapterList ?? [] }

    func load(force: Bool = false) async {
        if !force, detail != nil { return }
        guard !isLoading else { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            detail = try await OneClient.seriesChapters(seriesID: series.id)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
