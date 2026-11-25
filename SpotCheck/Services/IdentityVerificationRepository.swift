import Foundation
import Supabase

/// What IDVerifyScreen needs from the backend. A protocol so the flow can be
/// tested against a fake (IdentityVerificationTests).
protocol IdentityVerificationAPI: Sendable {
    /// The user's stored verification, or nil if they never started one.
    func verification(for userID: UUID) async throws -> IdentityVerification?
    /// Starts or resumes a Stripe Identity session for whoever is signed in.
    func startSession() async throws -> IdentitySessionStart
}

/// The row is read through RLS ("users read their own identity
/// verification"); a session is started by the `identity-session` Edge
/// Function, which holds the Stripe secret key. Nothing here writes a
/// status -- only the webhook does, so the app can't report its own success.
struct IdentityVerificationRepository: IdentityVerificationAPI {
    var client: SupabaseClient = SupabaseClientProvider.shared

    func verification(for userID: UUID) async throws -> IdentityVerification? {
        let rows: [IdentityVerification] = try await client
            .from("identity_verifications")
            .select(IdentityVerification.columns)
            .eq("user_id", value: userID)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func startSession() async throws -> IdentitySessionStart {
        try await client.functions.call("identity-session", decode: IdentitySessionStart.decode)
    }
}
