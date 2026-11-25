import XCTest
@testable import SpotCheck

/// The rules behind booking, Discover and cancelling. Most of them restate a
/// rule the database enforces (spot-check-backend
/// 20261125120000_filming_requests.sql), so the app shows the same number the
/// server will record. Where they drift, the user is shown one price and
/// charged another -- worth pinning here rather than eyeballing.
final class FilmingRequestTests: XCTestCase {

    private let start = Date(timeIntervalSince1970: 1_800_000_000)
    private let filmerRates = FilmerRates(hourlyRateCents: 6000, parkDropInCents: 4000)

    // MARK: - Raw values must match the Postgres enum labels

    func testPackageRawValuesMatchPostgresLabels() {
        XCTAssertEqual(FilmingPackage.hourlyStreet.rawValue, "hourly_street")
        XCTAssertEqual(FilmingPackage.parkDropIn.rawValue, "park_drop_in")
        XCTAssertEqual(FilmingPackage.fullEdit.rawValue, "full_edit")
    }

    func testConditionRawValuesMatchPostgresLabels() {
        XCTAssertEqual(SessionLighting.daylight.rawValue, "daylight")
        XCTAssertEqual(SessionLighting.goldenHour.rawValue, "golden_hour")
        XCTAssertEqual(SessionLighting.night.rawValue, "night")
        XCTAssertEqual(SecurityRisk.low.rawValue, "low")
        XCTAssertEqual(SecurityRisk.sometimes.rawValue, "sometimes")
        XCTAssertEqual(SecurityRisk.kicksOutFast.rawValue, "kicks_out_fast")
    }

    func testStatusRawValuesMatchPostgresLabels() {
        XCTAssertEqual(FilmingRequestStatus.requested.rawValue, "requested")
        XCTAssertEqual(FilmingRequestStatus.accepted.rawValue, "accepted")
        XCTAssertEqual(FilmingRequestStatus.cancelled.rawValue, "cancelled")
        XCTAssertEqual(RequestParty.skater.rawValue, "skater")
        XCTAssertEqual(RequestParty.filmer.rawValue, "filmer")
    }

    /// The exact shape PostgREST returns for `FilmingRequest.columns`,
    /// including the embedded skater name.
    func testFilmingRequestDecodesServerShape() throws {
        let json = """
        {
          "id": "dddddddd-dddd-4ddd-8ddd-ddddddddddd3",
          "skater_id": "11111111-1111-4111-8111-111111111111",
          "requested_filmer_id": null,
          "filmer_id": "22222222-2222-4222-8222-222222222222",
          "package": "hourly_street",
          "spot_id": null,
          "lat": 42.3554,
          "lng": -71.0656,
          "location_label": "Eggs",
          "starts_at": "2026-11-26T17:00:00+00:00",
          "ends_at": "2026-11-26T19:00:00+00:00",
          "lighting": "golden_hour",
          "security_risk": "sometimes",
          "notes": null,
          "rate_cents": 12000,
          "status": "accepted",
          "accepted_at": "2026-11-20T10:00:00.123456+00:00",
          "cancelled_at": null,
          "cancelled_by": null,
          "cancellation_was_late": null,
          "created_at": "2026-11-20T09:00:00+00:00",
          "skater": { "username": "rider_nguyen" }
        }
        """.data(using: .utf8)!

        let request = try SupabaseDecoders.decoder.decode(FilmingRequest.self, from: json)

        XCTAssertEqual(request.package, .hourlyStreet)
        XCTAssertEqual(request.status, .accepted)
        XCTAssertEqual(request.lighting, .goldenHour)
        XCTAssertEqual(request.securityRisk, .sometimes)
        XCTAssertEqual(request.rateCents, 12000)
        XCTAssertEqual(request.skater?.username, "rider_nguyen")
        XCTAssertEqual(request.endsAt.timeIntervalSince(request.startsAt), 2 * 3600)
    }

    // MARK: - Pricing: must match accept_filming_request

    func testHourlyIsBilledByTheMinuteAtTheFilmersRate() {
        XCTAssertEqual(
            FilmingPricing.rateCents(for: .hourlyStreet, startsAt: start,
                                     endsAt: start.addingTimeInterval(2 * 3600), rates: filmerRates),
            12000, "5-7 PM at $60/hr is $120, as Checkout shows")
        XCTAssertEqual(
            FilmingPricing.rateCents(for: .hourlyStreet, startsAt: start,
                                     endsAt: start.addingTimeInterval(90 * 60), rates: filmerRates),
            9000, "90 minutes at $60/hr")
    }

    func testHourlyRoundsHalfACentAwayFromZeroLikePostgres() {
        let rates = FilmerRates(hourlyRateCents: 6001, parkDropInCents: nil)
        // 6001 * 0.5 = 3000.5 -> Postgres round() gives 3001
        XCTAssertEqual(
            FilmingPricing.rateCents(for: .hourlyStreet, startsAt: start,
                                     endsAt: start.addingTimeInterval(30 * 60), rates: rates),
            3001)
    }

