import Foundation

/// 业务 API 域名列表；探测用 `hostBases`，真正请求用带 `v2.5` 的 `bases`。
enum OneTargets {
    /// 业务 API 版本目录（拼在域名后，如 `…/v2.5/navigation/…`）
    static let apiVersion = "v2.5"

    /// 域名根线路；仅用于 `domain/check` 探测，不含版本路径。
    static let hostBases: [String] = [
        "https://api.3459381.com", // 探测 domain/check，业务请求拼成 …/v2.5/
        "https://api.87735d5.com",
        "https://api.em1oifd0.com",
        "https://api.c6dd5cc.com",
    ]

    /// 业务 API 根：`{host}/v2.5`，例如 `https://api.3459381.com/v2.5` → `navigation/getDemandTagList`
    static let bases: [String] = hostBases.map { host in
        let root = host.hasSuffix("/") ? String(host.dropLast()) : host
        return "\(root)/\(apiVersion)"
    }
}
