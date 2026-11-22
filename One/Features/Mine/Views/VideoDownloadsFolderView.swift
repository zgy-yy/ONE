import QuickLook
import SwiftUI

/// 下载目录浏览：列出 `Documents/VideoDownloads` 内视频，可预览。
struct VideoDownloadsFolderView: View {
    /// 从下载列表点入时，滚动并高亮该文件名。
    var highlightFileName: String?

    @Bindable private var downloads = VideoDownloadSession.shared
    @Environment(\.dismiss) private var dismiss

    @State private var previewURL: URL?
    @State private var fileURLs: [URL] = []

    var body: some View {
        ScrollViewReader { scrollProxy in
            listContent(scrollProxy: scrollProxy)
        }
    }

    @ViewBuilder
    private func listContent(scrollProxy: ScrollViewProxy) -> some View {
        List {
            if let folder = downloads.downloadsFolderURL {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(folder.path)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        Text("也可在「文件」→ \(VideoDownloadSession.filesAppFolderHint)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("已保存视频") {
                if fileURLs.isEmpty {
                    Text("暂无文件")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(fileURLs, id: \.path) { url in
                        Button {
                            previewURL = url
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "film")
                                    .font(.title2)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 36)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(url.deletingPathExtension().lastPathComponent)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                    Text(byteSizeText(for: url))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 8)
                                Image(systemName: "play.circle")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .id(url.path)
                        .listRowBackground(
                            isHighlighted(url)
                                ? Color.accentColor.opacity(0.14)
                                : Color.clear
                        )
                    }
                }
            }
        }
        .navigationTitle("下载文件夹")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") { dismiss() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("刷新") { reloadFiles() }
            }
        }
        .onAppear {
            reloadFiles()
            scrollToHighlightIfNeeded(using: scrollProxy)
        }
        .onChange(of: fileURLs.map(\.path)) { _, _ in
            scrollToHighlightIfNeeded(using: scrollProxy)
        }
        .quickLookPreview($previewURL)
    }

    private func isHighlighted(_ url: URL) -> Bool {
        guard let highlightFileName, !highlightFileName.isEmpty else { return false }
        return url.lastPathComponent == highlightFileName
    }

    private func scrollToHighlightIfNeeded(using proxy: ScrollViewProxy) {
        guard let highlightFileName,
              let url = fileURLs.first(where: { $0.lastPathComponent == highlightFileName })
        else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(url.path, anchor: .center)
            }
        }
    }

    private func reloadFiles() {
        fileURLs = downloads.savedVideoFileURLs()
    }

    private func byteSizeText(for url: URL) -> String {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}