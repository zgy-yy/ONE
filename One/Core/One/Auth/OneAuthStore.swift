import Foundation

/// 登录态本地存储（UserDefaults）。请求头从此读取 token / user-key。
enum OneAuthStore {
    private static let storageKey = "one.auth.user"

    static var savedUser: OneUser? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(OneUser.self, from: data)
    }

    static var loginToken: String? {
        guard let token = savedUser?.token, !token.isEmpty else { return nil }
        return token
    }

    static var userKeyHeader: String {
        savedUser?.userKey ?? ""
    }

    static func save(_ user: OneUser) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
