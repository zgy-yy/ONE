import Foundation

/// 从 `ActorDetail` / 列表摘要拼资料行。
enum ActorProfileFields {
    static func make(detail: ActorDetail?, actor: ActorSummary) -> [ActorDetailProfileHeader.Field] {
        let height = detail?.height?.nonEmpty.map { "\($0) cm" }
        return [
            .init(icon: "textformat", label: "中文名", value: dash(detail?.mainName ?? actor.displayName)),
            .init(icon: "globe.asia.australia", label: "日文名", value: dash(detail?.japaneseName)),
            .init(icon: "sparkles", label: "昵称", value: dash(detail?.nickname)),
            .init(icon: "tag", label: "别名", value: dash(detail?.aliasName)),
            .init(icon: "arrow.up.and.down", label: "身高", value: height ?? "-"),
            .init(icon: "rectangle.split.3x1", label: "三围", value: dash(detail?.bustWaistHip)),
            .init(icon: "mug", label: "罩杯", value: dash(detail?.cupSize)),
            .init(icon: "birthday.cake", label: "生日", value: dash(detail?.birthDate)),
            .init(icon: "person.badge.clock", label: "年龄", value: dash(detail?.age)),
        ]
    }

    private static func dash(_ value: String?) -> String {
        value?.nonEmpty ?? "-"
    }
}