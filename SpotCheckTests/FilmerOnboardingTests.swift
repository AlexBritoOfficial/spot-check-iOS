import XCTest
@testable import SpotCheck

/// "Earn with Spot Check", ID first: ProApply → IDVerify → FilmerQualify →
/// Verification → FilmerRates → live. Everything a screen decides is tested
/// here without the screen: where the flow resumes, where Continue goes,
/// when re-checking stops, what is submitted, and the go-live order.
@MainActor
final class FilmerOnboardingTests: XCTestCase {

    private let userID = UUID(uuidString: "AAAAAAAA-1111-4111-8111-111111111111")!

    // MARK: - Where "Earn with Spot Check" opens

    func testSomeoneWhoNeverAppliedSeesThePitch() {
        XCTAssertEqual(FilmerOnboarding.entry(application: nil, filmerStatus: nil), .pitch)
    }

    func testAnApplicationInReviewReopensAtItsStatusNotThePitch() {
        XCTAssertEqual(
            FilmerOnboarding.entry(application: application(), filmerStatus: .inReview),
            .review
        )
        // Cleared but not live yet: still the status screen, which offers
        // "Set rates & go live".
        XCTAssertEqual(
            FilmerOnboarding.entry(application: application(gear: .passed, check: .passed), filmerStatus: .inReview),
            .review
        )
    }

    func testAPausedFilmerSeesWhyRatherThanThePitch() {
        XCTAssertEqual(
            FilmerOnboarding.entry(application: application(pausedAt: Date()), filmerStatus: .paused),
            .paused
        )
        // Either signal is enough: the profile's pause or the capability's.
        XCTAssertEqual(FilmerOnboarding.entry(application: application(), filmerStatus: .paused), .paused)
        XCTAssertEqual(FilmerOnboarding.entry(application: application(pausedAt: Date()), filmerStatus: .active), .paused)
    }

    func testAnActiveFilmerIsAlreadyLive() {
        XCTAssertEqual(
            FilmerOnboarding.entry(application: application(gear: .passed, check: .passed), filmerStatus: .active),
            .live
        )
    }

    func testARevokedFilmerCanApplyAgainFromThePitch() {
        XCTAssertEqual(FilmerOnboarding.entry(application: application(), filmerStatus: .revoked), .pitch)
    }

    // MARK: - The pitch's Continue (ID first)

    func testContinueAsksForAnIDWhenThereIsNone() {
        XCTAssertEqual(FilmerOnboarding.stepAfterPitch(identity: nil), .verifyID)
        XCTAssertEqual(FilmerOnboarding.stepAfterPitch(identity: id(.requiresInput)), .verifyID)
        XCTAssertEqual(FilmerOnboarding.stepAfterPitch(identity: id(.canceled)), .verifyID)
    }

    func testContinueWaitsOnAnIDStripeIsStillChecking() {
        // Alex: wait for the ID to be verified before the portfolio step.
        XCTAssertEqual(FilmerOnboarding.stepAfterPitch(identity: id(.processing)), .verifyID)
    }

    func testAVerifiedAdultSkipsStraightToThePortfolio() {
        XCTAssertEqual(FilmerOnboarding.stepAfterPitch(identity: id(.verified, adult: true)), .portfolio)
    }

    func testAnUnder18IDStopsTheFlow() {
        XCTAssertEqual(FilmerOnboarding.stepAfterPitch(identity: id(.verified, adult: false)), .notAdult)
    }

    // MARK: - IDVerify inside the flow

    func testInsideTheFlowThereIsNoSkipForNow() {
        typealias State = IdentityVerificationFlow.State
        let states: [State] = [.loading, .notStarted, .needsRetry(reason: "x"), .starting,
                               .inProgress, .processing, .verified, .notAdult, .failed(message: "x")]
        for state in states {
            XCTAssertFalse(state.offersSkip(in: .filmerOnboarding), "\(state)")
        }
        // Unchanged from the menu: skippable until there's nothing left to do.
        XCTAssertTrue(State.notStarted.offersSkip(in: .standalone))
        XCTAssertTrue(State.processing.offersSkip(in: .standalone))
        XCTAssertFalse(State.verified.offersSkip(in: .standalone))
    }

