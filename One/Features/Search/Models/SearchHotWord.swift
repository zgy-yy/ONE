import Foundation

/// `article/getHotWords` 单项。
struct SearchHotWord: Decodable, Identifiable, Hashable {
    let word: String
    let type: Int?
    let targetID: Int?

    var id: String { word }

    enum CodingKeys: String, CodingKey {
        case word, type
        case targetID = "target_id"
    }
}

/// `article/getHotWords` 的 `data`。
struct SearchHotWordsPayload: Decodable {
    let list: [SearchHotWord]?
}
