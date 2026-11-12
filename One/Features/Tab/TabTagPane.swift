import SwiftUI

struct TabTagPane: View {
    let tag: DemandTag

    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 16) {
                Image(systemName: "circle.slash")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Color(white: 0.35))
                Text("无内容")
                    .font(.title3)
                    .foregroundStyle(Color(white: 0.35))
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
