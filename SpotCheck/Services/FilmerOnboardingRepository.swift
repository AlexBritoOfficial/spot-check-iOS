import Foundation
import Supabase

/// Reads go through RLS (`filmer_profiles` is readable by any signed-in user;
/// this only ever asks for the caller's own row). Writes are limited to what
/// the client is granted: the application goes through the
/// `submit-filmer-application` Edge Function, rates are a column update the
/// filmer owns, and going live is the `filmer_go_live()` RPC, which checks the
/// reviews itself. Nothing here can pass a review.
struct FilmerOnboardingRepository: FilmerOnboardingAPI {
    var client: SupabaseClient = SupabaseClientProvider.shared

    func verification(for userID: UUID) async throws -> IdentityVerification? {
        try await IdentityVerificationRepository(client: client).verification(for: userID)
    }

    func application(for userID: UUID) async throws -> FilmerApplication? {
        let rows: [FilmerApplication] = try await client
            .from("filmer_profiles")
            .select(FilmerApplication.columns)
            .eq("user_id", value: userID)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func filmerStatus(for userID: UUID) async throws -> CapabilityStatus? {
        try await CapabilitiesRepository(client: client)
            .capabilities(for: userID)
            .first { $0.capability == .filmer }?
            .status
    }

    func submit(_ request: SubmitFilmerApplicationRequest) async throws {
        try await client.functions.call("submit-filmer-application", body: request) { _ in }
    }

    func saveRates(_ rates: FilmerRates, for userID: UUID) async throws {
        try await client
            .from("filmer_profiles")
            .update(rates)
            .eq("user_id", value: userID)
            .execute()
    }

    func goLive() async throws {
        try await client.rpc("filmer_go_live").execute()
    }
}
