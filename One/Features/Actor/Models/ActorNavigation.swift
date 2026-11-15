import Foundation

/// `actor/getMainNavigations` 的分类项。
struct ActorNavigation: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String?
    let sort: Int?
    let tags: [ActorNavTag]?

    var displayName: String {
        if let name, !name.isEmpty { return name }
        return "分类 \(id)"
    }

    var displayTags: [ActorNavTag] {
        tags ?? []
    }
}

/// 分类下的标签（如「有码」「无码」）。
struct ActorNavTag: Decodable, Identifiable, Hashable {
    let id: Int
    let slug: String?

    var displayName: String {
        let name = slug?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !name.isEmpty { return name }
        return "标签 \(id)"
    }
}

/// `data.list` 包裹。
struct ActorNavigationsPayload: Decodable {
    let list: [ActorNavigation]?
}
