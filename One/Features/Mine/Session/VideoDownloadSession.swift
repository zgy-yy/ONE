import Foundation
import Observation
import UIKit

/// App 内视频下载队列（`URLSession` 后台任务 + 进度回调）。
@MainActor
@Observable
final class VideoDownloadSession: NSObject {
    static let shared = VideoDownloadSession()

    nonisolated private static let taskRegistry = VideoDownloadTaskRegistry()

    /// 用户视频目录：`Documents/VideoDownloads`，可在系统「文件」App 中直接查看。
    nonisolated static let downloadsFolderName = "VideoDownloads"

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

        enum State: String, Hashable, Codable {
            case downloading
            case completed
            case failed
        }

        var progressText: String {
            switch state {
            case .downloading:
                if progress > 0 {
                    return "\(Int((progress * 100).rounded()))%"
                }
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
    }

    private(set) var items: [Item] = []

    private struct PersistedItem: Codable {
        let id: UUID
        var title: String
        var coverPath: String?
        var qualityLabel: String
        var fileName: String
        var state: Item.State
        var errorMessage: String?
        var addedAt: Date

        init(_ item: Item) {
            id = item.id
            title = item.title
            coverPath = item.coverPath
            qualityLabel = item.qualityLabel
            fileName = item.fileName
            state = item.state
            errorMessage = item.errorMessage
            addedAt = item.addedAt
        }
    }

    static let downloadQualitySuffixes = ["原画", "标清"]

    enum EnqueueResult {
        case started
        case duplicate
    }

    /// 仅在下载列表页展示的提示（详情页不再弹 Alert）。
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

    private(set) var listBanner: ListBanner?

    private var urlSession: URLSession!

    private override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        items = Self.loadPersistedItems()
    }

    var activeDownloadCount: Int {
        items.filter { $0.state == .downloading }.count
    }

    /// 「文件」里展示的相对路径说明（`本应用名 / VideoDownloads`）。
    static var filesAppFolderHint: String {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "One"
        return "\(appName) / \(downloadsFolderName)"
    }

    @discardableResult
    func enqueue(title: String, coverPath: String?, qualityLabel: String, remoteURL: URL) -> EnqueueResult {
        let quality = Self.normalizedQualityLabel(qualityLabel)
        let fileName = Self.suggestedFileName(title: title, qualityLabel: quality)

        if items.contains(where: {
            $0.fileName == fileName && ($0.state == .downloading || $0.state == .completed)
        }) {
            listBanner = .duplicate(title: title, quality: quality)
            return .duplicate
        }

        items.removeAll { $0.fileName == fileName && $0.state == .failed }

        let itemID = UUID()
        Self.taskRegistry.setFileName(fileName, for: itemID)

        items.insert(
            Item(
                id: itemID,
                title: title,
                coverPath: coverPath?.nonEmpty,
                qualityLabel: quality,
                fileName: fileName,
                progress: 0,
                bytesWritten: 0,
                bytesExpected: 0,
                state: .downloading,
                localFileURL: nil,
                errorMessage: nil,
                addedAt: Date()
            ),
            at: 0
        )
        persistItems()

        var request = URLRequest(url: remoteURL)
        request.timeoutInterval = 600
        let task = urlSession.downloadTask(with: request)
        Self.taskRegistry.setItemID(itemID, forTaskID: task.taskIdentifier)
        listBanner = .queued(title: title)
        task.resume()
        return .started
    }

    func clearListBanner() {
        listBanner = nil
    }

