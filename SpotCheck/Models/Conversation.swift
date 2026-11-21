import Foundation

/// Matches the my_conversations() RPC's return shape exactly -- one row
/// per conversation, already joined with the other participant's
/// profile and an unread count computed from MY last_read_at.
struct ConversationOverview: Codable, Identifiable, Sendable {
    var id: UUID { conversationID }
    let conversationID: UUID
    let otherUserID: UUID
    let otherUsername: String
    let otherAvatarURL: String?
    let lastMessageBody: String?
    let lastMessageSharedSpotID: UUID?
    let lastMessageSharedSpotName: String?
    let lastMessageAt: Date
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case conversationID = "conversation_id"
        case otherUserID = "other_user_id"
        case otherUsername = "other_username"
        case otherAvatarURL = "other_avatar_url"
        case lastMessageBody = "last_message_body"
        case lastMessageSharedSpotID = "last_message_shared_spot_id"
        case lastMessageSharedSpotName = "last_message_shared_spot_name"
        case lastMessageAt = "last_message_at"
        case unreadCount = "unread_count"
    }
}