    func testParkDropInIsFlatWhateverTheLength() {
        XCTAssertEqual(
            FilmingPricing.rateCents(for: .parkDropIn, startsAt: start,
                                     endsAt: start.addingTimeInterval(3 * 3600), rates: filmerRates),
            4000)
    }

    func testFullEditIsTheQuoteAndHasNoPriceWithoutOne() {
        XCTAssertNil(
            FilmingPricing.rateCents(for: .fullEdit, startsAt: start,
                                     endsAt: start.addingTimeInterval(8 * 3600), rates: filmerRates))
        XCTAssertEqual(
            FilmingPricing.rateCents(for: .fullEdit, startsAt: start,
                                     endsAt: start.addingTimeInterval(8 * 3600), rates: filmerRates,
                                     quoteCents: 75000),
            75000)
    }

    func testNoPriceWhenTheFilmerHasNoRateForThatPackage() {
        let hourlyOnly = FilmerRates(hourlyRateCents: 6000, parkDropInCents: nil)
        XCTAssertNil(
            FilmingPricing.rateCents(for: .parkDropIn, startsAt: start,
                                     endsAt: start.addingTimeInterval(3600), rates: hourlyOnly))
    }

    func testSkaterPaysTheRatePlusFifteenPercentOnTop() {
        XCTAssertEqual(FilmingPricing.skaterFeeCents(onRate: 12000), 1800)
        XCTAssertEqual(FilmingPricing.skaterTotalCents(onRate: 12000), 13800)
    }

    func testLateCancelFeeIsFifteenPercentOfTheRate() {
        XCTAssertEqual(FilmingPricing.lateCancelFeeCents(onRate: 12000), 1800)
        XCTAssertEqual(FilmingPricing.lateCancelFeeCents(onRate: 4000), 600)
    }

    func testDollarsDropsZeroCentsButKeepsRealOnes() {
        XCTAssertEqual(Money.dollars(12000), "$120")
        XCTAssertEqual(Money.dollars(1800), "$18")
        XCTAssertEqual(Money.dollars(1250), "$12.50")
        XCTAssertEqual(Money.dollars(123_456), "$1,234.56")
    }

    // MARK: - The 5-hour rule: must match is_late_cancellation

    func testLessThanFiveHoursBeforeTheStartIsLate() {
        XCTAssertTrue(LateCancellation.isLate(startsAt: start,
                                              cancelledAt: start.addingTimeInterval(-(5 * 3600 - 60))))
    }

    func testExactlyFiveHoursBeforeIsOnTime() {
        XCTAssertFalse(LateCancellation.isLate(startsAt: start,
                                               cancelledAt: start.addingTimeInterval(-5 * 3600)))
    }

    func testMoreThanFiveHoursBeforeIsOnTime() {
        XCTAssertFalse(LateCancellation.isLate(startsAt: start,
                                               cancelledAt: start.addingTimeInterval(-(5 * 3600 + 60))))
    }

    func testAfterTheStartIsLate() {
        XCTAssertTrue(LateCancellation.isLate(startsAt: start, cancelledAt: start.addingTimeInterval(600)))
    }

    func testSkaterLateCancelOfAnAcceptedSessionWarnsAboutTheFee() {
        let request = makeRequest(status: .accepted, rateCents: 12000)
        XCTAssertEqual(
            LateCancellation.warning(for: .skater, request: request,
                                     at: start.addingTimeInterval(-3 * 3600)),
            "The session starts in under 5 hours, so cancelling now costs $18 (15% of the $120 rate), paid to Spot Check.")
    }

    func testFilmerLateCancelWarnsAboutAStrike() {
        let request = makeRequest(status: .accepted, rateCents: 12000)
        XCTAssertEqual(
            LateCancellation.warning(for: .filmer, request: request,
                                     at: start.addingTimeInterval(-3 * 3600)),
            "The session starts in under 5 hours, so cancelling now counts as a strike. Three strikes pause your profile.")
    }

    func testNoWarningWhenCancellingInGoodTime() {
        let request = makeRequest(status: .accepted, rateCents: 12000)
        XCTAssertNil(LateCancellation.warning(for: .skater, request: request,
                                              at: start.addingTimeInterval(-6 * 3600)))
        XCTAssertNil(LateCancellation.warning(for: .filmer, request: request,
                                              at: start.addingTimeInterval(-6 * 3600)))
    }

    /// Nobody had accepted it, so there's no rate and nothing is charged --
    /// the database records it as late but takes no fee.
    func testNoWarningForALateCancelOfAnUnacceptedRequest() {
        let request = makeRequest(status: .requested, rateCents: nil)
        XCTAssertNil(LateCancellation.warning(for: .skater, request: request,
                                              at: start.addingTimeInterval(-60)))
    }

    // MARK: - Booking form

    func testDraftEndsTheChosenNumberOfHoursAfterItStarts() {
        let draft = makeDraft(package: .hourlyStreet, hours: 3)
        XCTAssertEqual(draft.endsAt, start.addingTimeInterval(3 * 3600))
    }

