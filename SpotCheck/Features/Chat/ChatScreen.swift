import Supabase
import SwiftUI

struct ChatScreen: View {
    let conversationID: UUID
    let otherUserID: UUID
    let otherUsername: String

    @Environment(AuthManager.self) private var authManager
    @Environment(SpotsStore.self) private var spotsStore
    @Environment(PresenceService.self) private var presenceService

    @State private var messages: [Message] = []
    @State private var draft = ""
    @State private var isSending = false
    @State private var showShareSpot = false
    @State private var errorMessage: String?
    @State private var channel: RealtimeChannelV2?

    private let repository = MessagesRepository()

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubble(
                                message: message,
                                isMine: message.senderID == authManager.currentProfile?.id,
                                sharedSpot: message.sharedSpotID.flatMap { spotsStore.spot(id: $0) }
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    guard let last = messages.last else { return }
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            HStack(spacing: 8) {
                Button {
                    showShareSpot = true
                } label: {
                    Image(systemName: "mappin.circle")
                        .font(.title2)
                }

                TextField("Message", text: $draft)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await sendDraft() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding()
        }
        .navigationTitle(otherUsername)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(otherUsername).font(.headline)
                    if presenceService.isOnline(otherUserID) {
                        Text("Skating now").font(.caption2).foregroundStyle(.green)
                    }
                }
            }
        }
        .task { await connect() }
        .onDisappear {
            if let channel {
                Task { await SupabaseClientProvider.shared.removeChannel(channel) }
            }
        }
        .sheet(isPresented: $showShareSpot) {
            ShareSpotSheet(spots: spotsStore.allCachedSpots.filter(\.isPublic)) { spot in
                showShareSpot = false
                Task { await send(body: nil, sharedSpotID: spot.id) }
            }
        }
    }

    /// Subscribe first, then backfill: subscribing after the fetch
    /// leaves a gap where a message arriving between the two is lost.
    private func connect() async {
        let client = SupabaseClientProvider.shared
        let ch = client.channel("conversation:\(conversationID.uuidString)")
        channel = ch

        let inserts = ch.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: .eq("conversation_id", value: conversationID)
        )
        await ch.subscribe()

        Task { await loadMessages() }
        try? await repository.markRead(conversationID: conversationID)

        for await insert in inserts {
            guard let message = try? insert.decodeRecord(as: Message.self, decoder: SupabaseDecoders.decoder) else {
                continue
            }
            await ingestSharedSpotIfNeeded(message)
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
            }
            if message.senderID != authManager.currentProfile?.id {
                try? await repository.markRead(conversationID: conversationID)
            }
        }
    }

    private func loadMessages() async {
        do {
            let loaded = try await repository.messages(in: conversationID)
            for message in loaded {
                await ingestSharedSpotIfNeeded(message)
            }
            // Merge rather than replace: a Realtime insert may have
            // already landed via the stream while this backfill was in flight.
            var byID = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
            for message in loaded { byID[message.id] = message }
            messages = byID.values.sorted { $0.createdAt < $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func ingestSharedSpotIfNeeded(_ message: Message) async {
        guard let spotID = message.sharedSpotID, spotsStore.spot(id: spotID) == nil else { return }
        if let spot = try? await SpotsRepository().byIDs([spotID]).first {
            spotsStore.ingest([spot])
        }
    }

    private func sendDraft() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        await send(body: text, sharedSpotID: nil)
    }

    private func send(body: String?, sharedSpotID: UUID?) async {
        guard let senderID = authManager.currentProfile?.id else { return }
        isSending = true
        defer { isSending = false }
        do {
            let sent = try await repository.send(
                NewMessage(conversationID: conversationID, senderID: senderID, body: body, sharedSpotID: sharedSpotID)
            )
            if !messages.contains(where: { $0.id == sent.id }) {
                messages.append(sent)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
