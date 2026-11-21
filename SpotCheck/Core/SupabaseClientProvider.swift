import Foundation
import Supabase

/// One SupabaseClient per process, shared across every repository/service.
enum SupabaseClientProvider {
    static let shared: SupabaseClient = SupabaseClient(
        supabaseURL: AppEnvironment.supabaseURL,
        supabaseKey: AppEnvironment.supabaseAnonKey,
        options: SupabaseClientOptions(
            db: .init(
                encoder: SupabaseDecoders.encoder,
                decoder: SupabaseDecoders.decoder
            ),
            auth: .init(
                redirectToURL: URL(string: "spotcheck://auth-callback")
            )
        )
    )
}
