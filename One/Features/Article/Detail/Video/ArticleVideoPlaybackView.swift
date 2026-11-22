import AVFoundation
import SwiftUI
import UIKit

/// 全屏播放（底部进度条 + 快退 / 暂停·播放 / 快进，布局参考 SenPlayer）。
struct ArticleVideoPlaybackView: View {
    let url: URL
    /// 详情里展示的分辨率文案，优先用于自动旋转（如 `1920x1080`）。
    let declaredContentSize: CGSize?

    @Environment(\.dismiss) private var dismiss

    @State private var player: AVPlayer
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isScrubbing = false
    @State private var showsControls = true

    @State private var timeObserver: PlayerPeriodicObserver?
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var scrubGate = PlaybackScrubState()
    @State private var autoRotationApplied = false
    @State private var userOverrodeRotation = false
    @State private var contentRotation: Double = 0
    @State private var containerSize: CGSize = .zero
    @State private var isSeekLoading = false
    @State private var seekOperationsInFlight = 0

    private let skipInterval: Double = 15
    private let controlAutoHide: Duration = .seconds(3)

    init(url: URL, quality: String? = nil) {
        self.url = url
        declaredContentSize = ArticleVideoDeclaredResolution.parse(quality: quality)
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black

                rotatedPlaybackStage(containerSize: proxy.size)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear {
                containerSize = proxy.size
                applyDeclaredRotation(containerSize: proxy.size)
                Task { await applyContentRotationIfNeeded(containerSize: proxy.size) }
            }
            .onChange(of: proxy.size) { _, newSize in
                containerSize = newSize
                guard newSize.width > 0, newSize.height > 0 else { return }
                applyDeclaredRotation(containerSize: newSize)
                Task { await applyContentRotationIfNeeded(containerSize: newSize) }
            }
        }
        .ignoresSafeArea()
        .onAppear { startPlayback() }
        .onDisappear { tearDown() }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    // MARK: - 视频 + 控件（同轴旋转）

    private func rotatedPlaybackStage(containerSize: CGSize) -> some View {
        let stage = PlaybackContentRotation.stageSize(for: containerSize, rotation: contentRotation)

        return ZStack {
            ArticleVideoPlayerLayerView(player: player)
                .frame(width: stage.width, height: stage.height)

            if isSeekLoading {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                    .playbackControlShadow()
            }

            if showsControls {
                VStack {
                    topBar
                    Spacer()
                    bottomTransportBar
                }
                .transition(.opacity)
            }
        }
        .frame(width: stage.width, height: stage.height)
        .contentShape(Rectangle())
        .onTapGesture { toggleControlsVisibility() }
        .rotationEffect(.degrees(contentRotation))
        .animation(.easeInOut(duration: 0.28), value: contentRotation)
        .animation(.easeInOut(duration: 0.22), value: showsControls)
        .position(x: containerSize.width / 2, y: containerSize.height / 2)
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .playbackControlShadow()
            }
            .accessibilityLabel("关闭播放")

            Spacer()

            Button {
                userOverrodeRotation = true
                withAnimation(.easeInOut(duration: 0.28)) {
                    contentRotation = PlaybackContentRotation.toggleDegrees(contentRotation)
                }
                scheduleAutoHideControls()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .playbackControlShadow()
            }
            .accessibilityLabel("旋转画面")

