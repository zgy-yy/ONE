import Foundation
import Observation
import UIKit

/// `URLSession` 任务 ID ↔ 下载项映射（委托线程安全，避免放在 `@Observable` 里）。
private final class VideoDownloadTaskRegistry: @unchecked Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var taskIDToItemID: [Int: UUID] = [:]
    nonisolated(unsafe) private var itemIDToFileName: [UUID: String] = [:]

    nonisolated init() {}

    nonisolated func setItemID(_ itemID: UUID, forTaskID taskID: Int) {
        lock.lock()
        defer { lock.unlock() }
        taskIDToItemID[taskID] = itemID
    }

    nonisolated func setFileName(_ fileName: String, for itemID: UUID) {
        lock.lock()
        defer { lock.unlock() }
        itemIDToFileName[itemID] = fileName
    }

    nonisolated func removeFileName(for itemID: UUID) {
        lock.lock()
        defer { lock.unlock() }
        itemIDToFileName[itemID] = nil
    }

    nonisolated func removeTaskMapping(taskID: Int) {
        lock.lock()
        defer { lock.unlock() }
        taskIDToItemID[taskID] = nil
    }

    nonisolated func itemID(forTaskID taskID: Int) -> UUID? {
        lock.lock()
        defer { lock.unlock() }
        return taskIDToItemID[taskID]
    }

    nonisolated func destinationURL(forTaskID taskID: Int) -> URL? {
        let fileName: String?
        lock.lock()
        if let itemID = taskIDToItemID[taskID] {
            fileName = itemIDToFileName[itemID]
        } else {
            fileName = nil
        }
        lock.unlock()

        guard let fileName else { return nil }
        do {
            let dir = try VideoDownloadSession.persistedDownloadsDirectory(ensureExists: true)
            return dir.appendingPathComponent(fileName, isDirectory: false)
        } catch {
            return nil
        }
    }
}

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
        var progress: Double
        var bytesWritten: Int64
        var bytesExpected: Int64
        var state: State
        var localFileURL: URL?
        var errorMessage: String?

        enum State: String, Hashable {
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

    /// 仅在下载列表页展示的提示（详情页不再弹 Alert）。
    enum ListBanner: Equatable {
        case queued(title: String)
        case completed(title: String)

        var text: String {
            switch self {
            case let .queued(title):
                return "「\(title)」已加入下载，可在下方查看进度。"
            case let .completed(title):
                return "「\(title)」已保存到「文件」→ \(VideoDownloadSession.filesAppFolderHint)。"
            }
        }

        var systemImage: String {
            switch self {
            case .queued: return "arrow.down.circle.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }

        var isCompleted: Bool {
            if case .completed = self { return true }
            return false
        }
    }

    private(set) var listBanner: ListBanner?

    private var urlSession: URLSession!

    private override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
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

    func enqueue(title: String, coverPath: String?, qualityLabel: String, remoteURL: URL) {
        let itemID = UUID()
        let fileName = Self.suggestedFileName(title: title, qualityLabel: qualityLabel, itemID: itemID)
        Self.taskRegistry.setFileName(fileName, for: itemID)

        items.insert(
            Item(
                id: itemID,
                title: title,
                coverPath: coverPath?.nonEmpty,
                qualityLabel: qualityLabel,
                progress: 0,
                bytesWritten: 0,
                bytesExpected: 0,
                state: .downloading,
                localFileURL: nil,
                errorMessage: nil
            ),
            at: 0
        )

        var request = URLRequest(url: remoteURL)
        request.timeoutInterval = 600
        let task = urlSession.downloadTask(with: request)
        Self.taskRegistry.setItemID(itemID, forTaskID: task.taskIdentifier)
        listBanner = .queued(title: title)
        task.resume()
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
    }

    private func markFailed(itemID: UUID, message: String) {
        guard let index = itemIndex(for: itemID) else { return }
        items[index].state = .failed
        items[index].errorMessage = message
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

    static func suggestedFileName(title: String, qualityLabel: String, itemID: UUID) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitized = trimmed
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        let base = sanitized.isEmpty ? "video" : String(sanitized.prefix(48))
        let suffix = String(itemID.uuidString.prefix(6))
        return "\(base)-\(qualityLabel)-\(suffix).mp4"
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