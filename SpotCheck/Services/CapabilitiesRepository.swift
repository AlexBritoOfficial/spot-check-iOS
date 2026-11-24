import Foundation
import Supabase

/// Read-only. Capabilities are never granted from the client -- the database
/// has no insert/update policy on `profile_capabilities` at all, and every
/// grant path is a security-definer function (`redeem_organization_invite`,
/// `filmer_go_live`) or the service role. A write attempt here wouldn't fail
/// loudly, it would silently affect zero rows, so there is deliberately no
/// write method to reach for.
struct CapabilitiesRepository {
    var client: SupabaseClient = SupabaseClientProvider.shared

    func capabilities(for userID: UUID) async throws -> [ProfileCapability] {
        try await client
            .from("profile_capabilities")
            .select(ProfileCapability.columns)
            .eq("user_id", value: userID)
            .execute()
            .value
    }
}
