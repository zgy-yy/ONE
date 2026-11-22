import Foundation

// MARK: - JSON 索引 + 本地 mp4 目录

extension VideoDownloadSession {
  static let downloadQualitySuffixes = ["原画", "标清"]

  struct PersistedItem: Codable {
    let id: UUID
    var title: String
    var coverPath: String?
    var qualityLabel: String
    var fileName: String
    var state: Item.State
    var errorMessage: String?
    var addedAt: Date
    var remoteURLString: String
    var progress: Double
    var bytesWritten: Int64
    var bytesExpected: Int64
    var isPaused: Bool

    init(_ item: Item) {
      id = item.id
      title = item.title
      coverPath = item.coverPath
      qualityLabel = item.qualityLabel
      fileName = item.fileName
      state = item.state
      errorMessage = item.errorMessage
      addedAt = item.addedAt
      remoteURLString = item.remoteURLString
      progress = item.progress
      bytesWritten = item.bytesWritten
      bytesExpected = item.bytesExpected
      isPaused = item.isPaused
    }

    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      id = try c.decode(UUID.self, forKey: .id)
      title = try c.decode(String.self, forKey: .title)
      coverPath = try c.decodeIfPresent(String.self, forKey: .coverPath)
      qualityLabel = try c.decode(String.self, forKey: .qualityLabel)
      fileName = try c.decode(String.self, forKey: .fileName)
      state = try c.decode(Item.State.self, forKey: .state)
      errorMessage = try c.decodeIfPresent(String.self, forKey: .errorMessage)
      addedAt = try c.decode(Date.self, forKey: .addedAt)
      remoteURLString = try c.decodeIfPresent(String.self, forKey: .remoteURLString) ?? ""
      progress = try c.decodeIfPresent(Double.self, forKey: .progress) ?? 0
      bytesWritten = try c.decodeIfPresent(Int64.self, forKey: .bytesWritten) ?? 0
      bytesExpected = try c.decodeIfPresent(Int64.self, forKey: .bytesExpected) ?? 0
      isPaused = try c.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
    }
  }

  func persistItems() {
    let payload = items.map(PersistedItem.init)
    guard let data = try? JSONEncoder().encode(payload) else { return }
    let url = Self.indexFileURL
    try? FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try? data.write(to: url, options: .atomic)
  }

  static func loadPersistedItems() -> [Item] {
    let dir = (try? persistedDownloadsDirectory(ensureExists: true))
    let indexURL = indexFileURL

    var records: [PersistedItem] = []
    if let data = try? Data(contentsOf: indexURL),
      let decoded = try? JSONDecoder().decode([PersistedItem].self, from: data)
    {
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
        items.append(
          Item(
            id: UUID(),
            title: titleGuess(fromFileName: name),
            coverPath: nil,
            qualityLabel: qualityLabel(fromFileName: name),
            fileName: name,
            progress: 1,
            bytesWritten: 0,
            bytesExpected: 0,
            state: .completed,
            localFileURL: fileURL,
            errorMessage: nil,
            addedAt:
              (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
              ?? .distantPast,
            remoteURLString: ""
          )
        )
      }
    }

    return items.sorted { $0.addedAt > $1.addedAt }
  }

  private static var indexFileURL: URL {
    let base =
      FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.temporaryDirectory
    return base.appendingPathComponent("VideoDownloadsIndex.json")
  }

  static func item(from record: PersistedItem, downloadsDir: URL?) -> Item {
    var state = record.state
    var error = record.errorMessage
    var localURL: URL?
    var waitingForNetwork = false

    let savedProgress = record.progress
    let savedWritten = record.bytesWritten
    let savedExpected = record.bytesExpected

    if state == .downloading {
      if record.isPaused {
        waitingForNetwork = false
      } else if savedProgress > 0 || savedWritten > 0 {
        waitingForNetwork = false
      } else {
        waitingForNetwork = true
      }
      error = nil
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

    let progress: Double = {
      if state == .completed { return 1 }
      if savedProgress > 0 { return min(1, savedProgress) }
      if savedExpected > 0, savedWritten > 0 {
        return min(1, Double(savedWritten) / Double(savedExpected))
      }
      return 0
    }()

    return Item(
      id: record.id,
      title: record.title,
      coverPath: record.coverPath,
      qualityLabel: record.qualityLabel,
      fileName: record.fileName,
      progress: progress,
      bytesWritten: savedWritten,
      bytesExpected: savedExpected,
      state: state,
      localFileURL: localURL,
      errorMessage: error,
      addedAt: record.addedAt,
      remoteURLString: record.remoteURLString,
      isWaitingForNetwork: waitingForNetwork,
      isPaused: record.isPaused
    )
  }

  /// 文件名 → 片名（`我的电影-原画.mp4` → `我的电影`）。
  static func titleGuess(fromFileName name: String) -> String {
    let base = (name as NSString).deletingPathExtension
    for quality in downloadQualitySuffixes {
      let suffix = "-\(quality)"
      if base.hasSuffix(suffix) {
        return String(base.dropLast(suffix.count))
      }
    }
    return base
  }

  static func qualityLabel(fromFileName name: String) -> String {
    let base = (name as NSString).deletingPathExtension
    for quality in downloadQualitySuffixes where base.hasSuffix("-\(quality)") {
      return quality
    }
    return "本地"
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

  /// 委托线程：在临时文件被删前复制到用户目录。
  nonisolated static func persistDownload(from tempLocation: URL, to destination: URL) throws {
    let fm = FileManager.default
    let dir = destination.deletingLastPathComponent()
    try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    if fm.fileExists(atPath: destination.path) {
      try fm.removeItem(at: destination)
    }
    try fm.copyItem(at: tempLocation, to: destination)
  }
}