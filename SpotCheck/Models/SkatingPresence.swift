import Foundation

/// Ephemeral payload tracked on a Realtime Presence channel -- never
/// written to Postgres. See PresenceService for why.
struct SkatingPresence: Codable, Sendable, Equatable {
    let userID: UUID
    let username: String
    var avatarURL: String?
    var spotID: UUID?
    var spotName: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case username
        case avatarURL = "avatar_url"
        case spotID = "spot_id"
        case spotName = "spot_name"
    }
}