    func testContinueUnlocksOnlyOnceVerified() {
        typealias State = IdentityVerificationFlow.State
        XCTAssertEqual(State.verified.primaryAction(in: .filmerOnboarding), .continueOnboarding)
        XCTAssertEqual(State.processing.primaryAction(in: .filmerOnboarding), .refresh(title: "Check status"))
        XCTAssertEqual(State.notStarted.primaryAction(in: .filmerOnboarding), .start(title: "Start verification"))
        // Under 18 ends here: Done closes the flow, there is no next step.
        XCTAssertEqual(State.notAdult.primaryAction(in: .filmerOnboarding), .done)
        // The menu's screen keeps its plain Done.
        XCTAssertEqual(State.verified.primaryAction(in: .standalone), .done)
    }

    func testWhileStripeChecksTheScreenReChecksUntilVerified() async {
        let api = FakeIdentityVerificationAPI(row: id(.processing))
        let sleeper = CountingSleeper {
            // The webhook lands during the second wait.
            if $0 == 2 { api.row = self.id(.verified, adult: true) }
        }
        let flow = IdentityVerificationFlow(api: api, sleep: sleeper.sleep)
        await flow.load(userID: userID)

        await flow.keepCheckingWhileProcessing(userID: userID, every: .seconds(3))

        XCTAssertEqual(flow.state, .verified)
        XCTAssertEqual(sleeper.calls, 2)
        XCTAssertEqual(sleeper.durations, [.seconds(3), .seconds(3)])
    }

    func testReCheckingStopsOnAFinalAnswerThatIsNotVerified() async {
        let api = FakeIdentityVerificationAPI(row: id(.processing))
        let sleeper = CountingSleeper { _ in api.row = self.id(.requiresInput, error: "document_expired") }
        let flow = IdentityVerificationFlow(api: api, sleep: sleeper.sleep)
        await flow.load(userID: userID)

        await flow.keepCheckingWhileProcessing(userID: userID, every: .seconds(3))

        XCTAssertEqual(flow.state, .needsRetry(reason: "Your ID has expired. Try again with a current one."))
        XCTAssertEqual(sleeper.calls, 1)
    }

    func testNothingIsReCheckedWhenStripeIsNotChecking() async {
        let api = FakeIdentityVerificationAPI(row: nil)
        let sleeper = CountingSleeper()
        let flow = IdentityVerificationFlow(api: api, sleep: sleeper.sleep)
        await flow.load(userID: userID)

        await flow.keepCheckingWhileProcessing(userID: userID, every: .seconds(3))

        XCTAssertEqual(sleeper.calls, 0)
    }

    func testLeavingTheScreenStopsReChecking() async {
        let api = FakeIdentityVerificationAPI(row: id(.processing))
        // SwiftUI cancels a view's task when it disappears; the sleep throws.
        let sleeper = CountingSleeper(throwsOnCall: 1)
        let flow = IdentityVerificationFlow(api: api, sleep: sleeper.sleep)
        await flow.load(userID: userID)

        await flow.keepCheckingWhileProcessing(userID: userID, every: .seconds(3))

        XCTAssertEqual(flow.state, .processing)
        XCTAssertEqual(sleeper.calls, 1)
    }

    // MARK: - The portfolio step

    func testSubmittingNeedsConsentToTheBackgroundCheck() {
        var draft = FilmerApplicationDraft()
        XCTAssertFalse(draft.canSubmit)
        draft.consentsToBackgroundCheck = true
        XCTAssertTrue(draft.canSubmit)
    }

    func testTheDraftStartsWithTheCanvasSelections() {
        let draft = FilmerApplicationDraft()
        XCTAssertEqual(draft.gear, [
            "VX1000 / tapeless", "DSLR/mirrorless + fisheye", "External shotgun mic", "Filmer cruiser board"
        ])
        XCTAssertEqual(draft.styles, ["Street follow-lines", "Night / external lighting"])
    }

