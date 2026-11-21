import Foundation

/// Reads Supabase project config from Info.plist, which in turn pulls the
/// real values from Config/Secrets.xcconfig via Xcode's $(VAR) substitution.
/// Never hardcode a URL/key here — see Config/Secrets.example.xcconfig.
enum AppEnvironment {
    static let supabaseURL: URL = {
        guard
            let scheme = infoString("SUPABASE_SCHEME"),
            let host = infoString("SUPABASE_HOST"),
            !host.isEmpty, !host.hasPrefix("$("),
            let url = URL(string: "\(scheme)://\(host)")
        else {
            fatalError(
                "Missing/invalid SUPABASE_SCHEME or SUPABASE_HOST in Info.plist. "
                    + "Copy Config/Secrets.example.xcconfig to Config/Secrets.xcconfig and fill it in."
            )
        }
        return url
    }()

    static let supabaseAnonKey: String = {
        guard
            let key = infoString("SUPABASE_ANON_KEY"),
            !key.isEmpty, !key.hasPrefix("$(")
        else {
            fatalError(
                "Missing SUPABASE_ANON_KEY in Info.plist. "
                    + "Copy Config/Secrets.example.xcconfig to Config/Secrets.xcconfig and fill it in."
            )
        }
        return key
    }()

    /// `$(VAR)` left unsubstituted shows up literally as "$(VAR)" when the
    /// build setting is missing entirely, not as an empty string — checked
    /// for above so that failure mode fails loudly instead of silently.
    private static func infoString(_ key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
