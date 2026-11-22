import Foundation
import Network
import Observation
import UIKit

/// 视频下载调度中心（单例 Session）。
///
/// 阅读顺序（初学者）：
/// 1. `VideoDownloadModels.swift` — 列表项长什么样
/// 2. 本文件 — 入队、暂停、网络与生命周期
/// 3. `VideoDownloadTaskRegistry.swift` — 任务 ID 映射（委托线程安全）
/// 4. `VideoDownloadSession+Persistence.swift` — JSON 索引与本地 mp4
/// 5. 本文件末尾 — `URLSessionDownloadDelegate` 回调
/// 6. `VideoDownloadListView.swift` — 界面
@MainActor
@Observable
final class VideoDownloadSession: NSObject {
    static let shared = VideoDownloadSession()

    nonisolated static let taskRegistry = VideoDownloadTaskRegistry()

    /// 用户视频目录：`Documents/VideoDownloads`，可在系统「文件」App 中直接查看。
    nonisolated static let downloadsFolderName = "VideoDownloads"

    private(set) var items: [Item] = []
    private(set) var listBanner: ListBanner?

    private var urlSession: URLSession!
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "VideoDownload.NetworkMonitor")
    private var downloadSpeedTrackers: [UUID: DownloadSpeedSample] = [:]
    private var lastProgressPersistDate = Date.distantPast
    private var preserveSuspendRemainingCount = 0

    private struct DownloadSpeedSample {
        var lastBytes: Int64
        var lastDate: Date
        var smoothedBytesPerSecond: Double
    }

    // MARK: - 初始化

    private override init() {
        super.init()
        urlSession = URLSession(configuration: Self.makeURLSessionConfiguration(), delegate: self, delegateQueue: nil)
        items = Self.loadPersistedItems()
        restoreRegistryFromPersistedItems()
        seedSpeedTrackersFromItems()
        resumeInterruptedDownloads()
        startNetworkMonitor()
        registerAppLifecycleObservers()
    }

    // MARK: - 生命周期与网络

    private func restoreRegistryFromPersistedItems() {
        for item in items where item.state == .downloading {
            Self.taskRegistry.setFileName(item.fileName, for: item.id)
            if let url = URL(string: item.remoteURLString) {
                Self.taskRegistry.setRemoteURL(url, for: item.id)
            }
        }
    }

    private func seedSpeedTrackersFromItems() {
        let now = Date()
        for item in items where item.state == .downloading && item.bytesWritten > 0 {
            downloadSpeedTrackers[item.id] = DownloadSpeedSample(
                lastBytes: item.bytesWritten,
                lastDate: now,
                smoothedBytesPerSecond: 0
            )
        }
    }

    private func registerAppLifecycleObservers() {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(onDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(onWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(onWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func onDidEnterBackground() {
        preserveActiveDownloadsBeforeSuspension()
    }

    @objc private func onWillTerminate() {
        preserveActiveDownloadsBeforeSuspension()
    }

    @objc private func onWillEnterForeground() {
        resumeInterruptedDownloads()
    }

    private static func makeURLSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 86_400
        config.timeoutIntervalForRequest = 600
        return config
    }

    private func startNetworkMonitor() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }
            DispatchQueue.main.async {
                self?.resumeInterruptedDownloads()
            }
        }
        networkMonitor.start(queue: networkQueue)
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

    // MARK: - 对外 API

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
        Self.taskRegistry.setRemoteURL(remoteURL, for: itemID)

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
                addedAt: Date(),
                remoteURLString: remoteURL.absoluteString,
                isWaitingForNetwork: false,
                isPaused: false
            ),
            at: 0
        )
        persistItems()
        deleteResumeData(for: itemID)

        listBanner = .queued(title: title)
        startDownloadTask(for: itemID)
        return .started
    }

    func clearListBanner() {
        listBanner = nil
    }

    func toggleDownloadPause(_ item: Item) {
        if item.isPaused {
            resumeDownloadAfterPause(item)
        } else {
            pauseDownload(item)
        }
    }

    private func pauseDownload(_ item: Item) {
        guard item.state == .downloading, !item.isPaused else { return }
        cancelActiveDownload(for: item.id, markPaused: true)
    }

    private func resumeDownloadAfterPause(_ item: Item) {
        guard item.state == .downloading, item.isPaused else { return }
        guard let index = itemIndex(for: item.id) else { return }
        items[index].isPaused = false
        items[index].isWaitingForNetwork = false
        persistItems()
        startDownloadTask(for: item.id)
    }

    // MARK: - 暂停 / 后台续传

    /// 退到后台 / 即将被杀时：用 `resumeData` 留住断点，下次进来自动续传。
    private func preserveActiveDownloadsBeforeSuspension() {
        let activeIDs = items
            .filter { $0.state == .downloading && !$0.isPaused }
            .map(\.id)
        guard !activeIDs.isEmpty else {
            persistItems()
            return
        }

        urlSession.getTasksWithCompletionHandler { _, _, downloadTasks in
            let tasksToCancel = downloadTasks.compactMap { task -> (URLSessionDownloadTask, UUID)? in
                guard let itemID = Self.taskRegistry.itemID(forTaskID: task.taskIdentifier),
                      activeIDs.contains(itemID)
                else { return nil }
                return (task, itemID)
            }
            Task { @MainActor in
                self.beginPreservingDownloadsBeforeSuspension(tasksToCancel)
            }
        }
    }

    private func beginPreservingDownloadsBeforeSuspension(_ tasks: [(URLSessionDownloadTask, UUID)]) {
        guard !tasks.isEmpty else {
            persistItems()
            return
        }
        preserveSuspendRemainingCount = tasks.count
        for (task, itemID) in tasks {
            cancelDownloadTask(task, itemID: itemID, markPaused: false) {
                self.onPreserveSuspendCancelFinished()
            }
        }
    }

    private func onPreserveSuspendCancelFinished() {
        preserveSuspendRemainingCount -= 1
        if preserveSuspendRemainingCount <= 0 {
            persistItems()
        }
    }

    private func cancelActiveDownload(for itemID: UUID, markPaused: Bool) {
        guard let index = itemIndex(for: itemID), items[index].state == .downloading else { return }

        if let taskID = Self.taskRegistry.taskID(forItemID: itemID) {
            urlSession.getTasksWithCompletionHandler { _, _, downloadTasks in
                let matched = downloadTasks.first { $0.taskIdentifier == taskID }
                Task { @MainActor in
                    if let matched {
                        self.cancelDownloadTask(matched, itemID: itemID, markPaused: markPaused, completion: nil)
                    } else if markPaused {
                        self.applyPausedState(for: itemID)
                    }
                }
            }
        } else if markPaused {
            applyPausedState(for: itemID)
        }
    }

    private func cancelDownloadTask(
        _ task: URLSessionDownloadTask,
        itemID: UUID,
        markPaused: Bool,
        completion: (() -> Void)?
    ) {
        let taskID = task.taskIdentifier
        task.cancel(byProducingResumeData: { data in
            Task { @MainActor in
                self.finishCancellingDownload(
                    resumeData: data,
                    itemID: itemID,
                    taskID: taskID,
                    markPaused: markPaused
                )
                completion?()
            }
        })
    }

    private func finishCancellingDownload(
        resumeData: Data?,
        itemID: UUID,
        taskID: Int,
        markPaused: Bool
    ) {
        if let resumeData {
            saveResumeData(resumeData, for: itemID)
        }
        clearTaskMapping(taskID: taskID)
        if markPaused {
            applyPausedState(for: itemID)
        }
    }

    private func applyPausedState(for itemID: UUID) {
        guard let index = itemIndex(for: itemID), items[index].state == .downloading else { return }
        items[index].isPaused = true
        items[index].isWaitingForNetwork = false
        resetDownloadSpeed(for: itemID)
        persistItems()
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
        if let taskID = Self.taskRegistry.taskID(forItemID: item.id) {
            urlSession.getTasksWithCompletionHandler { _, _, downloadTasks in
                downloadTasks.first { $0.taskIdentifier == taskID }?.cancel()
            }
        }
        if let url = item.localFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        items.removeAll { $0.id == item.id }
        Self.taskRegistry.removeFileName(for: item.id)
        Self.taskRegistry.removeRemoteURL(for: item.id)
        deleteResumeData(for: item.id)
        downloadSpeedTrackers.removeValue(forKey: item.id)
        persistItems()
    }

    func itemIndex(for id: UUID) -> Int? {
        items.firstIndex { $0.id == id }
    }

    func updateProgress(
        itemID: UUID,
        fraction: Double,
        bytesWritten: Int64,
        bytesExpected: Int64
    ) {
        guard let index = itemIndex(for: itemID) else { return }
        items[index].progress = min(1, max(0, fraction))
        items[index].bytesWritten = bytesWritten
        items[index].bytesExpected = bytesExpected
        if items[index].state == .downloading, items[index].isWaitingForNetwork {
            items[index].isWaitingForNetwork = false
        }
        updateDownloadSpeed(itemID: itemID, bytesWritten: bytesWritten)

        let now = Date()
        if now.timeIntervalSince(lastProgressPersistDate) >= 1.5 {
            lastProgressPersistDate = now
            persistItems()
        }
    }

    private func updateDownloadSpeed(itemID: UUID, bytesWritten: Int64, now: Date = .now) {
        guard let index = itemIndex(for: itemID), items[index].state == .downloading else { return }

        if var sample = downloadSpeedTrackers[itemID] {
            let interval = now.timeIntervalSince(sample.lastDate)
            guard interval >= 0.3 else { return }

            let deltaBytes = bytesWritten - sample.lastBytes
            sample.lastBytes = bytesWritten
            sample.lastDate = now

            if deltaBytes > 0 {
                let instant = Double(deltaBytes) / interval
                let alpha = 0.35
                if sample.smoothedBytesPerSecond > 0 {
                    sample.smoothedBytesPerSecond =
                        sample.smoothedBytesPerSecond * (1 - alpha) + instant * alpha
                } else {
                    sample.smoothedBytesPerSecond = instant
                }
                items[index].bytesPerSecond = sample.smoothedBytesPerSecond
            }

            downloadSpeedTrackers[itemID] = sample
        } else {
            downloadSpeedTrackers[itemID] = DownloadSpeedSample(
                lastBytes: bytesWritten,
                lastDate: now,
                smoothedBytesPerSecond: 0
            )
        }
    }

    private func resetDownloadSpeed(for itemID: UUID) {
        downloadSpeedTrackers.removeValue(forKey: itemID)
        guard let index = itemIndex(for: itemID) else { return }
        items[index].bytesPerSecond = 0
    }

    func markCompleted(itemID: UUID, fileURL: URL) {
        guard let index = itemIndex(for: itemID) else { return }
        items[index].state = .completed
        items[index].progress = 1
        items[index].localFileURL = fileURL
        items[index].errorMessage = nil
        items[index].isWaitingForNetwork = false
        resetDownloadSpeed(for: itemID)
        deleteResumeData(for: itemID)
        listBanner = .completed(title: items[index].title)
        persistItems()
    }

    func markFailed(itemID: UUID, message: String) {
        guard let index = itemIndex(for: itemID) else { return }
        items[index].state = .failed
        items[index].errorMessage = message
        items[index].isWaitingForNetwork = false
        resetDownloadSpeed(for: itemID)
        persistItems()
    }

    func markWaitingForNetwork(itemID: UUID) {
        guard let index = itemIndex(for: itemID) else { return }
        guard items[index].state == .downloading else { return }
        items[index].isWaitingForNetwork = true
        items[index].errorMessage = nil
        resetDownloadSpeed(for: itemID)
        persistItems()
    }

    // MARK: - 任务控制与进度

    /// 网络恢复或冷启动后，继续未完成下载（支持 `resumeData` 断点续传）。
    private func resumeInterruptedDownloads() {
        for item in items where item.state == .downloading && !item.isPaused {
            guard !Self.taskRegistry.hasActiveTask(for: item.id) else { continue }
            startDownloadTask(for: item.id)
        }
    }

    private func startDownloadTask(for itemID: UUID) {
        guard let index = itemIndex(for: itemID), items[index].state == .downloading, !items[index].isPaused else { return }
        guard let remoteURL = URL(string: items[index].remoteURLString)
            ?? Self.taskRegistry.remoteURL(for: itemID)
        else {
            markFailed(itemID: itemID, message: "缺少下载地址")
            return
        }

        Self.taskRegistry.setRemoteURL(remoteURL, for: itemID)
        items[index].isWaitingForNetwork = false
        items[index].errorMessage = nil
        resetDownloadSpeed(for: itemID)

        let task: URLSessionDownloadTask
        if let resumeData = loadResumeData(for: itemID) {
            task = urlSession.downloadTask(withResumeData: resumeData)
        } else {
            var request = URLRequest(url: remoteURL)
            request.timeoutInterval = 600
            task = urlSession.downloadTask(with: request)
        }

        Self.taskRegistry.setItemID(itemID, forTaskID: task.taskIdentifier)
        task.resume()
    }

    nonisolated static func isRecoverableNetworkError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorCannotFindHost,
                 NSURLErrorDNSLookupFailed,
                 NSURLErrorInternationalRoamingOff,
                 NSURLErrorDataNotAllowed:
                return true
            default:
                return false
            }
        }
        return false
    }

    nonisolated static func resumeData(from error: Error) -> Data? {
        let nsError = error as NSError
        return nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
    }

    func saveResumeData(_ data: Data, for itemID: UUID) {
        try? data.write(to: Self.resumeDataURL(for: itemID), options: .atomic)
    }

    private func loadResumeData(for itemID: UUID) -> Data? {
        let url = Self.resumeDataURL(for: itemID)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }

    private func deleteResumeData(for itemID: UUID) {
        try? FileManager.default.removeItem(at: Self.resumeDataURL(for: itemID))
    }

    private nonisolated static func resumeDataURL(for itemID: UUID) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("VideoDownloadResume", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(itemID.uuidString).resume", isDirectory: false)
    }

    func clearTaskMapping(taskID: Int) {
        Self.taskRegistry.removeTaskMapping(taskID: taskID)
    }
}

