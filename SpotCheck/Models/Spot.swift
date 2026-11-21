import CoreLocation
import Foundation

/// Mirrors public.spots. Never select("*") on the real table -- that
/// pulls the raw EWKB-encoded lat_lng geography blob. Use `Spot.columns`
/// for a plain select, or the spots_nearby RPC for distance-sorted reads
/// (which also populates distanceMeters).
struct Spot: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let ownerID: UUID?
    var name: String
    var city: String
    var spotType: SpotType
    var description: String?
    var features: [Feature]
    var difficulty: Difficulty
    var isSkateable: Bool
    var isPublic: Bool
    var rating: Int
    var lat: Double
    var lng: Double
    /// Object path inside the `spot-photos` bucket, not a URL -- resolve
    /// via SpotPhotoStorage's signed-URL lookup before rendering.
    var photo: String?
    var status: SpotStatus
    let createdAt: Date
    /// Only populated when decoded from the spots_nearby RPC response.
    var distanceMeters: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case city
        case spotType = "spot_type"
        case description
        case features
        case difficulty
        case isSkateable = "is_skateable"
        case isPublic = "is_public"
        case rating
        case lat
        case lng
        case photo
        case status
        case createdAt = "created_at"
        case distanceMeters = "distance_meters"
    }

    /// Every column spots_nearby returns, in the same order -- share this
    /// across every `.from("spots").select(...)` call site instead of "*".
    static let columns =
        "id,owner_id,name,city,spot_type,description,features,difficulty,is_skateable,is_public,rating,lat,lng,photo,status,created_at"

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    func isOwned(by userID: UUID?) -> Bool {
        ownerID != nil && ownerID == userID
    }
}

/// Params for the `spots_nearby` RPC (supabase/migrations/20261118155806_rpc_spots_nearby.sql).
struct SpotsNearbyParams: Encodable, Sendable {
    let lat: Double
    let lng: Double
    let radiusMeters: Double
    let limit: Int

    enum CodingKeys: String, CodingKey {
        case lat = "p_lat"
        case lng = "p_lng"
        case radiusMeters = "p_radius_meters"
        case limit = "p_limit"
    }
}

/// Insert payload for AddSpot. `id` is generated client-side (not left to
/// the DB default) so a photo can be uploaded to spot-photos/{owner}/{id}/
/// *before* the row exists -- the storage insert policy only checks the
/// owner-id path prefix, so this ordering avoids a chicken-and-egg wait.
struct NewSpot: Encodable, Sendable {
    let id: UUID
    let ownerID: UUID
    var name: String
    var city: String
    var spotType: SpotType
    var description: String?
    var features: [Feature]
    var difficulty: Difficulty
    var isSkateable: Bool
    var isPublic: Bool
    var lat: Double
    var lng: Double
    var photo: String?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case city
        case spotType = "spot_type"
        case description
        case features
        case difficulty
        case isSkateable = "is_skateable"
        case isPublic = "is_public"
        case lat
        case lng
        case photo
    }
}

/// PATCH payload for editing a spot. Only columns the RLS column-grant
/// actually allows authenticated users to update (see
/// supabase/migrations/20261118155807_rls.sql) -- rating/status are
/// display-only and intentionally absent here.
struct SpotUpdate: Encodable, Sendable {
    var name: String
    var city: String
    var spotType: SpotType
    var description: String?
    var features: [Feature]
    var difficulty: Difficulty
    var isSkateable: Bool
    var isPublic: Bool
    var lat: Double
    var lng: Double
    var photo: String?

    enum CodingKeys: String, CodingKey {
        case name
        case city
        case spotType = "spot_type"
        case description
        case features
        case difficulty
        case isSkateable = "is_skateable"
        case isPublic = "is_public"
        case lat
        case lng
        case photo
    }
}
