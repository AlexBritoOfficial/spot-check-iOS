import SwiftUI

struct MessagesScreen: View {
    struct ChatTarget: Identifiable, Hashable {
        let conversationID: UUID
        let otherUserID: UUID
        let otherUsername: String
        var id: UUID { conversationID }
    }

    @Environment(AuthManager.self) private var authManager
    @Environment(PresenceService.self) private var presenceService
    @Environment(MenuCoordinator.self) private var menuCoordinator

    @State private var conversations: [ConversationOverview] = []
    @State private var nearbySkaters: [Profile] = []
    @State private var isLoading = false
    @State private var chatTarget: ChatTarget?

    private let messagesRepository = MessagesRepository()
    private let profilesRepository = ProfilesRepository()

    var body: some View {
        NavigationStack {
            List {
                if !nearbySkaters.isEmpty {
                    Section("Skaters Near You") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(nearbySkaters) { skater in
                                    skaterRailItem(skater)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                }

                Section("Chats") {
                    if conversations.isEmpty, !isLoading {
                        Text("No conversations yet.").foregroundStyle(.secondary)
                    }
                    ForEach(conversations) { conversation in
                        Button {
                            chatTarget = ChatTarget(
                                conversationID: conversation.conversationID,
                                otherUserID: conversation.otherUserID,
                                otherUsername: conversation.otherUsername
                            )
                        } label: {
                            conversationRow(conversation)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        menuCoordinator.isOpen = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
            .task { await load() }
            .refreshable { await load() }
            .onDisappear { Task { await presenceService.leave() } }
            .navigationDestination(item: $chatTarget) { target in
                ChatScreen(conversationID: target.conversationID, otherUserID: target.otherUserID, otherUsername: target.otherUsername)
            }
        }
    }

    private func skaterRailItem(_ skater: Profile) -> some View {
        Button {
            Task { await openChat(with: skater) }
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 56, height: 56)
                        .overlay(Text(skater.username.prefix(1).uppercased()).font(.headline))
                    if presenceService.isOnline(skater.id) {
                        Circle()
                            .fill(.green)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                    }
                }
                Text(skater.username).font(.caption).foregroundStyle(.primary).lineLimit(1)
            }
            .frame(width: 64)
        }
        .buttonStyle(.plain)
    }

    private func conversationRow(_ conversation: ConversationOverview) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 48, height: 48)
                .overlay(Text(conversation.otherUsername.prefix(1).uppercased()).font(.headline))

            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.otherUsername).font(.headline).foregroundStyle(.primary)
                if let spotName = conversation.lastMessageSharedSpotName {
                    Label("Shared a spot: \(spotName)", systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(conversation.lastMessageBody ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.caption2.bold())
                    .padding(6)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        guard let me = authManager.currentProfile else { return }

        presenceService.join(
            city: me.homeCity,
            me: SkatingPresence(userID: me.id, username: me.username, avatarURL: me.avatarURL)
        )

        async let convos = try? messagesRepository.conversations()
        async let nearby = try? profilesRepository.sameCity(as: me.homeCity, excluding: me.id)
        conversations = await convos ?? []
        nearbySkaters = await nearby ?? []
    }

    private func openChat(with skater: Profile) async {
        guard let conversationID = try? await messagesRepository.startConversation(with: skater.id) else { return }
        chatTarget = ChatTarget(conversationID: conversationID, otherUserID: skater.id, otherUsername: skater.username)
    }
}
