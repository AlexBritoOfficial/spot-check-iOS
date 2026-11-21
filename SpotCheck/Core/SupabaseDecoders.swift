import Foundation
import Supabase

/// Single source of truth for JSON coding so `select`/`rpc` results and
/// Realtime `postgresChange` payloads decode dates/keys identically.
/// Supabase's own `.supabase()` factories already handle its date/key
/// conventions correctly -- this just makes the "same instance
/// everywhere" intent explicit rather than relying on each call site's
/// own default.
enum SupabaseDecoders {
    static let decoder: JSONDecoder = PostgrestClient.Configuration.jsonDecoder
    static let encoder: JSONEncoder = PostgrestClient.Configuration.jsonEncoder
}
