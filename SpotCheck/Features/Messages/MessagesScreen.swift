import SwiftUI

/// The canvas's `Messages` artboard. Restyled off the system `List`:
/// custom header, filled search field, the ringed "skaters to follow"
/// rail and 52pt chat rows.
///
/// Two bits of the artboard are static chrome here because no data
/// backs them: the search field doesn't filter yet, and the "New
/// message" button has no compose flow. Relative timestamps aren't
/// shown either -- the artboard's "2m"/"Yesterday" would need a
/// formatting pass that belongs with the unread work.
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
    @State private var searchText = ""

    private let messagesRepository = MessagesRepository()
    private let profilesRepository = ProfilesRepository()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                searchField

                ScrollView {
                    VStack(spacing: 0) {
                        if !nearbySkaters.isEmpty {
                            skatersRail
                        }

                        Text("CHATS")
                            .scSectionLabel()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, SCMetric.screenPadding)
                            .padding(.top, 18)
                            .padding(.bottom, 6)

                        if conversations.isEmpty, !isLoading {
                            Text("No conversations yet.")
                                .font(.system(size: 14))
                                .foregroundStyle(SCColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, SCMetric.screenPadding)
                                .padding(.vertical, 12)
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
                    .padding(.bottom, SCMetric.bottomNavClearance)
                }
                .refreshable { await load() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SCColor.background)
            .toolbar(.hidden)
            .task { await load() }
            .onDisappear { Task { await presenceService.leave() } }
            .navigationDestination(item: $chatTarget) { target in
                ChatScreen(
                    conversationID: target.conversationID,
                    otherUserID: target.otherUserID,
                    otherUsername: target.otherUsername
                )
            }
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            Button {
                menuCoordinator.isOpen = true
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open menu")

            Text("Messages")
                .font(SCFont.heading(24))
                .foregroundStyle(SCColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {} label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SCColor.background)
                    .frame(width: 44, height: 44)
                    .background(SCColor.accent)
                    .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("New message")
        }
        .padding(.horizontal, 10)
        .padding(.top, SCMetric.headerTop(52))
        .padding(.bottom, 12)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SCColor.textSecondary)
            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    Text("Search skaters")
                        .font(.system(size: 15))
                        .foregroundStyle(SCColor.textSecondary)
                        .allowsHitTesting(false)
                }
                TextField("", text: $searchText)
                    .font(.system(size: 15))
                    .foregroundStyle(SCColor.textPrimary)
                    .tint(SCColor.accent)
                    .accessibilityLabel("Search skaters")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(SCColor.inputFill)
        .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))
        .padding(.horizontal, SCMetric.screenPadding)
        .padding(.bottom, 16)
    }

    private var skatersRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            SCSectionHeader("Skaters to follow") {
                Button("See all") {}
                    .font(.system(size: 13))
                    .foregroundStyle(SCColor.accent)
            }
            .padding(.horizontal, SCMetric.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(nearbySkaters) { skater in
                        skaterRailItem(skater)
                    }
                }
                .padding(.horizontal, SCMetric.screenPadding)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 18)
        .overlay(alignment: .bottom) { SCColor.border.frame(height: 1) }
    }

    private func skaterRailItem(_ skater: Profile) -> some View {
        Button {
            Task { await openChat(with: skater) }
        } label: {
            VStack(spacing: 6) {
                Avatar(
                    initial: skater.username,
                    size: 60,
                    ringColor: presenceService.isOnline(skater.id) ? SCColor.accent : SCColor.border,
                    backgroundColor: SCColor.border,
                    foregroundColor: SCColor.textPrimary
                )
                Text(skater.username)
                    .font(.system(size: 12))
                    .foregroundStyle(SCColor.textPrimary)
                    .lineLimit(1)
            }
            .frame(width: 64)
        }
        .buttonStyle(.plain)
    }

    private func conversationRow(_ conversation: ConversationOverview) -> some View {
        HStack(spacing: 14) {
            Avatar(
                initial: conversation.otherUsername,
                size: 52,
                backgroundColor: SCColor.border,
                foregroundColor: SCColor.textPrimary
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.otherUsername)
                    .font(SCFont.headingFixed(15))
                    .foregroundStyle(SCColor.textPrimary)

                HStack(spacing: 8) {
                    if let spotName = conversation.lastMessageSharedSpotName {
                        HStack(spacing: 6) {
                            SCPinGlyph(height: 14)
                            Text("Shared a spot: \(spotName)")
                                .lineLimit(1)
                        }
                    } else {
                        Text(conversation.lastMessageBody ?? "")
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SCColor.background)
                            .padding(.horizontal, 6)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(SCColor.accent)
                            .clipShape(Capsule())
                            .accessibilityLabel("\(conversation.unreadCount) unread")
                    }
                }
                .font(.system(size: 14, weight: conversation.unreadCount > 0 ? .semibold : .regular))
                .foregroundStyle(conversation.unreadCount > 0 ? SCColor.textPrimary : SCColor.textSecondary)
            }
        }
        .padding(.horizontal, SCMetric.screenPadding)
        .padding(.vertical, 12)
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
        chatTarget = ChatTarget(
            conversationID: conversationID,
            otherUserID: skater.id,
            otherUsername: skater.username
        )
    }
}
