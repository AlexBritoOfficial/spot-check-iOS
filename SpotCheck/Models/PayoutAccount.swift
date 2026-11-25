import Foundation

/// The signed-in earner's row in public.payout_accounts. Stripe's state,
/// mirrored by the webhook on `account.updated` -- never set by the app.
///
/// `tax_details_complete` is deliberately not read: the webhook leaves it
/// alone, because Stripe reports tax collection as a list of outstanding
/// fields rather than a flag. `details_submitted` stands in for it, since
/// Express onboarding collects tax details before it can be submitted.
struct PayoutAccount: Codable, Equatable, Sendable {
    let bankLast4: String?
    /// Stripe will pay money out to this account. `release-payment` refuses
    /// to deliver until it is true.
    let payoutsEnabled: Bool
    /// The filmer finished Stripe's hosted onboarding at least once.
    let detailsSubmitted: Bool

    enum CodingKeys: String, CodingKey {
        case bankLast4 = "bank_last4"
        case payoutsEnabled = "payouts_enabled"
        case detailsSubmitted = "details_submitted"
    }

    static let columns = "bank_last4,payouts_enabled,details_submitted"
}

/// What `connect-onboarding` answered: a single-use, minutes-long link to
/// Stripe's hosted Express onboarding. Fetched fresh on every tap.
struct ConnectOnboardingLink: Equatable, Sendable {
    let url: URL

    static func decode(_ data: Data) throws -> ConnectOnboardingLink {
        ConnectOnboardingLink(url: try JSONDecoder().decode(Body.self, from: data).url)
    }

    private struct Body: Decodable {
        let url: URL
    }
}

/// PayoutsScreen's "PAYOUT ACCOUNT" rows for a given account. The artboard
/// draws only the finished case ("Verified · managed with Stripe"); the
/// other three are the states a real filmer passes through to get there.
struct PayoutAccountSummary: Equatable {
    let bankTitle: String
    let bankSubtitle: String
    let actionTitle: String
    let taxSubtitle: String
    let isTaxComplete: Bool

    init(account: PayoutAccount?) {
        if let last4 = account?.bankLast4 {
            bankTitle = "Bank account •••• \(last4)"
        } else {
            bankTitle = "Bank account"
        }

        switch account {
        case nil:
            bankSubtitle = "Not set up · managed with Stripe"
            actionTitle = "Set up"
        case let account? where !account.detailsSubmitted:
            bankSubtitle = "Unfinished · finish with Stripe"
            actionTitle = "Finish"
        case let account? where !account.payoutsEnabled:
            bankSubtitle = "In review with Stripe"
            actionTitle = "Update"
        default:
            bankSubtitle = "Verified · managed with Stripe"
            actionTitle = "Update"
        }

        isTaxComplete = account?.detailsSubmitted == true
        taxSubtitle = isTaxComplete
            ? "Complete · collected by Stripe for payouts"
            : "Collected by Stripe during payout setup"
    }
}