            ArticleVideoAirPlayRoutePicker()
                .frame(width: 44, height: 44)
                .playbackControlShadow()
                .accessibilityLabel("投屏")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var bottomTransportBar: some View {
        VStack(spacing: 12) {
            progressRow
            transportButtons
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var progressRow: some View {
        HStack(spacing: 10) {
            Text(formatTime(currentTime))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white)
                .playbackControlShadow()
                .frame(minWidth: 44, alignment: .leading)

            Slider(
                value: sliderBinding,
                in: 0...max(duration, 0.01)
            ) { editing in
                isScrubbing = editing
                scrubGate.isScrubbing = editing
                if editing {
                    cancelAutoHide()
                    showsControls = true
                } else {
                    showsControls = true
                    cancelAutoHide()
                    seek(to: currentTime, precise: true, onFinished: scheduleAutoHideControls)
                }
            }
            .tint(.white.opacity(0.95))
            .accessibilityLabel("播放进度")

            Text(formatTime(duration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white)
                .playbackControlShadow()
                .frame(minWidth: 44, alignment: .trailing)
        }
    }

    private var transportButtons: some View {
        HStack(spacing: 52) {
            transportButton(
                systemName: "gobackward.\(Int(skipInterval))",
                label: "快退 \(Int(skipInterval)) 秒"
            ) {
                skip(by: -skipInterval)
            }

            transportButton(
                systemName: isPlaying ? "pause.fill" : "play.fill",
                label: isPlaying ? "暂停" : "播放",
                prominent: true
            ) {
                togglePlayPause()
            }

            transportButton(
                systemName: "goforward.\(Int(skipInterval))",
                label: "快进 \(Int(skipInterval)) 秒"
            ) {
                skip(by: skipInterval)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    private func transportButton(
        systemName: String,
        label: String,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: prominent ? 26 : 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: prominent ? 52 : 44, height: prominent ? 52 : 44)
                .playbackControlShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var sliderBinding: Binding<Double> {
        Binding(
            get: { currentTime },
            set: { newValue in
                currentTime = newValue
                if scrubGate.isScrubbing {
                    seek(to: newValue, precise: false)
                }
            }
        )
    }

    // MARK: - Playback

    private func startPlayback() {
        VideoPlaybackAudio.activate()
        player.isMuted = false
        player.allowsExternalPlayback = true
        player.automaticallyWaitsToMinimizeStalling = true
        player.play()
        isPlaying = true

        let gate = scrubGate
        timeObserver = PlayerPeriodicObserver(player: player, interval: 0.35) { time in
            guard !gate.isScrubbing else { return }
            currentTime = time
            if duration <= 0, let d = player.currentItem?.duration.cmSeconds, d.isFinite, d > 0 {
                duration = d
            }
            if !autoRotationApplied, !userOverrodeRotation, containerSize.width > 0 {
                Task {
                    await applyContentRotationIfNeeded(containerSize: containerSize)
                }
            }
        }
        Task {
            await loadDuration()
            await retryAutoRotationUntilReady()
        }
        scheduleAutoHideControls()
    }

    private func retryAutoRotationUntilReady() async {
        guard !userOverrodeRotation else { return }
        for attempt in 0 ..< 25 {
            if autoRotationApplied { return }
            let size = await MainActor.run { containerSize }
            guard size.width > 0, size.height > 0 else {
                try? await Task.sleep(for: .milliseconds(attempt < 3 ? 100 : 200))
                continue
            }
            await applyContentRotationIfNeeded(containerSize: size)
            if autoRotationApplied { return }
            try? await Task.sleep(for: .milliseconds(attempt < 3 ? 100 : 200))
        }
    }

    private func applyDeclaredRotation(containerSize: CGSize) {
        guard let declaredContentSize else { return }
        applyContentRotation(contentSize: declaredContentSize, containerSize: containerSize)
    }

    private func applyContentRotation(contentSize: CGSize, containerSize: CGSize) {
        guard !userOverrodeRotation, !autoRotationApplied else { return }
        guard containerSize.width > 0, containerSize.height > 0 else { return }
        guard PlaybackContentRotation.isValidPixelSize(contentSize) else { return }

        let degrees = PlaybackContentRotation.autoDegrees(
            contentSize: contentSize,
            containerSize: containerSize
        )
        withAnimation(.easeInOut(duration: 0.28)) {
            contentRotation = degrees
        }
        autoRotationApplied = true
    }

    private func applyContentRotationIfNeeded(containerSize: CGSize) async {
        guard !userOverrodeRotation else { return }
        guard containerSize.width > 0, containerSize.height > 0 else { return }
        if autoRotationApplied { return }

        if let declaredContentSize {
            await MainActor.run {
                applyContentRotation(contentSize: declaredContentSize, containerSize: containerSize)
            }
            return
        }

        var contentSize: CGSize?
        if let item = player.currentItem {
            _ = try? await item.asset.load(.tracks)
            contentSize = await ArticleVideoAspect.encodedSize(for: item.asset)
        }
        if contentSize == nil {
            contentSize = await ArticleVideoAspect.encodedSize(url: url)
        }
        guard let contentSize, PlaybackContentRotation.isValidPixelSize(contentSize) else { return }

        await MainActor.run {
            applyContentRotation(contentSize: contentSize, containerSize: containerSize)
        }
    }

    private func tearDown() {
        cancelAutoHide()
        timeObserver?.invalidate()
        timeObserver = nil
        player.pause()
    }

    private func loadDuration() async {
        guard let item = player.currentItem else { return }
        guard let loaded = try? await item.asset.load(.duration) else { return }
        let seconds = loaded.cmSeconds
        guard seconds.isFinite, seconds > 0 else { return }
        await MainActor.run { duration = seconds }
    }

    private func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        if isPlaying {
            scheduleAutoHideControls()
        } else {
            cancelAutoHide()
            showsControls = true
        }
    }

    private func skip(by delta: Double) {
        let target = min(max(0, currentTime + delta), max(duration, 0))
        seek(to: target, precise: true, onFinished: scheduleAutoHideControls)
    }

    private func beginSeekOperation() {
        seekOperationsInFlight += 1
        isSeekLoading = true
    }

    private func endSeekOperation() {
        seekOperationsInFlight = max(0, seekOperationsInFlight - 1)
        if seekOperationsInFlight == 0 {
            isSeekLoading = false
        }
    }

    private func seek(to seconds: Double, precise: Bool, onFinished: (() -> Void)? = nil) {
        beginSeekOperation()
        let clamped = min(max(0, seconds), max(duration, 0))
        let time = CMTime(seconds: clamped, preferredTimescale: 600)
        let tolerance = precise
            ? CMTime.zero
            : CMTime(seconds: 0.12, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: tolerance, toleranceAfter: tolerance) { finished in
            Task { @MainActor in
                currentTime = clamped
                if finished {
                    await waitUntilVideoReadyAtSeek()
                }
                endSeekOperation()
                onFinished?()
            }
        }
    }

    /// 进度跳转后：缓冲到可播或超时即收起 loading。
    private func waitUntilVideoReadyAtSeek() async {
        for _ in 0 ..< 30 {
            let item = player.currentItem
            if item?.isPlaybackLikelyToKeepUp == true || item?.status == .readyToPlay {
                return
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    private func toggleControlsVisibility() {
        showsControls.toggle()
        if showsControls, isPlaying {
            scheduleAutoHideControls()
        } else {
            cancelAutoHide()
        }
    }

    private func scheduleAutoHideControls() {
        cancelAutoHide()
        guard isPlaying else { return }
        hideControlsTask = Task {
            try? await Task.sleep(for: controlAutoHide)
            guard !Task.isCancelled, isPlaying, !isScrubbing, !isSeekLoading else { return }
            await MainActor.run { showsControls = false }
        }
    }

    private func cancelAutoHide() {
        hideControlsTask?.cancel()
        hideControlsTask = nil
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}
