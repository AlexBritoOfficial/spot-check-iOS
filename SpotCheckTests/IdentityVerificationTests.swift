import XCTest
@testable import SpotCheck

/// IDVerifyScreen's behaviour, without Stripe: what `identity-session`'s
/// answers decode to, what each stored verification row means on screen, and
/// how the flow moves when the Stripe sheet closes. The sheet is a closure
/// here, so each of its three outcomes can be driven directly.
@MainActor
final class IdentityVerificationTests: XCTestCase {

    private let userID = UUID(uuidString: "33333333-3333-4333-8333-333333333333")!

    // MARK: - identity-session's response

    func testAnAlreadyVerifiedUserIsNotSentThroughStripeAgain() throws {
        let start = try IdentitySessionStart.decode(json(#"{"status":"verified"}"#))
        XCTAssertEqual(start, .alreadyVerified)
    }

    func testASessionStripeIsStillCheckingIsNotRestarted() throws {
        let start = try IdentitySessionStart.decode(json(#"{"status":"processing"}"#))
        XCTAssertEqual(start, .alreadySubmitted)
    }

    func testANewSessionCarriesTheClientSecretTheSheetNeeds() throws {
        let start = try IdentitySessionStart.decode(json(
            #"{"status":"requires_input","client_secret":"vs_123_secret_abc","session_id":"vs_123"}"#
        ))
        XCTAssertEqual(start, .verify(clientSecret: "vs_123_secret_abc"))
    }

    func testANewSessionWithoutAClientSecretIsAnError() {
        XCTAssertThrowsError(try IdentitySessionStart.decode(json(#"{"status":"requires_input"}"#)))
    }

    // MARK: - The stored row

    func testTheRowDecodesFromPostgres() throws {
        let row = try SupabaseDecoders.decoder.decode(IdentityVerification.self, from: json(
            #"{"status":"requires_input","last_error_code":"document_expired","verified_is_adult":null}"#
        ))
        XCTAssertEqual(row.status, .requiresInput)
        XCTAssertEqual(row.lastErrorCode, "document_expired")
        XCTAssertNil(row.verifiedIsAdult)
    }

    func testOnlyAVerifiedAdultCountsAsVerified() {
        XCTAssertTrue(row(.verified, adult: true).isVerifiedAdult)
        XCTAssertFalse(row(.verified, adult: false).isVerifiedAdult)
        XCTAssertFalse(row(.processing).isVerifiedAdult)
    }

    func testWhatEachRowMeansOnScreen() {
        typealias State = IdentityVerificationFlow.State
        XCTAssertEqual(State(row: nil), .notStarted)
        // A session was created but never submitted: nothing has gone wrong.
        XCTAssertEqual(State(row: row(.requiresInput)), .notStarted)
        XCTAssertEqual(State(row: row(.canceled)), .notStarted)
        XCTAssertEqual(State(row: row(.processing)), .processing)
        XCTAssertEqual(State(row: row(.verified, adult: true)), .verified)
        XCTAssertEqual(State(row: row(.verified, adult: false)), .notAdult)
        XCTAssertEqual(
            State(row: row(.requiresInput, error: "document_expired")),
            .needsRetry(reason: "Your ID has expired. Try again with a current one.")
        )
    }

    func testAVerifiedIDWithNoReadableBirthDateIsUnknownNotUnder18() {
        // The webhook saves verified_is_adult = null when Stripe returns no
        // date of birth. That is "we don't know", and must never be shown as
        // "your ID shows you're under 18".
        typealias State = IdentityVerificationFlow.State
        XCTAssertEqual(State(row: row(.verified, adult: nil)), .ageUnknown)
    }

    func testAnUnknownAgeExplainsItselfAndOffersAnotherTry() {
        typealias State = IdentityVerificationFlow.State
        XCTAssertEqual(State.ageUnknown.primaryAction, .start(title: "Try again"))
        XCTAssertEqual(
            State.ageUnknown.statusMessage,
            "Your ID was verified, but we couldn't read the date of birth on it. Try again with an ID where it's clear."
        )
        XCTAssertTrue(State.ageUnknown.offersSkip(in: .standalone))
    }

    func testWhichStatesAreShownAsAProblem() {
        typealias State = IdentityVerificationFlow.State
        let problems: [State] = [.needsRetry(reason: "x"), .failed(message: "x"), .notAdult, .ageUnknown]
        for state in problems {
            XCTAssertTrue(state.isProblem, "\(state)")
        }
        let fine: [State] = [.loading, .notStarted, .starting, .inProgress, .processing, .verified]
        for state in fine {
            XCTAssertFalse(state.isProblem, "\(state)")
        }
    }

    func testAnUnknownStripeErrorStillGivesAReason() {
        XCTAssertEqual(
            IdentityVerificationFlow.State(row: row(.requiresInput, error: "something_new")),
            .needsRetry(reason: "We couldn't verify your ID. Try again.")
        )
    }

    func testTheFooterButtonForEachState() {
        typealias State = IdentityVerificationFlow.State
        XCTAssertEqual(State.notStarted.primaryAction, .start(title: "Start verification"))
        XCTAssertEqual(State.needsRetry(reason: "x").primaryAction, .start(title: "Try again"))
        XCTAssertEqual(State.failed(message: "x").primaryAction, .start(title: "Try again"))
        XCTAssertEqual(State.starting.primaryAction, .busy(title: "Starting…"))
        XCTAssertEqual(State.inProgress.primaryAction, .busy(title: "Verifying…"))
        // Stripe's answer arrives by webhook, so there is something to re-check.
        XCTAssertEqual(State.processing.primaryAction, .refresh(title: "Check status"))
        XCTAssertEqual(State.verified.primaryAction, .done)
        XCTAssertEqual(State.notAdult.primaryAction, .done)
    }

    // MARK: - The flow

    func testLoadingShowsTheStoredState() async {
        let api = FakeIdentityVerificationAPI(row: row(.processing))
        let flow = IdentityVerificationFlow(api: api)

        await flow.load(userID: userID)

        XCTAssertEqual(flow.state, .processing)
    }

    func testFinishingTheSheetWaitsOnStripeUntilTheWebhookLands() async {
        let api = FakeIdentityVerificationAPI(row: nil)
        api.start = .verify(clientSecret: "vs_1_secret_x")
        let flow = IdentityVerificationFlow(api: api)
        await flow.load(userID: userID)

        var presentedSecret: String?
        await flow.start(userID: userID) { secret in
            presentedSecret = secret
            // Stripe created the session's row, but the webhook hasn't run.
            api.row = self.row(.requiresInput)
            return .completed
        }

        XCTAssertEqual(presentedSecret, "vs_1_secret_x")
        // Not "Start verification" again: the user just submitted.
        XCTAssertEqual(flow.state, .processing)
    }

    func testFinishingTheSheetAfterTheWebhookShowsVerifiedAndReportsIt() async {
        let api = FakeIdentityVerificationAPI(row: nil)
        api.start = .verify(clientSecret: "vs_1_secret_x")
        var reported = 0
        let flow = IdentityVerificationFlow(api: api, onVerified: { reported += 1 })

        await flow.start(userID: userID) { _ in
            api.row = self.row(.verified, adult: true)
            return .completed
        }

        XCTAssertEqual(flow.state, .verified)
        XCTAssertEqual(reported, 1)
    }

    func testCancellingTheSheetGoesBackToWhereTheUserWas() async {
        let api = FakeIdentityVerificationAPI(row: row(.requiresInput, error: "selfie_face_mismatch"))
        api.start = .verify(clientSecret: "vs_1_secret_x")
        let flow = IdentityVerificationFlow(api: api)
        await flow.load(userID: userID)
        let before = flow.state

        await flow.start(userID: userID) { _ in .canceled }

        XCTAssertEqual(flow.state, before)
    }

    func testFinishingTheSheetAfterAWebhookWithNoBirthDateSaysSo() async {
        let api = FakeIdentityVerificationAPI(row: nil)
        api.start = .verify(clientSecret: "vs_1_secret_x")
        var reported = 0
        let flow = IdentityVerificationFlow(api: api, onVerified: { reported += 1 })

        await flow.start(userID: userID) { _ in
            api.row = self.row(.verified, adult: nil)
            return .completed
        }

        // A final answer: not "Stripe is checking" forever, and not verified.
        XCTAssertEqual(flow.state, .ageUnknown)
        XCTAssertEqual(reported, 0)
    }

    func testTheSheetFailingShowsWhy() async {
        let api = FakeIdentityVerificationAPI(row: nil)
        api.start = .verify(clientSecret: "vs_1_secret_x")
        let flow = IdentityVerificationFlow(api: api)

        await flow.start(userID: userID) { _ in .failed(message: "The camera is unavailable.") }

        XCTAssertEqual(flow.state, .failed(message: "The camera is unavailable."))
    }

    func testAnAlreadyVerifiedUserSkipsTheSheet() async {
        let api = FakeIdentityVerificationAPI(row: nil)
        api.start = .alreadyVerified
        api.row = row(.verified, adult: true)
        let flow = IdentityVerificationFlow(api: api)

        var presented = false
        await flow.start(userID: userID) { _ in presented = true; return .completed }

        XCTAssertFalse(presented)
        XCTAssertEqual(flow.state, .verified)
    }

    func testTheServerRefusingToStartShowsItsMessage() async {
        let api = FakeIdentityVerificationAPI(row: nil)
        api.startError = EdgeFunctionError(statusCode: 500, body: Data(#"{"error":"Could not start verification."}"#.utf8))
        let flow = IdentityVerificationFlow(api: api)

        await flow.start(userID: userID) { _ in .completed }

        XCTAssertEqual(flow.state, .failed(message: "Could not start verification."))
    }

    func testCheckingStatusPicksUpTheWebhooksAnswer() async {
        let api = FakeIdentityVerificationAPI(row: row(.processing))
        let flow = IdentityVerificationFlow(api: api)
        await flow.load(userID: userID)

        api.row = row(.verified, adult: true)
        await flow.refresh(userID: userID)

        XCTAssertEqual(flow.state, .verified)
    }

    func testTheCheckingNoteStaysUntilTheWebhookLands() async {
        // After the sheet, the row stays requires_input until Stripe's first
        // webhook lands. A re-check in that gap used to read it as "not
        // started": the clock note vanished after 3 seconds and the button
        // went back to "Start verification".
        let api = FakeIdentityVerificationAPI(row: nil)
        api.start = .verify(clientSecret: "vs_1_secret_x")
        let sleeper = CountingSleeper {
            switch $0 {
            case 1: break // No webhook yet: still requires_input.
            case 2: api.row = self.row(.processing)
            default: api.row = self.row(.verified, adult: true)
            }
        }
        let flow = IdentityVerificationFlow(api: api, sleep: sleeper.sleep)
        await flow.load(userID: userID)
        await flow.start(userID: userID) { _ in
            api.row = self.row(.requiresInput)
            return .completed
        }
        XCTAssertEqual(flow.state, .processing)

        await flow.keepCheckingWhileProcessing(userID: userID, every: .seconds(3))

        XCTAssertEqual(flow.state, .verified)
        XCTAssertEqual(sleeper.calls, 3)
    }

    func testCheckStatusBeforeTheWebhookKeepsShowingChecking() async {
        let api = FakeIdentityVerificationAPI(row: nil)
        api.start = .verify(clientSecret: "vs_1_secret_x")
        let flow = IdentityVerificationFlow(api: api)
        await flow.start(userID: userID) { _ in
            api.row = self.row(.requiresInput)
            return .completed
        }

        await flow.refresh(userID: userID)

        XCTAssertEqual(flow.state, .processing)
    }

    func testATurnedDownAttemptStillEndsTheCheckingState() async {
        // Only a requires_input row *without* an error is "not landed yet";
        // one with an error is Stripe's answer.
        let api = FakeIdentityVerificationAPI(row: nil)
        api.start = .verify(clientSecret: "vs_1_secret_x")
        let flow = IdentityVerificationFlow(api: api)
        await flow.start(userID: userID) { _ in
            api.row = self.row(.requiresInput)
            return .completed
        }

        api.row = row(.requiresInput, error: "document_expired")
        await flow.refresh(userID: userID)

        XCTAssertEqual(flow.state, .needsRetry(reason: "Your ID has expired. Try again with a current one."))
    }

    // MARK: - Fixtures

    private func row(_ status: IdentityStatus, adult: Bool? = nil, error: String? = nil) -> IdentityVerification {
        IdentityVerification(status: status, lastErrorCode: error, verifiedIsAdult: adult)
    }

    private func json(_ string: String) -> Data { Data(string.utf8) }
}

@MainActor
final class FakeIdentityVerificationAPI: IdentityVerificationAPI {
    var row: IdentityVerification?
    var start: IdentitySessionStart = .alreadySubmitted
    var startError: Error?

    init(row: IdentityVerification?) {
        self.row = row
    }

    func verification(for userID: UUID) async throws -> IdentityVerification? {
        row
    }

    func startSession() async throws -> IdentitySessionStart {
        if let startError { throw startError }
        return start
    }
}
