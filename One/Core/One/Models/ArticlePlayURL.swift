import Foundation

/// 把详情里的相对路径拼成可播放的绝对 URL。
///
/// 规则（与业务约定一致）：
/// 1. `video_hls_h265` / `video_hls` → 拼当前 API 主机（`OneTargets` 选线结果）
/// 2. `video_file` / `video` / `preview_video` → 拼 mp4 CDN
/// 3. 播放时取列表第一项；页底可展示全部（相同 URL 只保留一条）
enum ArticlePlayURL {
    /// 一条已拼接的地址（字段名 + URL）。
    struct Entry: Identifiable, Hashable {
        var id: String { url }
        let field: String
        let url: String
    }

    /// mp4 CDN。
    static let videoCDNBase = "https://pwavddl.t556wzr.com"
    /// 详情接口参数 `dn`。
    static let detailVideoDN = "https://pwavd123.phd3wfh.com/"

    /// 下载可选：`video_file` 原画 → `video` 标清。
    struct DownloadOption: Identifiable, Hashable {
        var id: String { field }
        let field: String
        let title: String
        let url: URL
    }

    private static let downloadFields = ["video_file", "video"]

    static func downloadOptions(from entries: [Entry]) -> [DownloadOption] {
        downloadFields.compactMap { field in
            guard let entry = entries.first(where: { $0.field == field }),
                  let url = URL(string: entry.url)
            else { return nil }
            let title = field == "video_file" ? "原画" : "标清"
            return DownloadOption(field: field, title: title, url: url)
        }
    }

    /// 全部可用地址：按优先级排列，相同 URL 只保留一条。播放器取 `first`。
    static func allEntries(
        business: ArticleDetail,
        play: ArticleDetail? = nil,
        apiBase: URL?
    ) -> [Entry] {
        let api = apiHost(from: apiBase) ?? OneTargets.hostBases.first ?? videoCDNBase
        let play = play ?? business

        func mergedPath(_ businessPath: String?, _ playPath: String?) -> String? {
            playPath?.nonEmpty ?? businessPath?.nonEmpty
        }

        let mergedVideos: [ArticleVideoItem] = {
            let fromPlay = play.videos ?? []
            if !fromPlay.isEmpty { return fromPlay }
            return business.videos ?? []
        }()

        // 顺序即播放优先级
        var sources: [(field: String, path: String?, base: String)] = [
            ("video_hls_h265", mergedPath(business.videoHlsH265, play.videoHlsH265), api),
            ("video_hls", mergedPath(business.videoHls, play.videoHls), api),
            ("video_file", mergedPath(business.videoFile, play.videoFile), videoCDNBase),
            ("video", mergedPath(business.video, play.video), videoCDNBase),
            ("preview_video", mergedPath(business.previewVideo, play.previewVideo), videoCDNBase),
        ]
        for (index, item) in mergedVideos.enumerated() {
            sources.append(("videos[\(index)]", item.videoFile, videoCDNBase))
        }

        var seen = Set<String>()
        var result: [Entry] = []
        for source in sources {
            guard let path = source.path?.nonEmpty else { continue }
            let absolute = OneCDN.join(base: source.base, path: path)
            guard !absolute.isEmpty, URL(string: absolute) != nil else { continue }
            guard seen.insert(absolute).inserted else { continue }
            result.append(Entry(field: source.field, url: absolute))
        }
        return result
    }

    /// `https://api.xxx.com/v2.5/` → `https://api.xxx.com`
    static func apiHost(from apiBase: URL?) -> String? {
        guard let apiBase, let scheme = apiBase.scheme, let host = apiBase.host else { return nil }
        if let port = apiBase.port {
            return "\(scheme)://\(host):\(port)"
        }
        return "\(scheme)://\(host)"
    }
}