    /// 已落盘的 mp4（按修改时间倒序）。
    func savedVideoFileURLs() -> [URL] {
        guard let dir = try? Self.persistedDownloadsDirectory(ensureExists: true) else { return [] }
        let keys: [URLResourceKey] = [.contentModificationDateKey, .isRegularFileKey]
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return [] }
        return entries
            .filter { $0.pathExtension.lowercased() == "mp4" }
            .sorted { lhs, rhs in
                let lDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lDate > rDate
            }
    }

    var downloadsFolderURL: URL? {
        try? Self.persistedDownloadsDirectory(ensureExists: true)
    }

    /// 尝试在系统「文件」App 中打开下载目录；不成功时由调用方改走应用内浏览。
    func openDownloadsFolderInFilesApp() async -> Bool {
        guard let dir = downloadsFolderURL else { return false }
        let shareURLString = dir.absoluteString.replacingOccurrences(of: "file://", with: "shareddocuments://")
        guard let url = URL(string: shareURLString) else { return false }
        return await UIApplication.shared.open(url)
    }

    func remove(_ item: Item) {
        if let url = item.localFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        items.removeAll { $0.id == item.id }
        Self.taskRegistry.removeFileName(for: item.id)
        persistItems()
    }

    private func itemIndex(for id: UUID) -> Int? {
        items.firstIndex { $0.id == id }
    }

    private func updateProgress(
        itemID: UUID,
        fraction: Double,
        bytesWritten: Int64,
        bytesExpected: Int64
    ) {
        guard let index = itemIndex(for: itemID) else { return }
        items[index].progress = min(1, max(0, fraction))
        items[index].bytesWritten = bytesWritten
        items[index].bytesExpected = bytesExpected
    }

    private func markCompleted(itemID: UUID, fileURL: URL) {
        guard let index = itemIndex(for: itemID) else { return }
        items[index].state = .completed
        items[index].progress = 1
        items[index].localFileURL = fileURL
        items[index].errorMessage = nil
        listBanner = .completed(title: items[index].title)
        persistItems()
    }

    private func markFailed(itemID: UUID, message: String) {
        guard let index = itemIndex(for: itemID) else { return }
        items[index].state = .failed
        items[index].errorMessage = message
        persistItems()
    }

    private func clearTaskMapping(taskID: Int) {
        Self.taskRegistry.removeTaskMapping(taskID: taskID)
    }

    /// 在委托回调里同步落盘（须在 `didFinishDownloadingTo` 返回前完成，不能 `await` 主线程）。
    nonisolated private static func persistDownload(
        from tempLocation: URL,
        to destination: URL
    ) throws {
        let fm = FileManager.default
        let dir = destination.deletingLastPathComponent()
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        if fm.fileExists(atPath: destination.path) {
            try fm.removeItem(at: destination)
        }
        // 必须从 CFNetwork 临时路径 **复制**；方法返回后临时文件会被系统删掉。
        try fm.copyItem(at: tempLocation, to: destination)
    }

    /// 仅 `片名-原画.mp4` / `片名-标清.mp4`。
    static func suggestedFileName(title: String, qualityLabel: String) -> String {
        let base = sanitizedBaseName(title)
        let quality = normalizedQualityLabel(qualityLabel)
        return "\(base)-\(quality).mp4"
    }

    static func normalizedQualityLabel(_ label: String) -> String {
        switch label {
        case "标准": return "标清"
        case "原画", "标清": return label
        default: return label
        }
    }

    private static func sanitizedBaseName(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitized = trimmed
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        return sanitized.isEmpty ? "video" : String(sanitized.prefix(80))
    }

    nonisolated static func persistedDownloadsDirectory(ensureExists: Bool = false) throws -> URL {
        guard let base = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        let dir = base.appendingPathComponent(downloadsFolderName, isDirectory: true)
        if ensureExists {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    // MARK: - 列表持久化（进程退出后仍能看见记录）

    private nonisolated static var indexFileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("VideoDownloadsIndex.json")
    }

    private func persistItems() {
        let payload = items.map(PersistedItem.init)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        let url = Self.indexFileURL
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
    }

    private static func loadPersistedItems() -> [Item] {
        let dir = (try? persistedDownloadsDirectory(ensureExists: true))
        let indexURL = indexFileURL
        let decoder = JSONDecoder()

        var records: [PersistedItem] = []
        if let data = try? Data(contentsOf: indexURL),
           let decoded = try? decoder.decode([PersistedItem].self, from: data) {
            records = decoded
        }

        var items: [Item] = records.map { record in
            item(from: record, downloadsDir: dir)
        }

        guard let dir else { return items.sorted { $0.addedAt > $1.addedAt } }

        let knownNames = Set(items.map(\.fileName))
        if let urls = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) {
            for fileURL in urls where fileURL.pathExtension.lowercased() == "mp4" {
                let name = fileURL.lastPathComponent
                guard !knownNames.contains(name) else { continue }
                let title = titleGuess(fromFileName: name)
                items.append(
                    Item(
                        id: UUID(),
                        title: title,
                        coverPath: nil,
                        qualityLabel: qualityLabel(fromFileName: name),
                        fileName: name,
                        progress: 1,
                        bytesWritten: 0,
                        bytesExpected: 0,
                        state: .completed,
                        localFileURL: fileURL,
                        errorMessage: nil,
                        addedAt: (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
                            ?? .distantPast
                    )
                )
            }
        }

        return items.sorted { $0.addedAt > $1.addedAt }
    }

    private static func item(from record: PersistedItem, downloadsDir: URL?) -> Item {
        var state = record.state
        var error = record.errorMessage
        var localURL: URL?

        if state == .downloading {
            state = .failed
            error = "应用已退出，请重新下载"
        }

        if let dir = downloadsDir {
            let fileURL = dir.appendingPathComponent(record.fileName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                localURL = fileURL
                if state != .failed {
                    state = .completed
                    error = nil
                }
            } else if state == .completed {
                state = .failed
                error = "文件已不存在"
            }
        }

        return Item(
            id: record.id,
            title: record.title,
            coverPath: record.coverPath,
            qualityLabel: record.qualityLabel,
            fileName: record.fileName,
            progress: state == .completed ? 1 : 0,
            bytesWritten: 0,
            bytesExpected: 0,
            state: state,
            localFileURL: localURL,
            errorMessage: error,
            addedAt: record.addedAt
        )
    }

    private static func titleGuess(fromFileName name: String) -> String {
        let base = (name as NSString).deletingPathExtension
        for quality in downloadQualitySuffixes {
            let suffix = "-\(quality)"
            if base.hasSuffix(suffix) {
                return String(base.dropLast(suffix.count))
            }
        }
        return base
    }

    private static func qualityLabel(fromFileName name: String) -> String {
        let base = (name as NSString).deletingPathExtension
        for quality in downloadQualitySuffixes where base.hasSuffix("-\(quality)") {
            return quality
        }
        return "本地"
    }
}

