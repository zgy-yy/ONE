import Foundation
import Observation

/// 登录状态：发短信、登录、退出；用户写入 `OneAuthStore`。
@MainActor
@Observable
final class AuthSession {
    static let shared = AuthSession()

    private(set) var user: OneUser?
    private(set) var isSendingSMS = false
    private(set) var isLoggingIn = false
    private(set) var errorMessage: String?
    private(set) var smsCooldown = 0

    var isLoggedIn: Bool { user?.token?.nonEmpty != nil }

    private var cooldownTask: Task<Void, Never>?

    private init() {
        user = OneAuthStore.savedUser
    }

    func sendSMS(mobile: String, area: String = "86") async {
        let phone = normalizedPhone(mobile)
        guard phone.count == 11 else {
            errorMessage = "请输入 11 位手机号"
            return
        }
        guard smsCooldown == 0, !isSendingSMS else { return }

        isSendingSMS = true
        errorMessage = nil
        defer { isSendingSMS = false }

        do {
            try await OneClient.sendSMS(mobile: phone, area: area)
            startCooldown(60)
        } catch {
            errorMessage = Self.friendlyMessage(from: error, fallback: "验证码发送失败")
        }
    }

    func login(mobile: String, code: String, area: String = "86") async {
        let phone = normalizedPhone(mobile)
        let sms = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard phone.count == 11 else {
            errorMessage = "请输入 11 位手机号"
            return
        }
        guard sms.count >= 4 else {
            errorMessage = "请输入验证码"
            return
        }
        guard !isLoggingIn else { return }

        isLoggingIn = true
        errorMessage = nil
        defer { isLoggingIn = false }

        do {
            let payload = try await OneClient.userLogin(mobile: phone, code: sms, area: area)
            user = payload.user
            OneAuthStore.save(payload.user)
        } catch {
            errorMessage = Self.friendlyMessage(from: error, fallback: "登录失败")
        }
    }

    func logout() {
        cooldownTask?.cancel()
        cooldownTask = nil
        smsCooldown = 0
        user = nil
        errorMessage = nil
        OneAuthStore.clear()
        MineLibrarySession.shared.reset()
    }

    private func normalizedPhone(_ mobile: String) -> String {
        String(mobile.filter(\.isNumber))
    }

    private func startCooldown(_ seconds: Int) {
        cooldownTask?.cancel()
        smsCooldown = seconds
        cooldownTask = Task {
            while smsCooldown > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                smsCooldown -= 1
            }
        }
    }

    private static func friendlyMessage(from error: Error, fallback: String) -> String {
        if let api = error as? OneClientError {
            return api.localizedDescription
        }
        if error is DecodingError {
            return "\(fallback)：服务器数据格式异常"
        }
        let text = error.localizedDescription
        if text.localizedCaseInsensitiveContains("format")
            || text.localizedCaseInsensitiveContains("couldn't be read")
            || text.localizedCaseInsensitiveContains("could not be read")
        {
            return "\(fallback)：服务器数据格式异常"
        }
        return text
    }
}
