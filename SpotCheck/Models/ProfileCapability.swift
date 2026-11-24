import Foundation

/// Mirrors public.profile_capabilities.
///
/// There is no row for a capability someone doesn't have -- absence is the
/// "none" state, which is why the enum has no such case.
struct ProfileCapability: Codable, Identifiable, Equatable, Sendable {
    let userID: UUID
    let capability: Capability
    let status: CapabilityStatus
    let grantedAt: Date?
    let revokedAt: Date?

    /// Composite key in Postgres; derived here so SwiftUI lists can identify it.
    var id: String { "\(userID.uuidString)-\(capability.rawValue)" }

    var isActive: Bool { status == .active }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case capability
        case status
        case grantedAt = "granted_at"
        case revokedAt = "revoked_at"
    }

    static let columns = "user_id,capability,status,granted_at,revoked_at"
}
