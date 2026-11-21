import Foundation

/// Mirrors public.messages. body and sharedSpotID are each optional,
/// but the DB's messages_has_content check requires at least one --
/// enforced when sending, not re-validated on decode.
struct Message: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let conversationID: UUID
    let senderID: UUID
    var body: String?
    var sharedSpotID: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conversationID = "conversation_id"
        case senderID = "sender_id"
        case body
        case sharedSpotID = "shared_spot_id"
        case createdAt = "created_at"
    }
}

struct NewMessage: Encodable, Sendable {
    let conversationID: UUID
    let senderID: UUID
    var body: String?
    var sharedSpotID: UUID?

    enum CodingKeys: String, CodingKey {
        case conversationID = "conversation_id"
        case senderID = "sender_id"
        case body
        case sharedSpotID = "shared_spot_id"
    }
}
