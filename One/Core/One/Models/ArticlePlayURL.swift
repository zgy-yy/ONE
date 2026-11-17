import Foundation

/// 从 detail 挑选默认播放相对路径（与 one-web `pickDefaultPlayPath` 优先级一致）。
enum ArticlePlayURL {
    /// 点播视频 CDN 前缀（拼在 `video_file` / `video_hls` 等相对路径前）。
    static let videoCDNBase = "https://pwavddl.t556wzr.com"

    static func defaultPath(in detail: ArticleDetail) -> String? {
        for candidate in [
            detail.videoFile,
            detail.videoHls,
            detail.video,
            detail.previewVideo,
        ] {
            if let trimmed = trimmed(candidate) { return trimmed }
        }
        for item in detail.videos ?? [] {
            if let trimmed = trimmed(item.videoFile) { return trimmed }
        }
        return nil
    }

    static func resolvedURL(detail: ArticleDetail, videoCDN: String?) -> URL? {
        guard let path = defaultPath(in: detail) else { return nil }
        let joined = OneCDN.join(base: videoCDN ?? videoCDNBase, path: path)
        return URL(string: joined)
    }

    private static func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let s = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? nil : s
    }
}
