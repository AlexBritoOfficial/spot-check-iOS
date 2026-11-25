import XCTest
@testable import SpotCheck

/// The store is what keeps Discover, a filmer's sessions and a skater's
/// requests consistent after an action. These pin what each action does to
/// the lists, against a fake backend that behaves like the real one.
@MainActor
final class FilmingRequestsStoreTests: XCTestCase {

    private let skaterID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
    private let filmerID = UUID(uuidString: "22222222-2222-4222-8222-222222222222")!
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testLoadingAsAFilmerFillsDiscoverSessionsAndStanding() async {
        let api = FakeFilmingRequestsAPI(requests: [open(1), accepted(2, by: filmerID)])
        api.standing = FilmerStanding(hourlyRateCents: 6000, parkDropInCents: 4000, strikeCount: 1)
        let store = FilmingRequestsStore(api: api)

        await store.loadFilmerInbox(userID: filmerID)

        XCTAssertEqual(store.discover.map(\.id), [id(1)])
        XCTAssertEqual(store.sessions.map(\.id), [id(2)])
        XCTAssertEqual(store.standing?.strikeCount, 1)
        XCTAssertNil(store.lastError)
    }

    func testPassingTakesTheRequestOutOfDiscover() async throws {
        let api = FakeFilmingRequestsAPI(requests: [open(1), open(2)])
        let store = FilmingRequestsStore(api: api)
        await store.loadFilmerInbox(userID: filmerID)

        try await store.pass(store.discover[0])

        XCTAssertEqual(store.discover.map(\.id), [id(2)])
        XCTAssertEqual(api.passed, [id(1)])
    }

    func testAcceptingMovesTheRequestFromDiscoverIntoSessions() async throws {
        let api = FakeFilmingRequestsAPI(requests: [open(1), open(2)])
        api.acceptingFilmerID = filmerID
        let store = FilmingRequestsStore(api: api)
        await store.loadFilmerInbox(userID: filmerID)

        try await store.accept(store.discover[0], quoteCents: nil, userID: filmerID)

        XCTAssertEqual(store.discover.map(\.id), [id(2)])
        XCTAssertEqual(store.sessions.map(\.id), [id(1)])
        XCTAssertEqual(store.sessions.first?.status, .accepted)
    }

    func testAFailedAcceptLeavesDiscoverAsItWasAndThrows() async {
        let api = FakeFilmingRequestsAPI(requests: [open(1)])
        api.failAccept = true
        let store = FilmingRequestsStore(api: api)
        await store.loadFilmerInbox(userID: filmerID)

        do {
            try await store.accept(store.discover[0], quoteCents: nil, userID: filmerID)
            XCTFail("accept should have thrown")
        } catch {}

        XCTAssertEqual(store.discover.map(\.id), [id(1)])
        XCTAssertTrue(store.sessions.isEmpty)
    }

    func testCreatingSendsTheDraftAndShowsItInMyRequests() async throws {
        let api = FakeFilmingRequestsAPI(requests: [])
        api.signedInUserID = skaterID
        let store = FilmingRequestsStore(api: api)
        let draft = FilmingRequestDraft(
            package: .hourlyStreet, startsAt: now, hours: 2,
            place: .pin(lat: 42.35, lng: -71.07, label: "Pin near Copley Square"),
            lighting: .goldenHour, securityRisk: .sometimes, requestedFilmerID: nil)

        try await store.create(draft, userID: skaterID)

        XCTAssertEqual(api.created, [draft])
        XCTAssertEqual(store.myRequests.count, 1)
        XCTAssertEqual(store.myRequests.first?.locationLabel, "Pin near Copley Square")
    }

    func testCancellingReplacesTheRequestWithTheServersCancelledRow() async throws {
        let api = FakeFilmingRequestsAPI(requests: [open(1)])
        let store = FilmingRequestsStore(api: api)
        await store.loadMyRequests(userID: skaterID)

        try await store.cancel(store.myRequests[0], userID: skaterID)

        XCTAssertEqual(api.cancelled, [id(1)])
        XCTAssertEqual(store.myRequests.first?.status, .cancelled)
    }

    // MARK: - Fixtures

    private func id(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "f0000000-0000-4000-8000-%012d", n))!
    }

    private func open(_ n: Int) -> FilmingRequest {
        FakeFilmingRequestsAPI.request(id: id(n), skaterID: skaterID, startsAt: now.addingTimeInterval(Double(n) * 3600))
    }

    private func accepted(_ n: Int, by filmer: UUID) -> FilmingRequest {
        FakeFilmingRequestsAPI.request(id: id(n), skaterID: skaterID,
                                       startsAt: now.addingTimeInterval(Double(n) * 3600),
                                       status: .accepted, filmerID: filmer, rateCents: 12000)
    }
}

