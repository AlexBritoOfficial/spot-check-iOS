import Foundation
import Supabase

private struct StartConversationParams: Encodable, Sendable {
    let otherUserID: UUID
    enum CodingKeys: String, CodingKey { case otherUserID = "p_other_user_id" }
}

private struct MarkConversationReadParams: Encodable, Sendable {
    let conversationID: UUID
    enum CodingKeys: String, CodingKey { case conversationID = "p_conversation_id" }
}

struct MessagesRepository {
    var client: SupabaseClient = SupabaseClientProvider.shared

    func conversations() async throws -> [ConversationOverview] {
        try await client.rpc("my_conversations").execute().value
    }

    func messages(in conversationID: UUID, limit: Int = 200) async throws -> [Message] {
        try await client
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationID)
            .order("created_at", ascending: true)
            .limit(limit)
            .execute()
            .value
    }

    @discardableResult
    func send(_ message: NewMessage) async throws -> Message {
        try await client
            .from("messages")
            .insert(message)
            .select()
            .single()
            .execute()
            .value
    }

    /// Find-or-create a 1:1 thread (dm_key dedupes server-side).
    func startConversation(with otherUserID: UUID) async throws -> UUID {
        try await client
            .rpc("start_conversation", params: StartConversationParams(otherUserID: otherUserID))
            .execute()
            .value
    }

    func markRead(conversationID: UUID) async throws {
        try await client
            .rpc("mark_conversation_read", params: MarkConversationReadParams(conversationID: conversationID))
            .execute()
    }
}
