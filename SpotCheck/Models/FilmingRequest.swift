import Foundation

/// Mirrors public.filming_requests (spot-check-backend
/// 20261125120000_filming_requests.sql): a skater's request for a filmer, and
/// the booking a filming payment is for.
///
/// Read-only from the client. Every change goes through a security-definer
/// function (`create_filming_request`, `accept_…`, `pass_…`, `cancel_…`) that
/// checks the caller -- there is no insert/update policy to write through.
struct FilmingRequest: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let skaterID: UUID
    /// Set when the skater chose this filmer from their profile; nil means
    /// any filmer nearby can take it.
    let requestedFilmerID: UUID?
    /// Whoever accepted. Nil until then.
    let filmerID: UUID?
    let package: FilmingPackage
    let spotID: UUID?
    let lat: Double
    let lng: Double
    let locationLabel: String?
    let startsAt: Date
    let endsAt: Date
    let lighting: SessionLighting
    let securityRisk: SecurityRisk
    let notes: String?
    /// The filmer's price, copied when they accepted. Excludes Spot Check's
    /// 15%, which the skater pays on top.
    let rateCents: Int?
    let status: FilmingRequestStatus
    let acceptedAt: Date?
    let cancelledAt: Date?
    let cancelledBy: RequestParty?
    let cancellationWasLate: Bool?
    let createdAt: Date
    /// Embedded from `profiles` so Discover can say who is asking.
    let skater: PartyName?

    struct PartyName: Codable, Equatable, Sendable {
        let username: String
    }

    enum CodingKeys: String, CodingKey {
        case id
        case skaterID = "skater_id"
        case requestedFilmerID = "requested_filmer_id"
        case filmerID = "filmer_id"
        case package
        case spotID = "spot_id"
        case lat
        case lng
        case locationLabel = "location_label"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case lighting
        case securityRisk = "security_risk"
        case notes
        case rateCents = "rate_cents"
        case status
        case acceptedAt = "accepted_at"
        case cancelledAt = "cancelled_at"
        case cancelledBy = "cancelled_by"
        case cancellationWasLate = "cancellation_was_late"
        case createdAt = "created_at"
        case skater
    }

    /// Never `*`: that would pull the generated `lat_lng` geography blob. The
    /// skater embed names its foreign key column because the table has three
    /// references to `profiles`, and PostgREST can't pick one on its own.
    static let columns = """
        id,skater_id,requested_filmer_id,filmer_id,package,spot_id,lat,lng,location_label,\
        starts_at,ends_at,lighting,security_risk,notes,rate_cents,status,accepted_at,\
        cancelled_at,cancelled_by,cancellation_was_late,created_at,\
        skater:profiles!skater_id(username)
        """

    var locationTitle: String { locationLabel ?? "Dropped pin" }
}

// MARK: - Enums. Raw values match the Postgres labels exactly.

enum FilmingPackage: String, Codable, CaseIterable, Sendable {
    case hourlyStreet = "hourly_street"
    case parkDropIn = "park_drop_in"
    case fullEdit = "full_edit"

    /// FilmBooking's package names and captions.
    var title: String {
        switch self {
        case .hourlyStreet: "Hourly Street Session"
        case .parkDropIn: "Park Drop-In"
        case .fullEdit: "Full Edit Package"
        }
    }

    var detail: String {
        switch self {
        case .hourlyStreet: "Grind out one spot, billed by the hour"
        case .parkDropIn: "A 30–60 min block at a skatepark"
        case .fullEdit: "Multi-day filming plus post-production"
        }
    }
}

enum SessionLighting: String, Codable, CaseIterable, Sendable {
    case daylight
    case goldenHour = "golden_hour"
    case night

    /// FilmBooking's chip labels.
    var title: String {
        switch self {
        case .daylight: "Daylight"
        case .goldenHour: "Golden hour"
        case .night: "Night · bring lights"
        }
    }
}

enum SecurityRisk: String, Codable, CaseIterable, Sendable {
    case low
    case sometimes
    case kicksOutFast = "kicks_out_fast"

    var title: String {
        switch self {
        case .low: "Low"
        case .sometimes: "Sometimes"
        case .kicksOutFast: "Kicks out fast"
        }
    }
}

enum FilmingRequestStatus: String, Codable, Sendable {
    case requested
    case accepted
    case cancelled
}

enum RequestParty: String, Codable, Sendable {
    case skater
    case filmer
}

/// The two prices a filmer sets on FilmerRates. Read from
/// `filmer_profiles`, which every signed-in user can read.
struct FilmerRates: Codable, Equatable, Sendable {
    let hourlyRateCents: Int?
    let parkDropInCents: Int?

    enum CodingKeys: String, CodingKey {
        case hourlyRateCents = "hourly_rate_cents"
        case parkDropInCents = "park_drop_in_cents"
    }

    static let columns = "hourly_rate_cents,park_drop_in_cents"
}

/// A filmer's prices and strikes, from `filmer_profiles`. Discover's
/// "You earn" and "Your reliability" both read it.
struct FilmerStanding: Codable, Equatable, Sendable {
    let hourlyRateCents: Int?
    let parkDropInCents: Int?
    let strikeCount: Int

    var rates: FilmerRates {
        FilmerRates(hourlyRateCents: hourlyRateCents, parkDropInCents: parkDropInCents)
    }

    enum CodingKeys: String, CodingKey {
        case hourlyRateCents = "hourly_rate_cents"
        case parkDropInCents = "park_drop_in_cents"
        case strikeCount = "strike_count"
    }

    static let columns = "hourly_rate_cents,park_drop_in_cents,strike_count"
}
