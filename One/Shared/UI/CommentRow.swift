import SwiftUI

/// 评论列表单行（文章详情 / 演员详情共用）：头像、正文、配图、楼中楼回复。
struct CommentRow: View {
    let comment: CommentItem
    /// 是否为楼中楼样式（缩进、字号略小）。
    var isReply: Bool = false

    @State private var viewerIndex: Int?
    @State private var viewerSelection = 0

    private let imageColumns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

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
            repliesBlock
        }
        .padding(isReply ? 10 : 12)
        .background(
            (isReply ? Color(.tertiarySystemFill) : Color(.secondarySystemBackground)),
            in: RoundedRectangle(cornerRadius: isReply ? 8 : 10, style: .continuous)
        )
        .fullScreenCover(isPresented: Binding(
            get: { viewerIndex != nil },
            set: { if !$0 { viewerIndex = nil } }
        )) {
            FullscreenImageViewer(
                paths: comment.viewerImagePaths,
                selection: $viewerSelection
            )
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
            LazyVGrid(columns: imageColumns, spacing: 6) {
                ForEach(Array(paths.enumerated()), id: \.offset) { index, path in
                    Button {
                        openViewer(at: index)
                    } label: {
                        CommentImageThumb(path: path)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func openViewer(at index: Int) {
        let paths = comment.viewerImagePaths
        guard !paths.isEmpty else { return }
        let clamped = min(max(index, 0), paths.count - 1)
        viewerSelection = clamped
        viewerIndex = clamped
    }

    @ViewBuilder
    private var repliesBlock: some View {
        if !comment.replies.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(comment.replies) { reply in
                    CommentRow(comment: reply, isReply: true)
                }
            }
            .padding(.top, 4)
        } else if let count = comment.replyCount, count > 0 {
            Text("\(count) 条回复")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color(.tertiarySystemFill)
                        ProgressView()
                    }
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .task(id: path) {
                uiImage = await OneRemoteImage.load(path: path)
            }
    }
}