extension VideoDownloadSession: URLSessionDownloadDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let taskID = downloadTask.taskIdentifier
        let fraction = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { @MainActor in
            guard let itemID = Self.taskRegistry.itemID(forTaskID: taskID) else { return }
            self.updateProgress(
                itemID: itemID,
                fraction: fraction,
                bytesWritten: totalBytesWritten,
                bytesExpected: totalBytesExpectedToWrite
            )
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let taskID = downloadTask.taskIdentifier
        let itemID = Self.taskRegistry.itemID(forTaskID: taskID)
        let destination = Self.taskRegistry.destinationURL(forTaskID: taskID)

        let persistResult: Result<URL, Error>
        if let destination {
            do {
                try Self.persistDownload(from: location, to: destination)
                persistResult = .success(destination)
            } catch {
                persistResult = .failure(error)
            }
        } else {
            persistResult = .failure(
                CocoaError(.fileWriteNoPermission, userInfo: [
                    NSLocalizedDescriptionKey: "无法创建下载目录或找不到下载任务",
                ])
            )
        }

        Task { @MainActor in
            defer { self.clearTaskMapping(taskID: taskID) }
            guard let itemID else {
                if case .success(let url) = persistResult {
                    try? FileManager.default.removeItem(at: url)
                }
                return
            }
            switch persistResult {
            case let .success(url):
                self.markCompleted(itemID: itemID, fileURL: url)
            case let .failure(error):
                self.markFailed(itemID: itemID, message: error.localizedDescription)
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        let taskID = task.taskIdentifier
        Task { @MainActor in
            defer { self.clearTaskMapping(taskID: taskID) }
            guard let itemID = Self.taskRegistry.itemID(forTaskID: taskID) else { return }
            if let index = self.itemIndex(for: itemID), self.items[index].state == .downloading {
                self.markFailed(itemID: itemID, message: error.localizedDescription)
            }
        }
    }
}