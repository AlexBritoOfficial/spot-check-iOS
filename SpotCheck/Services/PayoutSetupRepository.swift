import Foundation
import Supabase

/// What PayoutsScreen needs from the backend. A protocol so the flow can be
/// tested against a fake (PayoutSetupTests).
protocol PayoutSetupAPI: Sendable {
    /// The earner's payout account, or nil before they first open Stripe.
    func payoutAccount(for userID: UUID) async throws -> PayoutAccount?
    /// A fresh link into Stripe's hosted Connect onboarding.
    func onboardingLink() async throws -> ConnectOnboardingLink
}

/// The row is read through RLS ("users read their own payout account"). The
/// link comes from `connect-onboarding`, which also creates the Connect
/// account on first use and refuses anyone who isn't a filmer or a pro. The
/// app never sees a bank number: Stripe's pages collect it.
struct PayoutSetupRepository: PayoutSetupAPI {
    var client: SupabaseClient = SupabaseClientProvider.shared

    func payoutAccount(for userID: UUID) async throws -> PayoutAccount? {
        let rows: [PayoutAccount] = try await client
            .from("payout_accounts")
            .select(PayoutAccount.columns)
            .eq("user_id", value: userID)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func onboardingLink() async throws -> ConnectOnboardingLink {
        try await client.functions.call("connect-onboarding", decode: ConnectOnboardingLink.decode)
    }
}
