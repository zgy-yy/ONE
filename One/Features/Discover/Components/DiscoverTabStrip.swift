import SwiftUI

/// 发现页顶栏：发布日期 / 排序 + 频道 Tab。
struct DiscoverTopBar: View {
    @Binding var channel: DiscoverChannel
    @Bindable var session: DiscoverSession

    var body: some View {
        VStack(spacing: 0) {
            FilterBar(publishedAt: $session.listPublishedAt, sort: $session.listSort)
            channelStrip
            Divider()
        }
        .background(Color(.systemBackground))
    }

    private var channelStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DiscoverChannel.allCases) { item in
                        chip(item)
                            .id(item)
                            .onTapGesture { channel = item }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .onAppear {
                proxy.scrollTo(channel, anchor: .center)
            }
            .onChange(of: channel) { _, newValue in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private func chip(_ item: DiscoverChannel) -> some View {
        let selected = channel == item
        return Text(item.title)
            .font(.subheadline.weight(selected ? .semibold : .regular))
            .foregroundStyle(selected ? Color.accentColor : Color.secondary)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background {
                Capsule().fill(selected ? Color.accentColor.opacity(0.14) : Color.clear)
            }
            .contentShape(Capsule())
            .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}
