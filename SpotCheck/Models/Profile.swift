import Foundation

/// Mirrors public.profiles.
struct Profile: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var username: String
    var homeCity: String
    var firstName: String?
    var lastName: String?
    var stance: String?
    var discipline: String?
    /// Storage path in `avatars`, or an external (e.g. Google) picture URL.
    var avatarURL: String?
    var age: Int?
    var yearsSkating: Int?
    var filmer: Bool
    let createdAt: Date
    var updatedAt: Date

    /// Always derived, never stored -- matches the web app's convention.
    var handle: String { "@\(username)" }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case homeCity = "home_city"
        case firstName = "first_name"
        case lastName = "last_name"
        case stance
        case discipline
        case avatarURL = "avatar_url"
        case age
        case yearsSkating = "years_skating"
        case filmer
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static let columns =
        "id,username,home_city,first_name,last_name,stance,discipline,avatar_url,age,years_skating,filmer,created_at,updated_at"
}
