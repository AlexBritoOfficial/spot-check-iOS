import XCTest
@testable import SpotCheck

/// A single test binary only ever sees the config it was built under, so
/// "two configs share a host" can't be checked by comparing all four
/// live values against each other in one run — only per-config, via the
/// LOCAL_ENV compilation condition (set on Debug only, see project.yml).
final class AppEnvironmentTests: XCTestCase {
    func testSupabaseHostMatchesExpectedEnvironment() {
        // Merely resolving this without AppEnvironment's own fatalError
        // firing already proves the value is well-formed and non-empty.
        let host = AppEnvironment.supabaseURL.host ?? ""

        #if LOCAL_ENV
        XCTAssertTrue(
            host.hasPrefix("127.0.0.1"),
            "Debug must resolve to the local `supabase start` stack, got \"\(host)\""
        )
        #else
        XCTAssertFalse(
            host.hasPrefix("127.0.0.1"),
            "Every non-Debug config must not resolve to the local stack, got \"\(host)\""
        )
        #endif
    }
}
