import Foundation

/// Raw values match the Postgres enum labels in
/// supabase/migrations/20261124120000_capabilities_and_identity.sql exactly,
/// the same convention `SpotEnums` follows.
///
/// A Spot Check account is always a skater. These are *additive* grants layered
/// on top of that, not alternatives to it -- which is why there's no `.skater`
/// case: everyone is one, so it would never be worth storing.
///
/// `proSkater`, never `pro`: `Difficulty.pro` already means spot difficulty and
/// the two are unrelated.
enum Capability: String, Codable, CaseIterable, Sendable {
    case filmer
    case industry
    case proSkater = "pro_skater"
}

/// Mirrors `public.capability_status`.
///
/// Only `.active` unlocks anything. `.paused` in particular must not --
/// `FilmerTools/StrikePausedScreen` spells out what a paused filmer loses:
/// "Skaters can't find or request you".
enum CapabilityStatus: String, Codable, Sendable {
    case applied
    case inReview = "in_review"
    case active
    case paused
    case revoked
}
