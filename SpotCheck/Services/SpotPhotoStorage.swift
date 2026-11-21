import Foundation
import Supabase

/// Path convention: {owner_id}/{spot_id}/{uuid}.jpg -- matches the RLS
/// policies in supabase/migrations/20261118155808_storage.sql, which
/// gate reads by the referenced spot's own visibility and gate
/// writes by the owner-id path prefix.
enum SpotPhotoStorage {
    private static let bucket = "spot-photos"
    private static var client: SupabaseClient { SupabaseClientProvider.shared }

    /// Upload happens before the spot row exists -- AddSpot pre-generates
    /// the spot's UUID client-side so this path (and its owner-prefix
    /// check) is valid immediately, with no chicken-and-egg wait on the
    /// row being created first.
    @discardableResult
    static func upload(ownerID: UUID, spotID: UUID, imageData: Data) async throws -> String {
        let objectPath = "\(ownerID.uuidString)/\(spotID.uuidString)/\(UUID().uuidString).jpg"
        try await client.storage.from(bucket).upload(
            objectPath,
            data: imageData,
            options: FileOptions(contentType: "image/jpeg")
        )
        return objectPath
    }

    static func signedURL(path: String, expiresIn: Int = 3600) async throws -> URL {
        try await client.storage.from(bucket).createSignedURL(path: path, expiresIn: expiresIn)
    }
}
