import Foundation
import Observation

/// PayoutsScreen's payout account: what the rows say, and the round trip to
/// Stripe's hosted onboarding.
///
/// Stripe's return URL is not relied on to come back into the app -- the
/// filmer closes Stripe's page themselves, and the account is re-read then.
/// The webhook may not have landed by that moment, so "Unfinished" can
/// briefly show for a filmer who just finished; reopening Payouts catches up.
@MainActor
@Observable
final class PayoutSetupFlow {
    /// Stripe's hosted page, while it is open.
    struct StripePage: Identifiable, Equatable {
        let url: URL
        var id: URL { url }
    }

    private(set) var summary = PayoutAccountSummary(account: nil)
    private(set) var isLoading = false
    private(set) var isOpeningStripe = false
    var stripePage: StripePage?
    private(set) var errorMessage: String?

    private let api: PayoutSetupAPI

    init(api: PayoutSetupAPI = PayoutSetupRepository()) {
        self.api = api
    }

    func load(userID: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            summary = PayoutAccountSummary(account: try await api.payoutAccount(for: userID))
            errorMessage = nil
        } catch {
            errorMessage = error.edgeFunctionUserMessage
        }
    }

    func openStripe() async {
        // Each call mints a new single-use link; a double tap shouldn't.
        guard !isOpeningStripe else { return }
        isOpeningStripe = true
        defer { isOpeningStripe = false }
        do {
            stripePage = StripePage(url: try await api.onboardingLink().url)
            errorMessage = nil
        } catch {
            errorMessage = error.edgeFunctionUserMessage
        }
    }

    func stripeClosed(userID: UUID) async {
        stripePage = nil
        await load(userID: userID)
    }
}
