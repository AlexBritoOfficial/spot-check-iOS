import Foundation

/// Mirrors `public.review_status`. Raw values match the Postgres labels.
enum ReviewStatus: String, Codable, Sendable {
    case pending
    case inReview = "in_review"
    case passed
    case failed
}

/// The signed-in user's own row in `public.filmer_profiles`: what they
/// submitted, and what Spot Check has decided about it so far.
///
/// The row only exists once `submit_filmer_application` has run, so a nil
/// application means "never applied". Review statuses, consent and the pause
/// are written only by the server; the app reads them.
struct FilmerApplication: Codable, Equatable, Sendable {
    let gear: [String]
    let styles: [String]
    let reelPath: String?
    let rawClipPath: String?
    let hourlyRateCents: Int?
    let parkDropInCents: Int?
    let consentSignedAt: Date?
    let gearReviewStatus: ReviewStatus
    let backgroundCheckStatus: ReviewStatus
    let wentLiveAt: Date?
    let pausedAt: Date?

    enum CodingKeys: String, CodingKey {
        case gear
        case styles
        case reelPath = "reel_path"
        case rawClipPath = "raw_clip_path"
        case hourlyRateCents = "hourly_rate_cents"
        case parkDropInCents = "park_drop_in_cents"
        case consentSignedAt = "consent_signed_at"
        case gearReviewStatus = "gear_review_status"
        case backgroundCheckStatus = "background_check_status"
        case wentLiveAt = "went_live_at"
        case pausedAt = "paused_at"
    }

    static let columns = """
        gear,styles,reel_path,raw_clip_path,hourly_rate_cents,park_drop_in_cents,\
        consent_signed_at,gear_review_status,background_check_status,went_live_at,paused_at
        """
}

/// The body `submit-filmer-application` reads (`application.ts`).
struct SubmitFilmerApplicationRequest: Encodable, Equatable, Sendable {
    let gear: [String]
    let styles: [String]
    let reelPath: String?
    let rawClipPath: String
    /// Must be literally `true`; the function records it as a signed consent.
    let consent: Bool

    enum CodingKeys: String, CodingKey {
        case gear
        case styles
        case reelPath = "reel_path"
        case rawClipPath = "raw_clip_path"
        case consent
    }

    // Explicit so a nil reel is sent as `null` rather than left out: the
    // function treats both the same today, but the SQL it calls takes the
    // parameter positionally and has no default.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gear, forKey: .gear)
        try container.encode(styles, forKey: .styles)
        try container.encode(reelPath, forKey: .reelPath)
        try container.encode(rawClipPath, forKey: .rawClipPath)
        try container.encode(consent, forKey: .consent)
    }
}

extension FilmerRates {
    /// What "Go live" saves before calling `filmer_go_live()`, which refuses
    /// anyone without an hourly rate. Rates are on hold (Alex, 2026-11-25:
    /// "let's circle back"), so it's the seeded filmer's rates until
    /// FilmerRatesScreen's fields and the backend agree on a format.
    static let sample = FilmerRates(hourlyRateCents: 6000, parkDropInCents: 4000)
}
