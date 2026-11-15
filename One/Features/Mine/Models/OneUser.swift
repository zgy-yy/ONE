import Foundation

/// 登录用户（`user/login` 的 `data.user`，只保留 App 会用到的字段）。
struct OneUser: Codable, Hashable, Identifiable {
    let id: Int
    let username: String?
    let nickname: String?
    let avatar: String?
    let avatarThumbnail: String?
    let mobile: String?
    let userKey: String?
    let integral: Int?
    let wallet: Int?
    let vipLevel: Int?
    let activeLevel: Int?
    let token: String?
    let loggedAt: String?

    var displayName: String {
        nickname?.nonEmpty ?? username?.nonEmpty ?? "用户 \(id)"
    }

    var displayMobile: String {
        mobile?.nonEmpty ?? "—"
    }

    var avatarPath: String? {
        avatar?.nonEmpty ?? avatarThumbnail?.nonEmpty
    }

    enum CodingKeys: String, CodingKey {
        case id, username, nickname, avatar, mobile, integral, wallet, token
        case avatarThumbnail = "avatar_thumbnail"
        case userKey = "user_key"
        case vipLevel = "vip_level"
        case activeLevel = "active_level"
        case loggedAt = "logged_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = JSONFlex.int(c, .id) else {
            throw DecodingError.keyNotFound(
                CodingKeys.id,
                .init(codingPath: c.codingPath, debugDescription: "缺少用户 id")
            )
        }
        self.id = id
        username = JSONFlex.string(c, .username)
        nickname = JSONFlex.string(c, .nickname)
        avatar = JSONFlex.string(c, .avatar)
        avatarThumbnail = JSONFlex.string(c, .avatarThumbnail)
        mobile = JSONFlex.string(c, .mobile)
        userKey = JSONFlex.string(c, .userKey)
        integral = JSONFlex.int(c, .integral)
        wallet = JSONFlex.int(c, .wallet)
        vipLevel = JSONFlex.int(c, .vipLevel)
        activeLevel = JSONFlex.int(c, .activeLevel)
        token = JSONFlex.string(c, .token)
        loggedAt = JSONFlex.string(c, .loggedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(username, forKey: .username)
        try c.encodeIfPresent(nickname, forKey: .nickname)
        try c.encodeIfPresent(avatar, forKey: .avatar)
        try c.encodeIfPresent(avatarThumbnail, forKey: .avatarThumbnail)
        try c.encodeIfPresent(mobile, forKey: .mobile)
        try c.encodeIfPresent(userKey, forKey: .userKey)
        try c.encodeIfPresent(integral, forKey: .integral)
        try c.encodeIfPresent(wallet, forKey: .wallet)
        try c.encodeIfPresent(vipLevel, forKey: .vipLevel)
        try c.encodeIfPresent(activeLevel, forKey: .activeLevel)
        try c.encodeIfPresent(token, forKey: .token)
        try c.encodeIfPresent(loggedAt, forKey: .loggedAt)
    }
}

/// `user/login` 的 `data`。
struct LoginPayload: Decodable {
    let user: OneUser
}
