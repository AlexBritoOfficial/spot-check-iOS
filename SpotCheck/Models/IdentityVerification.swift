import Foundation

/// Mirrors the Postgres enum `identity_status`, which is Stripe's own
/// VerificationSession status. Raw values match the labels exactly.
enum IdentityStatus: String, Codable, Sendable {
    case requiresInput = "requires_input"
    case processing
    case verified
    case canceled
}

/// The signed-in user's own row in public.identity_verifications -- the only
/// row RLS lets them read. Written only by the Stripe webhook.
///
/// Stripe's date of birth is never stored: only whether it made the user an
/// adult, which is all IDVerifyScreen promises Spot Check keeps.
struct IdentityVerification: Codable, Equatable, Sendable {
    let status: IdentityStatus
    /// Stripe's `last_error.code`, e.g. `document_expired`.
    let lastErrorCode: String?
    let verifiedIsAdult: Bool?

    /// What the backend's money-movement gate checks (`payment-intent`):
    /// verified *and* an adult. Verified-but-under-18 still can't book.
    var isVerifiedAdult: Bool { status == .verified && verifiedIsAdult == true }

    enum CodingKeys: String, CodingKey {
        case status
        case lastErrorCode = "last_error_code"
        case verifiedIsAdult = "verified_is_adult"
    }

    static let columns = "status,last_error_code,verified_is_adult"
}

/// What `identity-session` answered. It only hands out a client secret when
/// there is something for the user to do; otherwise it says why not.
enum IdentitySessionStart: Equatable, Sendable {
    /// Nothing to do: the user verified before.
    case alreadyVerified
    /// The user already submitted and Stripe is still checking.
    case alreadySubmitted
    /// Present Stripe's sheet with this VerificationSession client secret.
    case verify(clientSecret: String)

    struct MissingClientSecret: Error {}

    static func decode(_ data: Data) throws -> IdentitySessionStart {
        let body = try JSONDecoder().decode(Body.self, from: data)
        switch body.status {
        case .verified: return .alreadyVerified
        case .processing: return .alreadySubmitted
        case .requiresInput, .canceled:
            guard let secret = body.clientSecret, !secret.isEmpty else { throw MissingClientSecret() }
            return .verify(clientSecret: secret)
        }
    }

    private struct Body: Decodable {
        let status: IdentityStatus
        let clientSecret: String?

        enum CodingKeys: String, CodingKey {
            case status
            case clientSecret = "client_secret"
        }
    }
}
