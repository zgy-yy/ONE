import Foundation
import Observation

@MainActor
@Observable
final class TabSession {
    static let shared = TabSession()

    private(set) var tags: [DemandTag] = []
    private(set) var isLoading = false
    private(set) var lastError: String?

    private init() {}

    func loadIfNeeded() async {
        guard tags.isEmpty, !isLoading else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        guard let base = OneSession.shared.baseURL else {
            lastError = OneClientError.baseNotReady.localizedDescription
            return
        }
        guard let token = TokensSession.shared.oneToken(forPath: OneAPI.demandTagListPath) else {
            lastError = OneClientError.missingToken.localizedDescription
            return
        }

        do {
            tags = try await OneClient.getDemandTagList(base: base, token: token)
        } catch {
            lastError = error.localizedDescription
        }
    }
}
