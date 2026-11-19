import SwiftUI

/// 评论行：主楼 / 回复缩进区分；默认 3 条回复，可展开；支持最新 / 最热。
struct CommentRow: View {
    let comment: CommentItem
    var isReply: Bool = false
    var loadReplies: ((CommentItem) async -> [CommentItem])? = nil

    @State private var showsViewer = false
    @State private var viewerSelection = 0
    @State private var showAll = false
    @State private var replySort: CommentSort = .likes
    @State private var fetchedReplies: [CommentItem]?
    @State private var isLoadingReplies = false

    private let replyIndent: CGFloat = 36
    private let previewCount = 3

    private var replies: [CommentItem] {
        (fetchedReplies ?? comment.replies).sorted(by: replySort)
    }

    private var visibleReplies: [CommentItem] {
        showAll ? replies : Array(replies.prefix(previewCount))
    }

    private var replyTotal: Int {
        max(comment.replyTotal, replies.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isReply ? 6 : 8) {
            header
            if !comment.displayText.isEmpty {
                Text(comment.displayText)
                    .font(isReply ? .subheadline : .body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            imageGrid
            if let created = comment.createdAt?.nonEmpty {
                Text(created)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if !isReply, replyTotal > 0 {
                repliesBlock
            }
        }
        .padding(.vertical, isReply ? 6 : 8)
        .padding(.leading, isReply ? replyIndent : 0)
        .fullScreenCover(isPresented: $showsViewer) {
            FullscreenImageViewer(paths: comment.viewerImagePaths, selection: $viewerSelection)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            UserAvatarImage(path: comment.avatarPath, size: isReply ? 28 : 36)
            Text(comment.displayAuthor)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Spacer(minLength: 8)
            if let likes = comment.likes, likes > 0 {
                Label("\(likes)", systemImage: "hand.thumbsup")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private var imageGrid: some View {
        let paths = comment.displayImagePaths
        if !paths.isEmpty {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(Array(paths.enumerated()), id: \.offset) { index, path in
                    Button {
                        viewerSelection = index
                        showsViewer = true
                    } label: {
                        CommentImageThumb(path: path)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var repliesBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer(minLength: 0)
                CommentSortPicker(sort: $replySort, compact: true)
            }
            .padding(.leading, replyIndent)

            if isLoadingReplies, visibleReplies.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            ForEach(visibleReplies) { reply in
                CommentRow(comment: reply, isReply: true)
            }

            if replyTotal > previewCount {
                Button {
                    showAll.toggle()
                    if showAll, replies.count < comment.replyTotal {
                        Task { await refreshReplies() }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if isLoadingReplies { ProgressView().controlSize(.mini) }
                        Text(showAll ? "收起回复" : "查看全部 \(replyTotal) 条回复")
                        Image(systemName: showAll ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, replyIndent)
            }
        }
        .padding(.top, 2)
    }

    @MainActor
    private func refreshReplies() async {
        guard let loadReplies, !isLoadingReplies else { return }
        isLoadingReplies = true
        defer { isLoadingReplies = false }
        let loaded = await loadReplies(comment)
        if loaded.count > replies.count { fetchedReplies = loaded }
    }
}

private struct CommentImageThumb: View {
    let path: String
    @State private var uiImage: UIImage?

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let uiImage {
                    Image(uiImage: uiImage).resizable().scaledToFill()
                } else {
                    ZStack {
                        Color(.tertiarySystemFill)
                        ProgressView()
                    }
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .task(id: path) { uiImage = await OneRemoteImage.load(path: path) }
    }
}
