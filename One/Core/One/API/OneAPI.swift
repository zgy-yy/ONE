import Foundation

/// ONE 业务接口路径与响应约定。
enum OneAPI {
    /// 相对 `OneTargets.bases`（拼接后为含 `v2.5` 的基址）。
    static let demandTagListPath = "navigation/getDemandTagList"
    static let discoveryPath = "article/discovery"

    static func isSuccess(code: Int?) -> Bool {
        code == 200 || code == 400
    }
}

/// 通用 JSON 壳：`{ code, message, data }`。
struct OneApiEnvelope<T: Decodable>: Decodable {
    let code: Int?
    let message: String?
    let data: T?
}
