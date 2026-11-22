import Foundation

/// `URLSession` 任务 ID ↔ 下载项映射。
///
/// 委托在后台线程执行，不能改 `@Observable` 的 Session；
/// 因此用锁 + 字典在这里做「任务 ID → 条目 / 文件名」中转。
final class VideoDownloadTaskRegistry: @unchecked Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var taskIDToItemID: [Int: UUID] = [:]
    nonisolated(unsafe) private var itemIDToFileName: [UUID: String] = [:]
    nonisolated(unsafe) private var itemIDToRemoteURL: [UUID: String] = [:]

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

    nonisolated func setRemoteURL(_ url: URL, for itemID: UUID) {
        lock.lock()
        defer { lock.unlock() }
        itemIDToRemoteURL[itemID] = url.absoluteString
    }

    nonisolated func remoteURL(for itemID: UUID) -> URL? {
        lock.lock()
        defer { lock.unlock() }
        guard let raw = itemIDToRemoteURL[itemID] else { return nil }
        return URL(string: raw)
    }

    nonisolated func removeFileName(for itemID: UUID) {
        lock.lock()
        defer { lock.unlock() }
        itemIDToFileName[itemID] = nil
    }

    nonisolated func removeRemoteURL(for itemID: UUID) {
        lock.lock()
        defer { lock.unlock() }
        itemIDToRemoteURL[itemID] = nil
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

    nonisolated func hasActiveTask(for itemID: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return taskIDToItemID.values.contains(itemID)
    }

    nonisolated func taskID(forItemID itemID: UUID) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        return taskIDToItemID.first(where: { $0.value == itemID })?.key
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