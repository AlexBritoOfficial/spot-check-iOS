import Foundation

/// Mirrors public.bookmarks. Per the web app's domain rules
/// (CONTEXT.md / grill-sign-in-account.md), a bookmark only ever points
/// at a spot you do NOT own -- RLS enforces this server-side too.
struct Bookmark: Codable, Identifiable, Sendable {
    let id: UUID
    let userID: UUID
    let spotID: UUID
    let savedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case spotID = "spot_id"
        case savedAt = "saved_at"
    }
}
