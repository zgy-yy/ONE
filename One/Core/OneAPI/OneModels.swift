import Foundation

enum OneAPI {
    /// 相对 `OneTargets.bases`（已含 `v2.5`）
    static let demandTagListPath = "navigation/getDemandTagList"

    static func isSuccess(code: Int?) -> Bool {
        code == 200 || code == 400
    }
}

struct OneApiEnvelope<T: Decodable>: Decodable {
    let code: Int?
    let message: String?
    let data: T?
}

struct DemandTag: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?
}
