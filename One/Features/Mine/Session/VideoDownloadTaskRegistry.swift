import Foundation

/// `URLSession` 任务 ID ↔ 下载项映射（委托线程安全，避免放在 `@Observable` 里）。
final class VideoDownloadTaskRegistry: @unchecked Sendable {
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