    func testTheRequestListsChoicesInTheOrderTheScreenShowsThem() {
        var draft = FilmerApplicationDraft()
        draft.gear = ["Filmer cruiser board", "Long lens (telephoto)"]
        draft.styles = ["Quick social clips", "Park / transition"]
        draft.consentsToBackgroundCheck = true

        let request = draft.request(userID: userID)

        XCTAssertEqual(request.gear, ["Long lens (telephoto)", "Filmer cruiser board"])
        XCTAssertEqual(request.styles, ["Park / transition", "Quick social clips"])
        XCTAssertTrue(request.consent)
    }

    func testTheSampleClipsSitUnderTheLowercasedUserFolder() {
        // Storage RLS compares the first folder to auth.uid()::text, which is
        // lowercase; Swift's uuidString is uppercase.
        let request = FilmerApplicationDraft().request(userID: userID)
        XCTAssertEqual(request.rawClipPath, "aaaaaaaa-1111-4111-8111-111111111111/sample-raw-follow-line.mp4")
        XCTAssertEqual(request.reelPath, "aaaaaaaa-1111-4111-8111-111111111111/sample-highlight-reel.mp4")
    }

    func testTheRequestBodyIsWhatTheFunctionReads() throws {
        var draft = FilmerApplicationDraft()
        draft.gear = ["VX1000 / tapeless"]
        draft.styles = []
        draft.consentsToBackgroundCheck = true

        let body = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(draft.request(userID: userID))
        ) as? [String: Any]

