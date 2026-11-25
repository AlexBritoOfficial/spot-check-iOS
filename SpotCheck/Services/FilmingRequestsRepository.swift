import Foundation
import Supabase

/// What the filming-request screens need from the backend. A protocol so the
/// store's behaviour can be tested against a fake (FilmingRequestsStoreTests).
/// Not tied to an actor, like the other repositories: the work is network I/O.
protocol FilmingRequestsAPI: Sendable {
    /// A skater's own requests, newest session first.
    func requests(asSkater userID: UUID) async throws -> [FilmingRequest]
    /// Discover: open requests this filmer may take. RLS already limits them
    /// to unstarted ones sent to anyone or named for this filmer, minus the
    /// ones they passed on -- and to nothing at all for a paused filmer.
    func openRequests(for filmerID: UUID) async throws -> [FilmingRequest]
    /// Sessions this filmer accepted and still has ahead of them.
    func sessions(asFilmer filmerID: UUID) async throws -> [FilmingRequest]
    func standing(for filmerID: UUID) async throws -> FilmerStanding?
    /// The skater is whoever is signed in; the server takes it from the session.
    func create(_ draft: FilmingRequestDraft) async throws -> UUID
    func accept(id: UUID, quoteCents: Int?) async throws
    func pass(id: UUID) async throws
    func cancel(id: UUID) async throws
}

/// Reads go through RLS; every write is one of the backend's security-definer
/// functions, because the tables have no client write policy at all. A direct
/// insert or update here wouldn't fail loudly -- it would be refused by RLS --
/// so there is deliberately no method that tries.
struct FilmingRequestsRepository: FilmingRequestsAPI {
    var client: SupabaseClient = SupabaseClientProvider.shared

    func requests(asSkater userID: UUID) async throws -> [FilmingRequest] {
        try await client
            .from("filming_requests")
            .select(FilmingRequest.columns)
            .eq("skater_id", value: userID)
            .order("starts_at", ascending: false)
            .execute()
            .value
    }

    func openRequests(for filmerID: UUID) async throws -> [FilmingRequest] {
        try await client
            .from("filming_requests")
            .select(FilmingRequest.columns)
            .eq("status", value: FilmingRequestStatus.requested.rawValue)
            // RLS also returns a filmer's own requests *as a skater*; those
            // belong in My requests, not in their Discover.
            .neq("skater_id", value: filmerID)
            .order("starts_at")
            .execute()
            .value
    }

    func sessions(asFilmer filmerID: UUID) async throws -> [FilmingRequest] {
        try await client
            .from("filming_requests")
            .select(FilmingRequest.columns)
            .eq("filmer_id", value: filmerID)
            .eq("status", value: FilmingRequestStatus.accepted.rawValue)
            .order("starts_at")
            .execute()
            .value
    }

    func standing(for filmerID: UUID) async throws -> FilmerStanding? {
        let rows: [FilmerStanding] = try await client
            .from("filmer_profiles")
            .select(FilmerStanding.columns)
            .eq("user_id", value: filmerID)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func create(_ draft: FilmingRequestDraft) async throws -> UUID {
        try await client
            .rpc("create_filming_request", params: CreateParams(draft))
            .execute()
            .value
    }

    func accept(id: UUID, quoteCents: Int?) async throws {
        try await client
            .rpc("accept_filming_request", params: AcceptParams(pRequestID: id, pQuoteCents: quoteCents))
            .execute()
    }

    func pass(id: UUID) async throws {
        try await client
            .rpc("pass_filming_request", params: RequestIDParams(pRequestID: id))
            .execute()
    }

    func cancel(id: UUID) async throws {
        try await client
            .rpc("cancel_filming_request", params: RequestIDParams(pRequestID: id))
            .execute()
    }
}

// MARK: - RPC parameters. Keys are the SQL functions' parameter names.

private struct CreateParams: Encodable, Sendable {
    let pPackage: FilmingPackage
    let pStartsAt: Date
    let pEndsAt: Date
    let pLat: Double
    let pLng: Double
    let pLighting: SessionLighting
    let pSecurityRisk: SecurityRisk
    let pSpotID: UUID?
    let pLocationLabel: String?
    let pRequestedFilmerID: UUID?

    init(_ draft: FilmingRequestDraft) {
        pPackage = draft.package
        pStartsAt = draft.startsAt
        pEndsAt = draft.endsAt
        pLat = draft.place.lat
        pLng = draft.place.lng
        pLighting = draft.lighting
        pSecurityRisk = draft.securityRisk
        pSpotID = draft.place.spotID
        pLocationLabel = draft.place.label
        pRequestedFilmerID = draft.requestedFilmerID
    }

    enum CodingKeys: String, CodingKey {
        case pPackage = "p_package"
        case pStartsAt = "p_starts_at"
        case pEndsAt = "p_ends_at"
        case pLat = "p_lat"
        case pLng = "p_lng"
        case pLighting = "p_lighting"
        case pSecurityRisk = "p_security_risk"
        case pSpotID = "p_spot_id"
        case pLocationLabel = "p_location_label"
        case pRequestedFilmerID = "p_requested_filmer_id"
    }
}

private struct AcceptParams: Encodable, Sendable {
    let pRequestID: UUID
    let pQuoteCents: Int?

    enum CodingKeys: String, CodingKey {
        case pRequestID = "p_request_id"
        case pQuoteCents = "p_quote_cents"
    }
}

private struct RequestIDParams: Encodable, Sendable {
    let pRequestID: UUID

    enum CodingKeys: String, CodingKey {
        case pRequestID = "p_request_id"
    }
}
