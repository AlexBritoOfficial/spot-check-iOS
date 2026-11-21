import Foundation
import Observation

/// The cache layer that replaces TanStack Query's invalidateQueries role
/// on the web app: one shared, observable source of truth for spots so a
/// mutation on one screen (e.g. editing on SpotDetail) is immediately
/// reflected everywhere else (Map, Bookmarks, SkaterProfile) without
/// each screen re-fetching.
@MainActor
@Observable
final class SpotsStore {
    private(set) var spotsByID: [UUID: Spot] = [:]
    /// Ordered by distance, from the last loadNearby() call.
    private(set) var nearbyIDs: [UUID] = []
    private(set) var isLoadingNearby = false
    private(set) var lastError: String?

    private let repository: SpotsRepository

    init(repository: SpotsRepository = SpotsRepository()) {
        self.repository = repository
    }

    var nearbySpots: [Spot] {
        nearbyIDs.compactMap { spotsByID[$0] }
    }

    func spot(id: UUID) -> Spot? {
        spotsByID[id]
    }

    var allCachedSpots: [Spot] {
        Array(spotsByID.values)
    }

    /// For screens (Bookmarks, SkaterProfile) that fetch spots through
    /// their own repository calls but still want the result visible to
    /// every other screen reading from this shared cache.
    func ingest(_ spots: [Spot]) {
        upsert(spots)
    }

    func loadNearby(lat: Double, lng: Double, radiusMeters: Double = 8000) async {
        isLoadingNearby = true
        defer { isLoadingNearby = false }
        do {
            let spots = try await repository.nearby(lat: lat, lng: lng, radiusMeters: radiusMeters)
            upsert(spots)
            nearbyIDs = spots.map(\.id)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    @discardableResult
    func create(_ spot: NewSpot) async throws -> Spot {
        let created = try await repository.create(spot)
        upsert([created])
        nearbyIDs.insert(created.id, at: 0)
        return created
    }

    @discardableResult
    func update(id: UUID, _ patch: SpotUpdate) async throws -> Spot {
        let updated = try await repository.update(id: id, patch)
        upsert([updated])
        return updated
    }

    func delete(id: UUID) async throws {
        try await repository.delete(id: id)
        spotsByID.removeValue(forKey: id)
        nearbyIDs.removeAll { $0 == id }
    }

    private func upsert(_ spots: [Spot]) {
        for spot in spots {
            spotsByID[spot.id] = spot
        }
    }
}