/// Behaves like the database for the cases above: actions change the rows,
/// and the read queries filter them the way RLS and the store's queries do.
@MainActor
final class FakeFilmingRequestsAPI: FilmingRequestsAPI {
    var requests: [FilmingRequest]
    var standing: FilmerStanding?
    var acceptingFilmerID: UUID?
    var failAccept = false
    /// Stands in for auth.uid(): the server takes the skater from the session.
    var signedInUserID = UUID()

    private(set) var passed: [UUID] = []
    private(set) var created: [FilmingRequestDraft] = []
    private(set) var cancelled: [UUID] = []
    private var passedBy: Set<UUID> = []

    init(requests: [FilmingRequest]) {
        self.requests = requests
    }

    func requests(asSkater userID: UUID) async throws -> [FilmingRequest] {
        requests.filter { $0.skaterID == userID }
    }

    func openRequests(for filmerID: UUID) async throws -> [FilmingRequest] {
        requests.filter { $0.status == .requested && $0.skaterID != filmerID && !passedBy.contains($0.id) }
    }

    func sessions(asFilmer filmerID: UUID) async throws -> [FilmingRequest] {
        requests.filter { $0.filmerID == filmerID && $0.status == .accepted }
    }

    func standing(for filmerID: UUID) async throws -> FilmerStanding? {
        standing
    }

    func create(_ draft: FilmingRequestDraft) async throws -> UUID {
        created.append(draft)
        let id = UUID()
        var row = Self.request(id: id, skaterID: signedInUserID, startsAt: draft.startsAt)
        row = row.replacing(locationLabel: draft.place.label)
        requests.append(row)
        return id
    }

    func accept(id: UUID, quoteCents: Int?) async throws {
        if failAccept { throw URLError(.badServerResponse) }
        guard let index = requests.firstIndex(where: { $0.id == id }) else { return }
        requests[index] = requests[index].replacing(status: .accepted, filmerID: acceptingFilmerID, rateCents: 12000)
    }

    func pass(id: UUID) async throws {
        passed.append(id)
        passedBy.insert(id)
    }

    func cancel(id: UUID) async throws {
        cancelled.append(id)
        guard let index = requests.firstIndex(where: { $0.id == id }) else { return }
        requests[index] = requests[index].replacing(status: .cancelled)
    }

    static func request(
        id: UUID, skaterID: UUID, startsAt: Date,
        status: FilmingRequestStatus = .requested, filmerID: UUID? = nil, rateCents: Int? = nil
    ) -> FilmingRequest {
        FilmingRequest(
            id: id, skaterID: skaterID, requestedFilmerID: nil, filmerID: filmerID,
            package: .hourlyStreet, spotID: nil, lat: 42.3493, lng: -71.0767,
            locationLabel: "Copley Library", startsAt: startsAt,
            endsAt: startsAt.addingTimeInterval(7200), lighting: .goldenHour,
            securityRisk: .sometimes, notes: nil, rateCents: rateCents, status: status,
            acceptedAt: status == .accepted ? startsAt : nil, cancelledAt: nil,
            cancelledBy: nil, cancellationWasLate: nil, createdAt: startsAt,
            skater: .init(username: "rider_nguyen"))
    }
}

private extension FilmingRequest {
    func replacing(
        status: FilmingRequestStatus? = nil,
        filmerID: UUID?? = nil,
        rateCents: Int?? = nil,
        locationLabel: String?? = nil
    ) -> FilmingRequest {
        FilmingRequest(
            id: id, skaterID: skaterID, requestedFilmerID: requestedFilmerID,
            filmerID: filmerID ?? self.filmerID, package: package, spotID: spotID,
            lat: lat, lng: lng, locationLabel: locationLabel ?? self.locationLabel,
            startsAt: startsAt, endsAt: endsAt, lighting: lighting, securityRisk: securityRisk,
            notes: notes, rateCents: rateCents ?? self.rateCents, status: status ?? self.status,
            acceptedAt: acceptedAt, cancelledAt: cancelledAt, cancelledBy: cancelledBy,
            cancellationWasLate: cancellationWasLate, createdAt: createdAt, skater: skater)
    }
}
