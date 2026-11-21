import Foundation
import Supabase

/// Path convention: {user_id}/{uuid}.jpg. Unlike spot photos, the
/// `avatars` bucket is public (low sensitivity, benefits from plain
/// cacheable URLs in AsyncImage across Menu/Messages/Chat/SkaterProfile).
enum AvatarStorage {
    private static let bucket = "avatars"
    private static var client: SupabaseClient { SupabaseClientProvider.shared }

    @discardableResult
    static func upload(userID: UUID, imageData: Data) async throws -> String {
        let objectPath = "\(userID.uuidString)/\(UUID().uuidString).jpg"
        try await client.storage.from(bucket).upload(
            objectPath,
            data: imageData,
            options: FileOptions(contentType: "image/jpeg", upsert: true)
        )
        return objectPath
    }

    static func publicURL(path: String) throws -> URL {
        try client.storage.from(bucket).getPublicURL(path: path)
    }

    /// `profiles.avatar_url` holds either a storage path (self-uploaded)
    /// or an external URL (Google OAuth's `picture` claim, copied in by
    /// handle_new_user) -- resolve whichever it is into a displayable URL.
    static func resolvedURL(from avatarURL: String?) -> URL? {
        guard let avatarURL, !avatarURL.isEmpty else { return nil }
        if avatarURL.hasPrefix("http") {
            return URL(string: avatarURL)
        }
        return try? publicURL(path: avatarURL)
    }
}