        XCTAssertEqual(Set(body?.keys ?? [:].keys), ["gear", "styles", "reel_path", "raw_clip_path", "consent"])
        XCTAssertEqual(body?["consent"] as? Bool, true)
        XCTAssertEqual(body?["gear"] as? [String], ["VX1000 / tapeless"])
    }

    func testSubmittingSendsTheApplicationAndReadsBackItsStatus() async {
        let api = FakeFilmerOnboardingAPI()
        api.applicationAfterSubmit = application()
        let flow = FilmerOnboardingFlow(api: api)
        var draft = FilmerApplicationDraft()
        draft.consentsToBackgroundCheck = true

        let submitted = await flow.submit(draft, userID: userID)

        XCTAssertTrue(submitted)
        XCTAssertEqual(api.submitted, [draft.request(userID: userID)])
        XCTAssertEqual(flow.application, application())
        XCTAssertNil(flow.errorMessage)
    }

    func testWithoutConsentNothingIsSent() async {
        let api = FakeFilmerOnboardingAPI()
        let flow = FilmerOnboardingFlow(api: api)

        let submitted = await flow.submit(FilmerApplicationDraft(), userID: userID)

        XCTAssertFalse(submitted)
        XCTAssertTrue(api.submitted.isEmpty)
    }

    func testARefusedApplicationShowsTheFunctionsSentence() async {
        let api = FakeFilmerOnboardingAPI()
        api.submitError = EdgeFunctionError(statusCode: 403, body: Data(
            #"{"error":"identity_verification_required","message":"Verify your ID before applying to film."}"#.utf8
        ))
        let flow = FilmerOnboardingFlow(api: api)
        var draft = FilmerApplicationDraft()
        draft.consentsToBackgroundCheck = true

        let submitted = await flow.submit(draft, userID: userID)

        XCTAssertFalse(submitted)
        XCTAssertEqual(flow.errorMessage, "Verify your ID before applying to film.")
        XCTAssertFalse(flow.isSubmitting)
    }

    // MARK: - The status checklist

    func testTheFilmerProfileRowDecodesFromPostgres() throws {
        let row = try SupabaseDecoders.decoder.decode(FilmerApplication.self, from: Data(#"""
        {"gear":["VX1000 / tapeless"],"styles":[],"reel_path":null,
         "raw_clip_path":"a/sample.mp4","hourly_rate_cents":null,"park_drop_in_cents":null,
         "consent_signed_at":"2026-11-25T06:00:00.123456+00:00",
         "gear_review_status":"in_review","background_check_status":"pending",
         "went_live_at":null,"paused_at":null}
        """#.utf8))
        XCTAssertEqual(row.gear, ["VX1000 / tapeless"])
        XCTAssertEqual(row.gearReviewStatus, .inReview)
        XCTAssertEqual(row.backgroundCheckStatus, .pending)
        XCTAssertNotNil(row.consentSignedAt)
        XCTAssertNil(row.pausedAt)
    }

    func testJustSubmittedIsInReviewAndKeepsChecking() {
        let progress = FilmerReviewProgress(identity: id(.verified, adult: true), application: application())
        XCTAssertTrue(progress.isIDVerified)
        XCTAssertTrue(progress.isConsentSigned)
        XCTAssertEqual(progress.gearReview, .inReview)
        XCTAssertEqual(progress.backgroundCheck, .pending)
        XCTAssertFalse(progress.isCleared)
        XCTAssertTrue(progress.shouldKeepChecking)
    }

    func testClearedNeedsBothReviewsAndTheID() {
        XCTAssertTrue(FilmerReviewProgress(
            identity: id(.verified, adult: true), application: application(gear: .passed, check: .passed)
        ).isCleared)
        XCTAssertFalse(FilmerReviewProgress(
            identity: id(.verified, adult: true), application: application(gear: .passed, check: .inReview)
        ).isCleared)
        XCTAssertFalse(FilmerReviewProgress(
            identity: id(.verified, adult: true), application: application(gear: .inReview, check: .passed)
        ).isCleared)
        XCTAssertFalse(FilmerReviewProgress(
            identity: id(.processing), application: application(gear: .passed, check: .passed)
        ).isCleared)
    }

    func testAFailedReviewStopsCheckingAndIsNotCleared() {
        let progress = FilmerReviewProgress(
            identity: id(.verified, adult: true), application: application(gear: .passed, check: .failed)
        )
        XCTAssertTrue(progress.hasFailure)
        XCTAssertFalse(progress.isCleared)
        XCTAssertFalse(progress.shouldKeepChecking)
    }

    func testTheStatusScreenReChecksEveryTenSecondsUntilCleared() async {
        let api = FakeFilmerOnboardingAPI()
        api.identity = id(.verified, adult: true)
        api.application = application()
        let sleeper = CountingSleeper {
            // The QA mock passes both reviews about a minute in.
            if $0 == 3 { api.application = self.application(gear: .passed, check: .passed) }
        }
        let flow = FilmerOnboardingFlow(api: api, sleep: sleeper.sleep)
        await flow.load(userID: userID)

        await flow.keepCheckingReview(userID: userID)

        XCTAssertTrue(flow.reviewProgress.isCleared)
        XCTAssertEqual(sleeper.calls, 3)
        XCTAssertEqual(sleeper.durations.first, .seconds(10))
    }

    func testLeavingTheStatusScreenStopsReChecking() async {
        let api = FakeFilmerOnboardingAPI()
        api.identity = id(.verified, adult: true)
        api.application = application()
        let sleeper = CountingSleeper(throwsOnCall: 1)
        let flow = FilmerOnboardingFlow(api: api, sleep: sleeper.sleep)
        await flow.load(userID: userID)

        await flow.keepCheckingReview(userID: userID)

        XCTAssertEqual(sleeper.calls, 1)
        XCTAssertFalse(flow.reviewProgress.isCleared)
    }

    func testLoadingReadsTheApplicationIDAndCapability() async {
        let api = FakeFilmerOnboardingAPI()
        api.identity = id(.verified, adult: true)
        api.application = application()
        api.filmerStatus = .inReview
        let flow = FilmerOnboardingFlow(api: api)

        await flow.load(userID: userID)

        XCTAssertEqual(flow.entry, .review)
        XCTAssertEqual(flow.stepAfterPitch, .portfolio)
        XCTAssertFalse(flow.isLoading)
    }

    // MARK: - Going live

    func testGoingLiveSavesTheSampleRatesThenGoesLive() async {
        let api = FakeFilmerOnboardingAPI()
        let flow = FilmerOnboardingFlow(api: api)
        var wentLive = 0

        let live = await flow.goLive(userID: userID) {
            // By now the capability is active, so the app can switch mode.
            XCTAssertEqual(api.calls, ["saveRates", "goLive"])
            wentLive += 1
        }

        XCTAssertTrue(live)
        XCTAssertEqual(api.calls, ["saveRates", "goLive"])
        // Rates are on hold (Alex: "let's circle back"): the seeded filmer's.
        XCTAssertEqual(api.savedRates, [FilmerRates(hourlyCents: 6000, parkDropInCents: 4000)])
        XCTAssertEqual(wentLive, 1)
    }

    func testIfTheRatesDoNotSaveItDoesNotGoLive() async {
        let api = FakeFilmerOnboardingAPI()
        api.saveRatesError = URLError(.notConnectedToInternet)
        let flow = FilmerOnboardingFlow(api: api)
        var wentLive = false

        let live = await flow.goLive(userID: userID) { wentLive = true }

        XCTAssertFalse(live)
        XCTAssertEqual(api.calls, ["saveRates"])
        XCTAssertFalse(wentLive)
        XCTAssertEqual(flow.errorMessage, EdgeFunctionError.genericMessage)
    }

    func testARefusedGoLiveIsNotReportedAsLive() async {
        let api = FakeFilmerOnboardingAPI()
        api.goLiveError = URLError(.badServerResponse)
        let flow = FilmerOnboardingFlow(api: api)
        var wentLive = false

        let live = await flow.goLive(userID: userID) { wentLive = true }

        XCTAssertFalse(live)
        XCTAssertFalse(wentLive)
        XCTAssertFalse(flow.isGoingLive)
        XCTAssertNotNil(flow.errorMessage)
    }

    // MARK: - Fixtures

    private func id(_ status: IdentityStatus, adult: Bool? = nil, error: String? = nil) -> IdentityVerification {
        IdentityVerification(status: status, lastErrorCode: error, verifiedIsAdult: adult)
    }

    private func application(
        gear: ReviewStatus = .inReview,
        check: ReviewStatus = .pending,
        pausedAt: Date? = nil
    ) -> FilmerApplication {
        FilmerApplication(
            gear: ["VX1000 / tapeless"],
            styles: ["Street follow-lines"],
            reelPath: nil,
            rawClipPath: "a/sample.mp4",
            hourlyRateCents: nil,
            parkDropInCents: nil,
            consentSignedAt: Date(timeIntervalSince1970: 1_795_600_000),
            gearReviewStatus: gear,
            backgroundCheckStatus: check,
            wentLiveAt: nil,
            pausedAt: pausedAt
        )
    }
}

/// Stands in for `Task.sleep`, so re-checking loops run instantly. `onCall`
/// sees the 1-based call number, to change the world between checks.
@MainActor
final class CountingSleeper {
    private(set) var calls = 0
    private(set) var durations: [Duration] = []
    private let throwsOnCall: Int?
    private let onCall: (Int) -> Void

    init(throwsOnCall: Int? = nil, onCall: @escaping (Int) -> Void = { _ in }) {
        self.throwsOnCall = throwsOnCall
        self.onCall = onCall
    }

    var sleep: @MainActor (Duration) async throws -> Void {
        { [self] duration in
            calls += 1
            durations.append(duration)
            if calls == throwsOnCall { throw CancellationError() }
            onCall(calls)
        }
    }
}

@MainActor
final class FakeFilmerOnboardingAPI: FilmerOnboardingAPI {
    var identity: IdentityVerification?
    var application: FilmerApplication?
    var applicationAfterSubmit: FilmerApplication?
    var filmerStatus: CapabilityStatus?
    var submitError: Error?
    var saveRatesError: Error?
    var goLiveError: Error?

    private(set) var submitted: [SubmitFilmerApplicationRequest] = []
    private(set) var savedRates: [FilmerRates] = []
    private(set) var calls: [String] = []

    func verification(for userID: UUID) async throws -> IdentityVerification? { identity }

    func application(for userID: UUID) async throws -> FilmerApplication? { application }

    func filmerStatus(for userID: UUID) async throws -> CapabilityStatus? { filmerStatus }

    func submit(_ request: SubmitFilmerApplicationRequest) async throws {
        calls.append("submit")
        if let submitError { throw submitError }
        submitted.append(request)
        if let applicationAfterSubmit { application = applicationAfterSubmit }
    }

    func saveRates(_ rates: FilmerRates, for userID: UUID) async throws {
        calls.append("saveRates")
        if let saveRatesError { throw saveRatesError }
        savedRates.append(rates)
    }

    func goLive() async throws {
        calls.append("goLive")
        if let goLiveError { throw goLiveError }
    }
}
