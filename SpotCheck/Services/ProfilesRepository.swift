import Foundation
import Supabase

struct ProfilesRepository {
    var client: SupabaseClient = SupabaseClientProvider.shared

    func profile(id: UUID) async throws -> Profile {
        try await client
            .from("profiles")
            .select(Profile.columns)
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    /// Find a user to start a conversation with (Messages' "new message" flow).
    func search(username query: String, limit: Int = 20) async throws -> [Profile] {
        try await client
            .from("profiles")
            .select(Profile.columns)
            .ilike("username", pattern: "%\(query)%")
            .limit(limit)
            .execute()
            .value
    }

    /// Messages screen's "Skaters near you" rail.
    func sameCity(as city: String, excluding userID: UUID, limit: Int = 20) async throws -> [Profile] {
        guard !city.isEmpty else { return [] }
        return try await client
            .from("profiles")
            .select(Profile.columns)
            .ilike("home_city", pattern: city)
            .neq("id", value: userID)
            .limit(limit)
            .execute()
            .value
    }
}