// MARK: - URLSessionDownloadDelegate

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
        Task { @MainActor [weak self] in
            guard let self,
                  let itemID = Self.taskRegistry.itemID(forTaskID: taskID)
            else { return }
            updateProgress(
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

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { clearTaskMapping(taskID: taskID) }
            guard let itemID else {
                if case .success(let url) = persistResult {
                    try? FileManager.default.removeItem(at: url)
                }
                return
            }
            switch persistResult {
            case let .success(url):
                markCompleted(itemID: itemID, fileURL: url)
            case let .failure(error):
                markFailed(itemID: itemID, message: error.localizedDescription)
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        let taskID = task.taskIdentifier
        let nsError = error as NSError
        let resumeData = Self.resumeData(from: error)
        let recoverable = Self.isRecoverableNetworkError(error)
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { clearTaskMapping(taskID: taskID) }
            guard let itemID = Self.taskRegistry.itemID(forTaskID: taskID) else { return }
            guard let index = itemIndex(for: itemID), items[index].state == .downloading else { return }

            if nsError.code == NSURLErrorCancelled {
                if let resumeData {
                    saveResumeData(resumeData, for: itemID)
                    persistItems()
                }
                return
            }

            if recoverable {
                if let resumeData {
                    saveResumeData(resumeData, for: itemID)
                }
                markWaitingForNetwork(itemID: itemID)
                return
            }
            markFailed(itemID: itemID, message: error.localizedDescription)
        }
    }
}