import Foundation

/// 壳（Box）服务 IP 列表（多线路容灾）。
enum TokensTargets {
    static let bases: [String] = [
        "http://202.95.22.200:6868",
        "http://202.95.22.201:6868",
        "http://202.95.22.202:6868",
        "http://198.44.248.102:6868",
        "http://38.46.10.6:6868",
    ]
}
