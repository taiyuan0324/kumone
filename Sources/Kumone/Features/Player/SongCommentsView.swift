import SwiftUI

/// Song comments sheet shown from the now-playing page.
struct SongCommentsSheet: View {
    @EnvironmentObject private var player: PlayerService
    @Environment(\.dismiss) private var dismiss

    let track: Track

    @State private var hotComments: [NeteaseAPI.SongComment] = []
    @State private var comments: [NeteaseAPI.SongComment] = []
    @State private var totalCount = 0
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var hasMore = false
    @State private var errorMessage: String?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    songHeader

                    if isLoading && comments.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding(.vertical, 40)
                            Spacer()
                        }
                    } else if errorMessage != nil && comments.isEmpty {
                        errorView
                    } else {
                        if !hotComments.isEmpty {
                            sectionHeader("热门评论")
                            ForEach(hotComments) { comment in
                                commentRow(comment)
                                Divider().padding(.leading, 62)
                            }
                        }

                        sectionHeader("最新评论")
                        if comments.isEmpty {
                            Text("还没有评论")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        } else {
                            ForEach(comments) { comment in
                                commentRow(comment)
                                Divider().padding(.leading, 62)
                            }
                        }

                        if hasMore {
                            Button {
                                Task { await loadMore() }
                            } label: {
                                HStack {
                                    Spacer()
                                    if isLoadingMore {
                                        ProgressView()
                                            .padding(.vertical, 12)
                                    } else {
                                        Text("加载更多")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .padding(.vertical, 12)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .background(Color(Platform.windowBackgroundColor))
            .navigationTitle("评论")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text("关闭")
                    }
                }
            }
            .task {
                await loadComments()
            }
        }
    }

    private var songHeader: some View {
        HStack(spacing: 10) {
            CachedAsyncImage(url: track.album.picUrl?.resizedImageURL(64))
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(track.artistNames)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func commentRow(_ comment: NeteaseAPI.SongComment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            CachedAsyncImage(url: comment.user.avatarURL)
                .frame(width: 38, height: 38)
                .clipShape(Circle())
                .overlay(
                    Circle().strokeBorder(.primary.opacity(0.08), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.user.nickname)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    if comment.isOwner {
                        Text("作者")
                            .font(.caption2)
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Theme.accent.opacity(0.12), in: Capsule())
                    }
                }

                Text(comment.content)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)

                HStack(spacing: 12) {
                    Text(comment.formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if let location = comment.ipLocation {
                        Text("· \(location)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    HStack(spacing: 3) {
                        Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 11))
                        if comment.likedCount > 0 {
                            Text("\(comment.likedCount)")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(comment.isLiked ? Theme.accent : .secondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var errorView: some View {
        VStack(spacing: 12) {
            Label("评论加载失败", systemImage: "exclamationmark.bubble")
                .font(.headline)
            if let errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button(action: { Task { await loadComments() } }) {
                Text("重试")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func loadComments() async {
        isLoading = true
        errorMessage = nil
        comments = []
        hotComments = []
        do {
            let response = try await NeteaseAPI.songComments(id: track.id, offset: 0, limit: 20)
            hotComments = response.hotComments
            comments = response.comments
            totalCount = response.total
            hasMore = response.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadMore() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let response = try await NeteaseAPI.songComments(
                id: track.id,
                offset: comments.count,
                limit: 20
            )
            comments.append(contentsOf: response.comments)
            hasMore = response.hasMore
            totalCount = response.total
        } catch {
            // silently ignore pagination errors
        }
    }
}
