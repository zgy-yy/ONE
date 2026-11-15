import SwiftUI
import Observation

/// 右下角搜索按钮显隐：跟随主列表滚动（下滚隐藏、上滚 / 到顶显示）。
@MainActor
@Observable
final class SearchFABChrome {
    static let shared = SearchFABChrome()

    private(set) var isHidden = false
    private var lastOffsetY: CGFloat?

    private init() {}

    func handleScroll(offsetY: CGFloat) {
        defer { lastOffsetY = offsetY }
        if offsetY <= 8 {
            isHidden = false
            return
        }
        guard let lastOffsetY else { return }
        let delta = offsetY - lastOffsetY
        if delta > 8 {
            isHidden = true
        } else if delta < -8 {
            isHidden = false
        }
    }

    func reset() {
        isHidden = false
        lastOffsetY = nil
    }
}

extension View {
    /// 挂载右下角搜索入口，并监听滚动显隐。
    func withSearchFAB(isPresented: Binding<Bool>) -> some View {
        modifier(SearchFABModifier(showsSearch: isPresented))
    }

    /// 搜索以大卡片 sheet 弹出。
    func searchCardSheet(isPresented: Binding<Bool>) -> some View {
        sheet(
            isPresented: Binding(
                get: { isPresented.wrappedValue },
                set: { open in
                    isPresented.wrappedValue = open
                    if !open { SearchFABChrome.shared.reset() }
                }
            )
        ) {
            SearchView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(16)
        }
    }
}

/// 右下角搜索悬浮按钮（滚动时隐藏）。
private struct SearchFABModifier: ViewModifier {
    @Binding var showsSearch: Bool
    @Bindable private var fab = SearchFABChrome.shared

    func body(content: Content) -> some View {
        content
            .onAppear { fab.reset() }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showsSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Color.accentColor, in: Circle())
                        .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("搜索")
                .padding(.trailing, 18)
                .padding(.bottom, 18)
                .opacity(fab.isHidden ? 0 : 1)
                .offset(y: fab.isHidden ? 24 : 0)
                .allowsHitTesting(!fab.isHidden)
                .animation(.easeInOut(duration: 0.22), value: fab.isHidden)
            }
    }
}
