import Foundation
import Supabase

/// Mirrors the web app's spotRepository.ts -- stateless async functions,
/// one per action. SpotsStore is the cache layer that replaces TanStack
/// Query's invalidateQueries role.
struct SpotsRepository {
    var client: SupabaseClient = SupabaseClientProvider.shared

    func nearby(lat: Double, lng: Double, radiusMeters: Double = 8000, limit: Int = 200) async throws -> [Spot] {
        try await client
            .rpc(
                "spots_nearby",
                params: SpotsNearbyParams(lat: lat, lng: lng, radiusMeters: radiusMeters, limit: limit)
            )
            .execute()
            .value
    }

    func all(limit: Int = 500) async throws -> [Spot] {
        try await client
            .from("spots")
            .select(Spot.columns)
            .limit(limit)
            .execute()
            .value
    }

    /// Bookmarks screen: the bookmarked spots themselves may not already
    /// be in SpotsStore's cache (e.g. outside the last nearby() radius).
    func byIDs(_ ids: [UUID]) async throws -> [Spot] {
        guard !ids.isEmpty else { return [] }
        return try await client
            .from("spots")
            .select(Spot.columns)
            .in("id", values: ids)
            .execute()
            .value
    }

    /// SkaterProfile's "spots added" list.
    func ownedBy(userID: UUID) async throws -> [Spot] {
        try await client
            .from("spots")
            .select(Spot.columns)
            .eq("owner_id", value: userID)
            .execute()
            .value
    }

    @discardableResult
    func create(_ spot: NewSpot) async throws -> Spot {
        try await client
            .from("spots")
            .insert(spot)
            .select(Spot.columns)
            .single()
            .execute()
            .value
    }

    @discardableResult
    func update(id: UUID, _ patch: SpotUpdate) async throws -> Spot {
        try await client
            .from("spots")
            .update(patch)
            .eq("id", value: id)
            .select(Spot.columns)
            .single()
            .execute()
            .value
    }

    func delete(id: UUID) async throws {
        try await client
            .from("spots")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
