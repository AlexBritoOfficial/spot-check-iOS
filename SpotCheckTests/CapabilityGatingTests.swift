import XCTest
@testable import SpotCheck

/// The gating rules, which decide what a given account can see. These are the
/// rules the drawer and tab bar read, so getting one wrong silently exposes a
/// surface to someone who hasn't earned it -- worth asserting rather than
/// eyeballing in the simulator.
final class CapabilityGatingTests: XCTestCase {

    /// Each coordinator gets its own defaults suite. Sharing
    /// `UserDefaults.standard` let one test's persisted mode leak into the
    /// next, which is what first surfaced the restore bug covered below.
    @MainActor
    private func makeCoordinator(storedMode: AppMode? = nil) -> ModeCoordinator {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        if let storedMode {
            suite.set(storedMode.rawValue, forKey: "activeAppMode")
        }
        return ModeCoordinator(defaults: suite)
    }

    // MARK: - Raw values must match the Postgres enum labels

    /// A mismatch here doesn't fail loudly: the decode throws, the repository
    /// returns nothing, and the user silently loses a capability they have.
    func testCapabilityRawValuesMatchPostgresLabels() {
        XCTAssertEqual(Capability.filmer.rawValue, "filmer")
        XCTAssertEqual(Capability.industry.rawValue, "industry")
        XCTAssertEqual(Capability.proSkater.rawValue, "pro_skater")
    }

    func testCapabilityStatusRawValuesMatchPostgresLabels() {
        XCTAssertEqual(CapabilityStatus.applied.rawValue, "applied")
        XCTAssertEqual(CapabilityStatus.inReview.rawValue, "in_review")
        XCTAssertEqual(CapabilityStatus.active.rawValue, "active")
        XCTAssertEqual(CapabilityStatus.paused.rawValue, "paused")
        XCTAssertEqual(CapabilityStatus.revoked.rawValue, "revoked")
    }

    /// Decodes the exact snake_case shape PostgREST returns for the seeded
    /// pro account, which is where a raw-value slip would actually bite.
    func testProfileCapabilityDecodesServerShape() throws {
        let json = """
        {
          "user_id": "55555555-5555-4555-8555-555555555555",
          "capability": "pro_skater",
          "status": "active",
          "granted_at": null,
          "revoked_at": null
        }
        """.data(using: .utf8)!

        let row = try JSONDecoder().decode(ProfileCapability.self, from: json)

        XCTAssertEqual(row.capability, .proSkater)
        XCTAssertEqual(row.status, .active)
        XCTAssertTrue(row.isActive)
    }

    func testPausedCapabilityIsNotActive() throws {
        let json = """
        {
          "user_id": "33333333-3333-4333-8333-333333333333",
          "capability": "filmer",
          "status": "paused",
          "granted_at": null,
          "revoked_at": null
        }
        """.data(using: .utf8)!

        let row = try JSONDecoder().decode(ProfileCapability.self, from: json)

        // The paused filmer fixture. StrikePausedScreen: "Skaters can't find
        // or request you" -- so paused must not unlock filmer surfaces.
        XCTAssertFalse(row.isActive)
    }

    // MARK: - Available modes

    @MainActor
    func testPlainSkaterHasOnlySkaterModeAndNoSwitcher() {
        let coordinator = makeCoordinator()

        XCTAssertEqual(coordinator.available(given: []), [.skater])
        XCTAssertFalse(
            coordinator.isSwitcherVisible(given: []),
            "With one mode there is nothing to switch to, so the control must not render"
        )
    }

    @MainActor
    func testFilmerGetsSkaterAndFilmerModes() {
        let coordinator = makeCoordinator()
        let capabilities: Set<Capability> = [.filmer]

        XCTAssertEqual(coordinator.available(given: capabilities), [.skater, .filmer])
        XCTAssertTrue(coordinator.isSwitcherVisible(given: capabilities))
    }

    @MainActor
    func testProSkaterGetsNoExtraModeOfItsOwn() {
        let coordinator = makeCoordinator()
        let capabilities: Set<Capability> = [.proSkater]

        // Pro surfaces hang off the drawer, not a mode: the canvas gives a pro
        // no tab bar of their own.
        XCTAssertEqual(coordinator.available(given: capabilities), [.skater])
        XCTAssertFalse(coordinator.isSwitcherVisible(given: capabilities))
    }

    // MARK: - Selection is validated, not trusted

    @MainActor
    func testSelectingAnUngrantedModeIsRejected() {
        let coordinator = makeCoordinator()

        coordinator.select(.filmer, given: [])

        XCTAssertEqual(
            coordinator.activeMode, .skater,
            "A mode without its capability must not become active"
        )
    }

    @MainActor
    func testSelectingAGrantedModeSucceeds() {
        let coordinator = makeCoordinator()

        coordinator.select(.industry, given: [.industry])

        XCTAssertEqual(coordinator.activeMode, .industry)
    }

    @MainActor
    func testReconcileDemotesWhenCapabilityIsLost() {
        let coordinator = makeCoordinator()
        coordinator.select(.filmer, given: [.filmer])
        XCTAssertEqual(coordinator.activeMode, .filmer)

        // Three strikes land while the app is open, so filmer drops to paused
        // and is no longer in the active set.
        coordinator.reconcile(with: [])

        XCTAssertEqual(coordinator.activeMode, .skater)
    }

    /// The bug the suite caught: a mode persisted from a previous session was
    /// active before any capability had been loaded, so a filmer whose
    /// capability had since been paused came back in filmer mode.
    @MainActor
    func testRestoredModeIsNotActiveUntilReconciled() {
        let coordinator = makeCoordinator(storedMode: .filmer)

        XCTAssertEqual(
            coordinator.activeMode, .skater,
            "A stored mode is a claim about a capability not yet loaded"
        )

        coordinator.reconcile(with: [])

        XCTAssertEqual(coordinator.activeMode, .skater)
    }

    @MainActor
    func testRestoredModeIsPromotedWhenStillGranted() {
        let coordinator = makeCoordinator(storedMode: .filmer)

        coordinator.reconcile(with: [.filmer])

        XCTAssertEqual(
            coordinator.activeMode, .filmer,
            "Someone who was in filmer mode last session should land back in it"
        )
    }

    @MainActor
    func testReconcileLeavesAStillValidModeAlone() {
        let coordinator = makeCoordinator()
        coordinator.select(.filmer, given: [.filmer])

        coordinator.reconcile(with: [.filmer, .industry])

        XCTAssertEqual(coordinator.activeMode, .filmer)
    }

    // MARK: - Tab bar

    func testSkaterAndIndustryShareTheDefaultTabBar() {
        XCTAssertEqual(MainTab.tabs(for: .skater), [.map, .feed, .chat, .profile])
        XCTAssertEqual(MainTab.tabs(for: .industry), [.map, .feed, .chat, .profile])
    }

    /// DiscoverScreen's own comment: "the canvas draws a filmer-mode bar with
    /// DISCOVER replacing FEED".
    func testFilmerModeSwapsFeedForDiscover() {
        let tabs = MainTab.tabs(for: .filmer)

        XCTAssertEqual(tabs, [.map, .discover, .chat, .profile])
        XCTAssertFalse(tabs.contains(.feed))
    }

    func testEveryModeHasExactlyFourTabs() {
        // The bar renders two, the raised post action, then two. Any other
        // count silently drops a destination.
        for mode in AppMode.allCases {
            XCTAssertEqual(
                MainTab.tabs(for: mode).count, 4,
                "\(mode.label) must have four tabs"
            )
        }
    }
}
