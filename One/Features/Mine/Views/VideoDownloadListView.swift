import SwiftUI

/// 我的 → 下载列表（只绑 `VideoDownloadSession.shared`，不写网络逻辑）。
///
/// 已完成条目：点按 → `VideoDownloadsFolderView` 并定位到对应 mp4。
private struct DownloadFolderBrowseContext: Identifiable {
    let id = UUID()
    let highlightFileName: String?
}

struct VideoDownloadListView: View {
    @Bindable private var downloads = VideoDownloadSession.shared

    @State private var folderBrowseContext: DownloadFolderBrowseContext?

    var body: some View {
        VStack(spacing: 0) {
            if let banner = downloads.listBanner {
                downloadListBanner(banner)
            }

            if downloads.items.isEmpty {
                ContentUnavailableView {
                    Label("暂无下载", systemImage: "arrow.down.circle")
                } description: {
                    Text("在影视 / 点播详情点「下载」后，会出现在这里。")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(downloads.items) { item in
                        VideoDownloadRow(item: item, downloads: downloads) { fileName in
                            folderBrowseContext = DownloadFolderBrowseContext(highlightFileName: fileName)
                        }
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                            .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: deleteItems)

                    Section {
                        Button(action: openDownloadsFolder) {
                            HStack(alignment: .center, spacing: 12) {
                                Label("保存位置", systemImage: "folder")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 8)
                                Text(VideoDownloadSession.filesAppFolderHint)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.trailing)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .plainContentList()
            }
        }
        .navigationTitle("下载")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .sheet(item: $folderBrowseContext) { context in
            NavigationStack {
                VideoDownloadsFolderView(highlightFileName: context.highlightFileName)
            }
            .presentationDragIndicator(.visible)
        }
    }

    private func openDownloadsFolder() {
        Task {
            if await !downloads.openDownloadsFolderInFilesApp() {
                folderBrowseContext = DownloadFolderBrowseContext(highlightFileName: nil)
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = downloads.items[index]
            downloads.remove(item)
        }
    }

    private func downloadListBanner(_ banner: VideoDownloadSession.ListBanner) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: banner.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(banner.listIconColor)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            Text(banner.text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                downloads.clearListBanner()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("关闭提示")
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

private struct VideoDownloadRow: View {
    let item: VideoDownloadSession.Item
    @Bindable var downloads: VideoDownloadSession
    var onOpenSavedFile: (String) -> Void

    private let coverWidth: CGFloat = 148

    private var coverHeight: CGFloat {
        CoverAspect.height(width: coverWidth)
    }

    var body: some View {
        Group {
            if item.state == .completed {
                Button {
                    onOpenSavedFile(item.fileName)
                } label: {
                    rowContent
                }
                .buttonStyle(.plain)
                .accessibilityLabel("在文件夹中查看 \(item.title)")
            } else {
                rowContent
            }
        }
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: 12) {
            cover
                .frame(width: coverWidth)
                .accessibilityHidden(item.coverPath == nil)

            infoColumn
                .frame(maxWidth: .infinity, minHeight: coverHeight, maxHeight: coverHeight, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.body.weight(.medium))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            statusLine
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var cover: some View {
        OneCoverImage(
            path: item.coverPath,
            aspectRatio: CoverAspect.landscape,
            cornerRadius: 10
        )
        .overlay(alignment: .bottomTrailing) {
            Text(item.qualityLabel)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.55), in: Capsule())
                .padding(6)
        }
        .overlay {
            if item.state == .downloading {
                Button {
                    downloads.toggleDownloadPause(item)
                } label: {
                    Image(systemName: item.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 48))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.45), radius: 3, y: 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.isPaused ? "继续下载" : "暂停下载")
            }
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        switch item.state {
        case .downloading:
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.isPaused ? item.progressText : "下载中 · \(item.progressText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    if let speed = item.formattedDownloadSpeed {
                        Text(speed)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if item.formattedBytesWritten != nil || item.formattedBytesTotal != nil {
                    VStack(alignment: .trailing, spacing: 1) {
                        if let written = item.formattedBytesWritten {
                            Text(written)
                        }
                        if let total = item.formattedBytesTotal {
                            Text(total)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .font(.caption.monospacedDigit())
                }
            }
        case .completed:
            VStack(alignment: .leading, spacing: 4) {
                Label("已保存", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                if let url = item.localFileURL {
                    Text(url.lastPathComponent)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
            }
        case .failed:
            Text(item.errorMessage ?? "下载失败")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}

private extension VideoDownloadSession.ListBanner {
    var listIconColor: Color {
        switch self {
        case .completed: return .green
        case .duplicate: return .orange
        case .queued: return Color.accentColor
        }
    }
}