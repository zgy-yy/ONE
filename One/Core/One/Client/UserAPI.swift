import Foundation

/// 登录与「我的」相关接口（短信 / 登录 / 喜欢 / 收藏）。
extension OneClient {
    static func sendSMS(mobile: String, area: String = "86") async throws {
        let envelope = try await post(
            OneApiEnvelope<IgnoredJSON?>.self,
            path: OneAPI.sendSMSPath,
            data: ["mobile": mobile, "area": area]
        )
        _ = try unwrap(envelope)
    }

    static func userLogin(
        mobile: String,
        code: String,
        area: String = "86",
        loginType: Int = 0
    ) async throws -> LoginPayload {
        let envelope = try await post(
            OneApiEnvelope<LoginPayload>.self,
            path: OneAPI.userLoginPath,
            data: [
                "mobile": mobile,
                "area": area,
                "code": code,
                "login_type": String(loginType),
            ]
        )
        guard let payload = try unwrap(envelope) else {
            throw OneClientError.apiRejected("登录结果为空")
        }
        return payload
    }

    static func userLikeList(modelID: Int, seriesCategory: Int = 0) async throws -> UserLikeListPayload {
        var data = ["model_id": String(modelID)]
        if seriesCategory != 0 { data["series_category"] = String(seriesCategory) }
        let envelope = try await post(OneApiEnvelope<UserLikeListPayload>.self, path: OneAPI.userLikeListPath, data: data)
        guard let payload = try unwrap(envelope) else {
            throw OneClientError.apiRejected("喜欢列表为空")
        }
        return payload
    }

    static func collectFolderList(
        page: Int = 1,
        size: Int = 20,
        keyword: String = "",
        sortDim: String = "create_time",
        sortDesc: Int = 1
    ) async throws -> [CollectFolder] {
        let envelope = try await post(
            OneApiEnvelope<[CollectFolder]>.self,
            path: OneAPI.collectFolderListPath,
            data: [
                "page": String(page),
                "size": String(size),
                "keyword": keyword,
                "sort_dim": sortDim,
                "sort_desc": String(sortDesc),
            ]
        )
        return try unwrap(envelope) ?? []
    }

    /// 新建收藏夹（body：`folder_name`）。
    static func createCollectFolder(folderName: String) async throws {
        let envelope = try await post(
            OneApiEnvelope<IgnoredJSON?>.self,
            path: OneAPI.createCollectFolderPath,
            data: ["folder_name": folderName]
        )
        _ = try unwrap(envelope)
    }

    static func favorites(
        modelID: Int,
        seriesCategory: Int = 0,
        page: Int = 1,
        size: Int = 20,
        folderID: Int = 0,
        sort: String = "collect",
        sortDesc: Int = 1,
        keyword: String = "",
        purchaseStatus: String = ""
    ) async throws -> FavoritesPayload {
        let envelope = try await post(
            OneApiEnvelope<FavoritesPayload>.self,
            path: OneAPI.favoritesPath,
            data: [
                "model_id": String(modelID),
                "series_category": String(seriesCategory),
                "page": String(page),
                "size": String(size),
                "sort": sort,
                "sort_desc": String(sortDesc),
                "purchase_status": purchaseStatus,
                "user_collect_folder_id": String(folderID),
                "keyword": keyword,
            ]
        )
        guard let payload = try unwrap(envelope) else {
            throw OneClientError.apiRejected("收藏列表为空")
        }
        return payload
    }

}
