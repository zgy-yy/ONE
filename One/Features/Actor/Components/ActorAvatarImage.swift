import SwiftUI

/// 演员头像：竖图 3:4，走 `one_img` CDN。
struct ActorAvatarImage: View {
    let path: String?

    var body: some View {
        OneCoverImage(
            path: path,
            aspectRatio: CoverAspect.portrait,
            placeholderSystemName: "person.fill",
            cornerRadius: 8
        )
    }
}
