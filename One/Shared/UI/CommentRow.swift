import SwiftUI

/// 评论行：主楼 / 回复缩进区分；默认 3 条回复，可展开；楼中楼支持最新 / 最热。
struct CommentRow: View {
    let comment: CommentItem
    var isReply: Bool = false
    var loadReplies: ((CommentItem, CommentSort) async -> [CommentItem])? = nil

    @State private var showsViewer = false
    @State private var viewerSelection = 0
    @State private var showAll = false
    @State private var replySort: CommentSort = .likes
    @State private var fetchedReplies: [CommentItem]?
    @State private var isLoadingReplies = false

    private let previewCount = 3

    private var replies: [CommentItem] {
        (fetchedReplies ?? comment.replies).sorted(by: replySort)
    }

    private var replyTotal: Int {
        max(comment.replyTotal, replies.count)
    }

    private var replyTaskID: String? {
        guard showAll, loadReplies != nil else { return nil }
        return replySort.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isReply ? 4 : 8) {
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
        .padding(.vertical, isReply ? 4 : 8)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                CommentSortPicker(sort: $replySort, style: .replyThread)
                if showAll {
                    replyTextButton("收起回复", color: .accentColor, fullWidth: false) { showAll = false }
                        .font(.caption2.weight(.medium))
                }
            }

            let visible = showAll ? replies : Array(replies.prefix(previewCount))
            ForEach(visible) { reply in
                CommentRow(comment: reply, isReply: true)
            }

            if showAll, isLoadingReplies, replies.count < replyTotal {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("加载回复…").font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            if replyTotal > previewCount {
                if showAll {
                    replyTextButton("收起全部") { showAll = false }
                        .padding(.top, 4)
                } else {
                    replyTextButton("查看全部 \(replyTotal) 条回复", chevronDown: true) { showAll = true }
                        .padding(.top, 2)
                }
            }
        }
        .padding(.leading, 14)
        .padding(.top, 2)
        .task(id: replyTaskID) {
            guard replyTaskID != nil else { return }
            await fetchReplies()
        }
    }

    private func replyTextButton(
        _ title: String,
        color: Color = .secondary,
        chevronDown: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if chevronDown {
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .leading)
    }

    private func fetchReplies() async {
        guard let loadReplies else { return }
        isLoadingReplies = true
        defer { isLoadingReplies = false }
        guard !Task.isCancelled else { return }
        fetchedReplies = await loadReplies(comment, replySort)
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