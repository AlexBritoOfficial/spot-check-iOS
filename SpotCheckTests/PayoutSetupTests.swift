import XCTest
@testable import SpotCheck

/// PayoutsScreen's "PAYOUT ACCOUNT" rows, read from `payout_accounts` rather
/// than the artboard's fixed "Verified · •••• 6789", and the trip out to
/// Stripe's hosted Connect onboarding and back.
@MainActor
final class PayoutSetupTests: XCTestCase {

    private let userID = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!
    private let stripeURL = URL(string: "https://connect.stripe.com/setup/e/acct_1/abc")!

    // MARK: - connect-onboarding's response

    func testTheOnboardingLinkDecodes() throws {
        let link = try ConnectOnboardingLink.decode(Data(
            #"{"url":"https://connect.stripe.com/setup/e/acct_1/abc","expires_at":1800000300,"account_id":"acct_1","details_submitted":false,"charges_enabled":false,"payouts_enabled":false}"#.utf8
        ))
        XCTAssertEqual(link.url, stripeURL)
    }

    func testTheRowDecodesFromPostgres() throws {
        let account = try SupabaseDecoders.decoder.decode(PayoutAccount.self, from: Data(
            #"{"bank_last4":"6789","payouts_enabled":true,"details_submitted":true}"#.utf8
        ))
        XCTAssertEqual(account, PayoutAccount(bankLast4: "6789", payoutsEnabled: true, detailsSubmitted: true))
    }

    // MARK: - What the rows say

    func testNoAccountYetOffersSetup() {
        let summary = PayoutAccountSummary(account: nil)
        XCTAssertEqual(summary.bankTitle, "Bank account")
        XCTAssertEqual(summary.bankSubtitle, "Not set up · managed with Stripe")
        XCTAssertEqual(summary.actionTitle, "Set up")
        XCTAssertEqual(summary.taxSubtitle, "Collected by Stripe during payout setup")
        XCTAssertFalse(summary.isTaxComplete)
    }

    func testAnAbandonedOnboardingOffersToFinish() {
        let summary = PayoutAccountSummary(account: account(submitted: false, payouts: false))
        XCTAssertEqual(summary.bankSubtitle, "Unfinished · finish with Stripe")
        XCTAssertEqual(summary.actionTitle, "Finish")
        XCTAssertFalse(summary.isTaxComplete)
    }

    func testSubmittedButNotYetEnabledIsInReview() {
        let summary = PayoutAccountSummary(account: account(submitted: true, payouts: false))
        XCTAssertEqual(summary.bankSubtitle, "In review with Stripe")
        XCTAssertEqual(summary.actionTitle, "Update")
        XCTAssertTrue(summary.isTaxComplete)
    }

    func testAPayableAccountReadsAsTheArtboardDoes() {
        let summary = PayoutAccountSummary(account: account(submitted: true, payouts: true, last4: "6789"))
        XCTAssertEqual(summary.bankTitle, "Bank account •••• 6789")
        XCTAssertEqual(summary.bankSubtitle, "Verified · managed with Stripe")
        XCTAssertEqual(summary.actionTitle, "Update")
        XCTAssertEqual(summary.taxSubtitle, "Complete · collected by Stripe for payouts")
        XCTAssertTrue(summary.isTaxComplete)
    }

    // MARK: - The flow

    func testLoadingReadsTheAccount() async {
        let api = FakePayoutSetupAPI(account: account(submitted: true, payouts: true))
        let flow = PayoutSetupFlow(api: api)

        await flow.load(userID: userID)

        XCTAssertEqual(flow.summary.bankSubtitle, "Verified · managed with Stripe")
        XCTAssertNil(flow.errorMessage)
    }

    func testOpeningStripeHandsOverTheHostedPage() async {
        let api = FakePayoutSetupAPI(account: nil)
        api.link = ConnectOnboardingLink(url: stripeURL)
        let flow = PayoutSetupFlow(api: api)

        await flow.openStripe()

        XCTAssertEqual(flow.stripePage?.url, stripeURL)
        XCTAssertFalse(flow.isOpeningStripe)
    }

    func testARefusedLinkShowsWhyAndOpensNothing() async {
        let api = FakePayoutSetupAPI(account: nil)
        api.linkError = EdgeFunctionError(
            statusCode: 403,
            body: Data(#"{"error":"Only verified filmers and pros can set up payouts."}"#.utf8)
        )
        let flow = PayoutSetupFlow(api: api)

        await flow.openStripe()

        XCTAssertNil(flow.stripePage)
        XCTAssertEqual(flow.errorMessage, "Only verified filmers and pros can set up payouts.")
    }

    func testComingBackFromStripeRereadsTheAccount() async {
        let api = FakePayoutSetupAPI(account: nil)
        api.link = ConnectOnboardingLink(url: stripeURL)
        let flow = PayoutSetupFlow(api: api)
        await flow.load(userID: userID)
        await flow.openStripe()

        // The webhook updated the row while the filmer was on Stripe's pages.
        api.account = account(submitted: true, payouts: false)
        await flow.stripeClosed(userID: userID)

        XCTAssertNil(flow.stripePage)
        XCTAssertEqual(flow.summary.bankSubtitle, "In review with Stripe")
    }

    // MARK: - Fixtures

    private func account(submitted: Bool, payouts: Bool, last4: String? = nil) -> PayoutAccount {
        PayoutAccount(bankLast4: last4, payoutsEnabled: payouts, detailsSubmitted: submitted)
    }
}

@MainActor
final class FakePayoutSetupAPI: PayoutSetupAPI {
    var account: PayoutAccount?
    var link = ConnectOnboardingLink(url: URL(string: "https://connect.stripe.com/x")!)
    var linkError: Error?

    init(account: PayoutAccount?) {
        self.account = account
    }

    func payoutAccount(for userID: UUID) async throws -> PayoutAccount? {
        account
    }

    func onboardingLink() async throws -> ConnectOnboardingLink {
        if let linkError { throw linkError }
        return link
    }
}
