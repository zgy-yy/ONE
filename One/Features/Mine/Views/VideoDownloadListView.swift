import SwiftUI

/// 我的 → 下载：进度列表；完成文件写入 `Documents/VideoDownloads`，在「文件」App 可见。
struct VideoDownloadListView: View {
    @Bindable private var downloads = VideoDownloadSession.shared

    @State private var showsFolderBrowser = false

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
                        VideoDownloadRow(item: item)
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
        .sheet(isPresented: $showsFolderBrowser) {
            NavigationStack {
                VideoDownloadsFolderView()
            }
            .presentationDragIndicator(.visible)
        }
    }

    private func openDownloadsFolder() {
        Task {
            if await !downloads.openDownloadsFolderInFilesApp() {
                showsFolderBrowser = true
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

    private let coverWidth: CGFloat = 148

    private var coverHeight: CGFloat {
        CoverAspect.height(width: coverWidth)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            cover
                .frame(width: coverWidth)
                .accessibilityHidden(item.coverPath == nil)

            infoColumn
                .frame(maxWidth: .infinity, minHeight: coverHeight, maxHeight: coverHeight, alignment: .topLeading)
        }
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
                ZStack {
                    Color.black.opacity(0.32)
                    VStack(spacing: 6) {
                        if item.progress > 0 {
                            ProgressView(value: item.progress) {
                                EmptyView()
                            }
                            .progressViewStyle(.circular)
                            .controlSize(.regular)
                            .tint(.white)
                            Text(item.progressText)
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                        } else {
                            ProgressView()
                                .controlSize(.regular)
                                .tint(.white)
                            Text(item.progressText)
                                .font(.caption.weight(.medium))
                        }
                    }
                    .foregroundStyle(.white)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        switch item.state {
        case .downloading:
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("下载中 · \(item.progressText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer(minLength: 4)
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