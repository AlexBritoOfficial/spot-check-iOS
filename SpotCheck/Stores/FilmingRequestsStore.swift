import Foundation
import Observation

/// One shared source of truth for filming requests, so an action on one screen
/// shows everywhere at once -- accepting in Discover adds to the filmer's
/// sessions, cancelling in My requests updates the row -- without each screen
/// re-fetching on its own. Same role SpotsStore plays for spots.
///
/// After every action the affected list is re-read from the server rather
/// than patched locally: the server decides the price, the lateness and the
/// strike, and showing anything else would be guessing.
@MainActor
@Observable
final class FilmingRequestsStore {
    /// The signed-in user's requests as a skater.
    private(set) var myRequests: [FilmingRequest] = []
    /// A filmer's inbox of open requests.
    private(set) var discover: [FilmingRequest] = []
    /// Sessions the signed-in filmer accepted.
    private(set) var sessions: [FilmingRequest] = []
    /// The signed-in filmer's rates and strikes.
    private(set) var standing: FilmerStanding?
    private(set) var isLoading = false
    private(set) var lastError: String?

    private let api: FilmingRequestsAPI

    init(api: FilmingRequestsAPI = FilmingRequestsRepository()) {
        self.api = api
    }

    func loadMyRequests(userID: UUID) async {
        await loading {
            myRequests = try await api.requests(asSkater: userID)
        }
    }

    func loadFilmerInbox(userID: UUID) async {
        await loading {
            discover = try await api.openRequests(for: userID)
            sessions = try await api.sessions(asFilmer: userID)
            standing = try await api.standing(for: userID)
        }
    }

    /// Reads any filmer's rates, for pricing a request named for them.
    func standing(ofFilmer filmerID: UUID) async -> FilmerStanding? {
        try? await api.standing(for: filmerID)
    }

    @discardableResult
    func create(_ draft: FilmingRequestDraft, userID: UUID) async throws -> UUID {
        let id = try await api.create(draft)
        myRequests = try await api.requests(asSkater: userID)
        return id
    }

    func accept(_ request: FilmingRequest, quoteCents: Int?, userID: UUID) async throws {
        try await api.accept(id: request.id, quoteCents: quoteCents)
        discover.removeAll { $0.id == request.id }
        sessions = try await api.sessions(asFilmer: userID)
    }

    func pass(_ request: FilmingRequest) async throws {
        try await api.pass(id: request.id)
        discover.removeAll { $0.id == request.id }
    }

    func cancel(_ request: FilmingRequest, userID: UUID) async throws {
        try await api.cancel(id: request.id)
        if request.skaterID == userID {
            myRequests = try await api.requests(asSkater: userID)
        } else {
            // A filmer's late cancel may have added a strike or paused them.
            sessions = try await api.sessions(asFilmer: userID)
            standing = try await api.standing(for: userID)
        }
    }

    private func loading(_ work: () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await work()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
