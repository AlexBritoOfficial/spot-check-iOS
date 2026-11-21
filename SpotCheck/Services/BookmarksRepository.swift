import Foundation
import Supabase

private struct NewBookmark: Encodable, Sendable {
    let userID: UUID
    let spotID: UUID

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case spotID = "spot_id"
    }
}

struct BookmarksRepository {
    var client: SupabaseClient = SupabaseClientProvider.shared

    func list(userID: UUID) async throws -> [Bookmark] {
        try await client
            .from("bookmarks")
            .select()
            .eq("user_id", value: userID)
            .order("saved_at", ascending: false)
            .execute()
            .value
    }

    func add(userID: UUID, spotID: UUID) async throws {
        try await client
            .from("bookmarks")
            .insert(NewBookmark(userID: userID, spotID: spotID))
            .execute()
    }

    func remove(userID: UUID, spotID: UUID) async throws {
        try await client
            .from("bookmarks")
            .delete()
            .eq("user_id", value: userID)
            .eq("spot_id", value: spotID)
            .execute()
    }
}
