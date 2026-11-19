import Foundation

/// 系列（写真 / 漫画）相关接口。
extension OneClient {
    static func seriesAlbumList(
        type: Int,
        page: Int,
        size: Int = 20,
        sort: String = "published_at"
    ) async throws -> [SeriesSummary] {
        try await seriesList(path: OneAPI.seriesAlbumListPath, type: type, page: page, size: size, sort: sort)
    }

    static func seriesMangaList(
        type: Int,
        page: Int,
        size: Int = 20,
        sort: String = "published_at"
    ) async throws -> [SeriesSummary] {
        try await seriesList(path: OneAPI.seriesMangaListPath, type: type, page: page, size: size, sort: sort)
    }

    static func seriesChapters(seriesID: Int) async throws -> SeriesDetail {
        let envelope = try await post(
            OneApiEnvelope<SeriesDetail>.self,
            path: OneAPI.seriesChaptersPath,
            data: ["series_id": String(seriesID)]
        )
        guard let detail = try unwrap(envelope) else {
            throw OneClientError.apiRejected("章节为空")
        }
        return detail
    }

    private static func seriesList(
        path: String,
        type: Int,
        page: Int,
        size: Int,
        sort: String
    ) async throws -> [SeriesSummary] {
        let envelope = try await post(
            OneApiEnvelope<SeriesListPayload>.self,
            path: path,
            data: [
                "type": String(type),
                "page": String(page),
                "size": String(size),
                "sort": sort,
            ]
        )
        return try unwrap(envelope)?.items ?? []
    }
}
