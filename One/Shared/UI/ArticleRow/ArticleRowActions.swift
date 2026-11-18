import Foundation

/// 列表行收藏 / 喜欢 / 播放的临时入口（待接真实接口）。
///
/// 标成 `nonisolated`：可直接作为 `Button(action:)` 方法引用；
/// 工程默认 MainActor 隔离时否则会报 actor-isolated-call。
nonisolated enum ArticleRowActions {
    static func favorite() {
        // TODO: 收藏
        print("收藏")
    }

    static func like() {
        // TODO: 喜欢
        print("喜欢")
    }

    static func play() {
        // TODO: 播放
        print("播放")
    }
}
