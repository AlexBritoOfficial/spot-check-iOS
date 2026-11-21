import SwiftUI

struct SkaterProfileScreen: View {
    let userID: UUID

    @Environment(AuthManager.self) private var authManager
    @Environment(SpotsStore.self) private var spotsStore
    @Environment(PresenceService.self) private var presenceService

    @State private var profile: Profile?
    @State private var ownedSpots: [Spot] = []
    @State private var isLoading = false
    @State private var chatTarget: MessagesScreen.ChatTarget?

    private let profilesRepository = ProfilesRepository()
    private let spotsRepository = SpotsRepository()
    private let messagesRepository = MessagesRepository()

    private var isMe: Bool { userID == authManager.currentProfile?.id }

    var body: some View {
        ScrollView {
            if let profile {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Circle()
                            .fill(Color(.tertiarySystemFill))
                            .frame(width: 96, height: 96)
                            .overlay(Text(profile.username.prefix(1).uppercased()).font(.largeTitle.bold()))

                        Text(profile.username).font(.title2.bold())
                        Text("\(profile.handle) · \(profile.homeCity)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if presenceService.isOnline(userID) {
                            let spotName = presenceService.presence(for: userID)?.spotName
                            Label(
                                "Skating now" + (spotName.map { " at \($0)" } ?? ""),
                                systemImage: "circle.fill"
                            )
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                        }
                    }

                    if !isMe {
                        Button {
                            Task { await message() }
                        } label: {
                            Label("Message", systemImage: "bubble.left.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }

                    if profile.stance != nil || profile.discipline != nil || profile.filmer {
                        HStack(spacing: 8) {
                            if let stance = profile.stance, !stance.isEmpty {
                                tag(stance)
                            }
                            if let discipline = profile.discipline, !discipline.isEmpty {
                                tag(discipline)
                            }
                            if profile.filmer {
                                tag("Filmer")
                            }
                        }
                    }

                    if !ownedSpots.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SPOTS ADDED")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            ForEach(ownedSpots) { spot in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(spot.name).font(.subheadline.bold())
                                        Text(spot.spotType.rawValue.capitalized)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(spot.difficulty.rawValue.capitalized)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color(.tertiarySystemFill))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            } else {
                ProgressView()
            }
        }
        .navigationTitle(profile?.username ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .navigationDestination(item: $chatTarget) { target in
            ChatScreen(conversationID: target.conversationID, otherUserID: target.otherUserID, otherUsername: target.otherUsername)
        }
    }

    private func tag(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption2.bold())
            .padding(.horizontal, 10).padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator)))
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        async let fetchedProfile = try? profilesRepository.profile(id: userID)
        async let fetchedSpots = try? spotsRepository.ownedBy(userID: userID)
        profile = await fetchedProfile
        let spots = await fetchedSpots ?? []
        ownedSpots = spots
        spotsStore.ingest(spots)
    }

    private func message() async {
        guard let conversationID = try? await messagesRepository.startConversation(with: userID), let profile else { return }
        chatTarget = .init(conversationID: conversationID, otherUserID: userID, otherUsername: profile.username)
    }
}