    func testParkDropInIsAlwaysAOneHourBlock() {
        XCTAssertEqual(FilmingRequestDraft.hourOptions(for: .parkDropIn), [1])
        XCTAssertEqual(FilmingRequestDraft.hourOptions(for: .hourlyStreet), Array(1...6))
        XCTAssertEqual(FilmingRequestDraft.hourOptions(for: .fullEdit), Array(1...6))

        var draft = makeDraft(package: .hourlyStreet, hours: 4)
        draft.package = .parkDropIn
        XCTAssertEqual(draft.hours, 1, "switching to a drop-in snaps the length to its only option")
    }

    func testDraftMustStartInTheFuture() {
        let draft = makeDraft(package: .hourlyStreet, hours: 2)
        XCTAssertNil(draft.problem(now: start.addingTimeInterval(-60)))
        XCTAssertEqual(draft.problem(now: start), "Pick a start time in the future.")
        XCTAssertEqual(draft.problem(now: start.addingTimeInterval(60)), "Pick a start time in the future.")
    }

    func testDraftPriceIsKnownOnlyWhenAFilmerIsNamed() {
        let open = makeDraft(package: .hourlyStreet, hours: 2)
        XCTAssertNil(open.quotedRateCents(namedFilmerRates: nil))
        XCTAssertEqual(open.quotedRateCents(namedFilmerRates: filmerRates), 12000)

        let fullEdit = makeDraft(package: .fullEdit, hours: 2)
        XCTAssertNil(fullEdit.quotedRateCents(namedFilmerRates: filmerRates),
                     "a full edit is quoted by the filmer when they accept")
    }

    // MARK: - Discover

    func testDiscoverGroupsByStartDayInOrderAndLabelsTodayAndTomorrow() {
        let calendar = utcCalendar
        // 2027-01-15 06:00 UTC, a Friday
        let now = Date(timeIntervalSince1970: 1_799_992_800)
        let requests = [
            makeRequest(id: 3, startsAt: now.addingTimeInterval(2 * 86_400)),
            makeRequest(id: 1, startsAt: now.addingTimeInterval(3600)),
            makeRequest(id: 2, startsAt: now.addingTimeInterval(86_400)),
            makeRequest(id: 4, startsAt: now.addingTimeInterval(5 * 3600)),
        ]

        let sections = DiscoverFeed.sections(requests, filter: .all, now: now, calendar: calendar)

        XCTAssertEqual(sections.map(\.title), ["Today · Fri 15", "Tomorrow · Sat 16", "Sun 17 Jan"])
        XCTAssertEqual(sections[0].requests.map(\.id), [uuid(1), uuid(4)], "earliest first within a day")
    }

    func testDiscoverFilterMatchesThePackage() {
        let requests = [
            makeRequest(id: 1, package: .hourlyStreet),
            makeRequest(id: 2, package: .parkDropIn),
            makeRequest(id: 3, package: .fullEdit),
        ]
        func ids(_ filter: DiscoverFilter) -> [UUID] {
            DiscoverFeed.sections(requests, filter: filter, now: start, calendar: utcCalendar)
                .flatMap(\.requests).map(\.id)
        }

        XCTAssertEqual(Set(ids(.all)), [uuid(1), uuid(2), uuid(3)])
        XCTAssertEqual(ids(.street), [uuid(1)])
        XCTAssertEqual(ids(.park), [uuid(2)])
        XCTAssertEqual(ids(.fullEdit), [uuid(3)])
        XCTAssertEqual(DiscoverFilter.allCases.map(\.title), ["All", "Street", "Park", "Full edit"])
    }

    // MARK: - Fixtures

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    private func uuid(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "f0000000-0000-4000-8000-%012d", n))!
    }

    private func makeRequest(
        id: Int = 1,
        package: FilmingPackage = .hourlyStreet,
        status: FilmingRequestStatus = .requested,
        rateCents: Int? = nil,
        startsAt: Date? = nil
    ) -> FilmingRequest {
        let startsAt = startsAt ?? start
        return FilmingRequest(
            id: uuid(id),
            skaterID: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            requestedFilmerID: nil,
            filmerID: status == .accepted ? UUID(uuidString: "22222222-2222-4222-8222-222222222222")! : nil,
            package: package,
            spotID: nil,
            lat: 42.3493,
            lng: -71.0767,
            locationLabel: "Copley Library",
            startsAt: startsAt,
            endsAt: startsAt.addingTimeInterval(2 * 3600),
            lighting: .goldenHour,
            securityRisk: .sometimes,
            notes: nil,
            rateCents: rateCents,
            status: status,
            acceptedAt: status == .accepted ? startsAt.addingTimeInterval(-86_400) : nil,
            cancelledAt: nil,
            cancelledBy: nil,
            cancellationWasLate: nil,
            createdAt: startsAt.addingTimeInterval(-2 * 86_400),
            skater: FilmingRequest.PartyName(username: "rider_nguyen")
        )
    }

    private func makeDraft(package: FilmingPackage, hours: Int) -> FilmingRequestDraft {
        FilmingRequestDraft(
            package: package,
            startsAt: start,
            hours: hours,
            place: .pin(lat: 42.3493, lng: -71.0767, label: "Pin near Copley Square"),
            lighting: .goldenHour,
            securityRisk: .sometimes,
            requestedFilmerID: nil
        )
    }
}
