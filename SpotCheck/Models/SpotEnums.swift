import Foundation

/// Raw values match the Postgres enum labels in
/// supabase/migrations/20261118155801_extensions_and_enums.sql exactly.
enum SpotType: String, Codable, CaseIterable {
    case park, street, diy
}

enum Feature: String, Codable, CaseIterable {
    case ledge, rail, plaza, stairs, skatepark
}

enum Difficulty: String, Codable, CaseIterable {
    case beginner, intermediate, advanced, pro
}

enum SpotStatus: String, Codable, CaseIterable {
    case active, pending, closed
}
