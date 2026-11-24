import SwiftUI

/// The canvas's `SkaterProfile` artboard -- another skater's profile
/// (the signed-in user's own is `SkaterPortfolioScreen`). Restyled off
/// system list/button chrome.
///
/// The artboard's "Connect" button and challenge-finalist pill are
/// static here: there's no follow graph or challenge data behind them
/// yet. The presence line replaces neither -- it stays, since it's
/// live.
struct SkaterProfileScreen: View {
    let userID: UUID

    @Environment(AuthManager.self) private var authManager
    @Environment(SpotsStore.self) private var spotsStore
    @Environment(PresenceService.self) private var presenceService
    @Environment(\.dismiss) private var dismiss

    @State private var profile: Profile?
    @State private var ownedSpots: [Spot] = []
    @State private var isLoading = false
    @State private var chatTarget: MessagesScreen.ChatTarget?

    private let profilesRepository = ProfilesRepository()
    private let spotsRepository = SpotsRepository()
    private let messagesRepository = MessagesRepository()

    private var isMe: Bool { userID == authManager.currentProfile?.id }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                if let profile {
                    VStack(alignment: .leading, spacing: 22) {
                        identity(profile)

                        if !isMe {
                            actionRow
                        }

                        aboutSection(profile)

                        if !ownedSpots.isEmpty {
                            spotsSection
                        }
                    }
                    .padding(.horizontal, SCMetric.screenPadding)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                } else {
                    ProgressView()
                        .tint(SCColor.accent)
                        .padding(.top, 60)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
        .toolbar(.hidden)
        .task { await load() }
        .navigationDestination(item: $chatTarget) { target in
            ChatScreen(
                conversationID: target.conversationID,
                otherUserID: target.otherUserID,
                otherUsername: target.otherUsername
            )
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()

            Button {} label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More options")
        }
        .padding(.horizontal, 10)
        .padding(.top, SCMetric.headerTop(52))
    }

    private func identity(_ profile: Profile) -> some View {
        VStack(spacing: 12) {
            Avatar(
                initial: profile.username,
                size: 104,
                ringColor: SCColor.accent,
                backgroundColor: SCColor.border,
                foregroundColor: SCColor.textPrimary
            )

            VStack(spacing: 4) {
                Text(profile.username)
                    .font(SCFont.heading(24))
                    .foregroundStyle(SCColor.textPrimary)
                Text("\(profile.handle) · \(profile.homeCity)")
                    .font(.system(size: 14))
                    .foregroundStyle(SCColor.textSecondary)
            }

            if presenceService.isOnline(userID) {
                let spotName = presenceService.presence(for: userID)?.spotName
                HStack(spacing: 6) {
                    Circle()
                        .fill(SCColor.success)
                        .frame(width: 8, height: 8)
                    Text("Skating now" + (spotName.map { " at \($0)" } ?? ""))
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(SCColor.success)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(SCColor.success.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                Task { await message() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 15))
                    Text("Message")
                }
            }
            .buttonStyle(.scPrimary(fontSize: 14))

            Button {} label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 15))
                    Text("Connect")
                }
            }
            .buttonStyle(.scSecondary(fontSize: 14))
        }
    }

    private func aboutSection(_ profile: Profile) -> some View {
        Group {
            if profile.stance != nil || profile.discipline != nil || profile.filmer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ABOUT").scSectionLabel()
                    FlowChips(spacing: 8) {
                        if let stance = profile.stance, !stance.isEmpty {
                            aboutTag(stance)
                        }
                        if let discipline = profile.discipline, !discipline.isEmpty {
                            aboutTag(discipline)
                        }
                        if profile.filmer {
                            aboutTag("Filmer", systemImage: "video.fill", tint: SCColor.accent)
                        }
                    }
                }
            }
        }
    }

    private func aboutTag(
        _ text: String,
        systemImage: String? = nil,
        tint: Color = SCColor.textPrimary
    ) -> some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 12))
            }
            Text(text.uppercased())
                .font(SCFont.headingFixed(11))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .overlay(
            Capsule().stroke(tint == SCColor.accent ? SCColor.accent : SCColor.border, lineWidth: 1.5)
        )
    }

    private var spotsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SPOTS ADDED").scSectionLabel()

            ForEach(ownedSpots) { spot in
                HStack(spacing: 12) {
                    SCMediaPlaceholder(cornerRadius: 10)
                        .frame(width: 56, height: 56)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(spot.name)
                            .font(SCFont.headingFixed(15))
                            .foregroundStyle(SCColor.textPrimary)
                        HStack(spacing: 6) {
                            Badge(text: spot.spotType.rawValue)
                            Badge.difficulty(spot.difficulty)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SCColor.textSecondary)
                }
                .padding(10)
                .scCard(cornerRadius: SCRadius.cardSmall)
            }
        }
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
