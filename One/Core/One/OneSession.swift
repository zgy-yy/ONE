import Foundation
import Observation

/// 业务 API 线路会话：保存选中的 `…/v2.5/` 基址（由 `OneClient.pickBaseURL` 写入）。
@MainActor
@Observable
final class OneSession {
    static let shared = OneSession()

    private(set) var baseURL: URL?
    private(set) var isLoading = false
    private(set) var lastError: String?

    private init() {}

    func prepare() async {
        guard baseURL == nil else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            baseURL = try await OneClient.pickBaseURL()
        } catch {
            lastError = error.localizedDescription
        }
    }

    var statusSummary: String {
        if isLoading { return "正在探测 ONE 线路…" }
        if let lastError { return lastError }
        if let baseURL {
            return "ONE: \(baseURL.absoluteString)"
        }
        return "ONE 线路未就绪"
    }
}
