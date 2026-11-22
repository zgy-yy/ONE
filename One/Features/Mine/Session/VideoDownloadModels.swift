import Foundation

// MARK: - 列表展示用模型（View 只读这些字段，不直接碰 URLSession）

extension VideoDownloadSession {
    struct Item: Identifiable, Hashable {
        let id: UUID
        var title: String
        var coverPath: String?
        var qualityLabel: String
        /// 相对 `VideoDownloads` 的文件名（入队时确定，用于重启后找回文件）。
        let fileName: String
        var progress: Double
        var bytesWritten: Int64
        var bytesExpected: Int64
        var state: State
        var localFileURL: URL?
        var errorMessage: String?
        var addedAt: Date
        var remoteURLString: String
        var isWaitingForNetwork = false
        var isPaused = false
        var bytesPerSecond: Double = 0

        enum State: String, Hashable, Codable {
            case downloading
            case completed
            case failed
        }

        var effectiveProgress: Double {
            if progress > 0 { return min(1, progress) }
            guard bytesExpected > 0, bytesWritten > 0 else { return 0 }
            return min(1, Double(bytesWritten) / Double(bytesExpected))
        }

        var progressText: String {
            switch state {
            case .downloading:
                if isPaused {
                    if effectiveProgress > 0 {
                        return "已暂停 · \(Int((effectiveProgress * 100).rounded()))%"
                    }
                    return "已暂停"
                }
                if effectiveProgress > 0 {
                    return "\(Int((effectiveProgress * 100).rounded()))%"
                }
                if isWaitingForNetwork { return "等待网络…" }
                return "连接中…"
            case .completed: return "已完成"
            case .failed: return "失败"
            }
        }

        var formattedBytesWritten: String? {
            guard state == .downloading, bytesWritten > 0 else { return nil }
            return ByteCountFormatter.string(fromByteCount: bytesWritten, countStyle: .file)
        }

        var formattedBytesTotal: String? {
            guard state == .downloading, bytesExpected > 0 else { return nil }
            return ByteCountFormatter.string(fromByteCount: bytesExpected, countStyle: .file)
        }

        var formattedDownloadSpeed: String? {
            guard state == .downloading, !isPaused, !isWaitingForNetwork, bytesPerSecond >= 1 else { return nil }
            return Self.formatBytesPerSecond(bytesPerSecond)
        }

        static func formatBytesPerSecond(_ bytesPerSecond: Double) -> String {
            let bps = max(0, bytesPerSecond)
            if bps >= 1_000_000 {
                return String(format: "%.1f MB/s", bps / 1_000_000)
            }
            if bps >= 1_000 {
                return String(format: "%.0f KB/s", bps / 1_000)
            }
            return String(format: "%.0f B/s", bps)
        }
    }

    enum EnqueueResult {
        case started
        case duplicate
    }

    enum ListBanner: Equatable {
        case queued(title: String)
        case completed(title: String)
        case duplicate(title: String, quality: String)

        var text: String {
            switch self {
            case let .queued(title):
                return "「\(title)」已加入下载，可在下方查看进度。"
            case let .completed(title):
                return "「\(title)」已保存到「文件」→ \(VideoDownloadSession.filesAppFolderHint)。"
            case let .duplicate(title, quality):
                return "「\(title)」（\(quality)）已在下载列表中，无需重复下载。"
            }
        }

        var systemImage: String {
            switch self {
            case .queued: return "arrow.down.circle.fill"
            case .completed: return "checkmark.circle.fill"
            case .duplicate: return "exclamationmark.circle.fill"
            }
        }
    }
}