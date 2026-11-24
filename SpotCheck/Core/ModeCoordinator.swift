import Observation
import SwiftUI

/// Which side of the app someone is currently looking at.
///
/// A mode is not an account type. Everyone is a skater, and `.skater` is always
/// available; the other two are views you can switch into once the matching
/// capability is active. `Features/Filming/DiscoverScreen` is the clearest
/// example of why this is a mode rather than a role -- the canvas draws the
/// filmer's own tab bar with DISCOVER where FEED normally sits.
enum AppMode: String, CaseIterable, Sendable {
    case skater
    case filmer
    case industry

    /// `nil` for `.skater`: it needs no grant.
    var requiredCapability: Capability? {
        switch self {
        case .skater: nil
        case .filmer: .filmer
        case .industry: .industry
        }
    }

    var label: String {
        switch self {
        case .skater: "Skater"
        case .filmer: "Filmer"
        case .industry: "Industry"
        }
    }

    var systemImage: String {
        switch self {
        case .skater: "figure.skating"
        case .filmer: "video"
        case .industry: "briefcase"
        }
    }
}

/// Owns the active mode and, crucially, decides which modes exist at all.
///
/// The switcher is not shown to someone with nothing to switch to, so a plain
/// skater never sees it. Selection is validated here rather than at the call
/// site: a capability can be revoked or paused while the app is running, and
/// `UserDefaults` can hold a mode from a previous session that is no longer
/// granted, so both paths funnel through `available(given:)`.
@MainActor
@Observable
final class ModeCoordinator {
    private static let storageKey = "activeAppMode"

    private let defaults: UserDefaults

    /// Always starts at `.skater`, whatever was stored. A persisted mode is a
    /// claim about a capability the app hasn't loaded yet, so it is held aside
    /// until `reconcile(with:)` can check it -- otherwise there is a window
    /// where a revoked filmer comes back in filmer mode.
    private(set) var activeMode: AppMode = .skater
    private var restoredMode: AppMode?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.storageKey) {
            restoredMode = AppMode(rawValue: raw)
        }
    }

    /// Modes this person can actually be in, in a stable order.
    func available(given capabilities: Set<Capability>) -> [AppMode] {
        AppMode.allCases.filter { mode in
            guard let required = mode.requiredCapability else { return true }
            return capabilities.contains(required)
        }
    }

    /// Only worth showing when there is somewhere else to go.
    func isSwitcherVisible(given capabilities: Set<Capability>) -> Bool {
        available(given: capabilities).count > 1
    }

    func select(_ mode: AppMode, given capabilities: Set<Capability>) {
        guard available(given: capabilities).contains(mode) else { return }
        activeMode = mode
        defaults.set(mode.rawValue, forKey: Self.storageKey)
    }

    /// Settles the mode against the capabilities actually held: promotes a
    /// mode restored from a previous session if it still holds, and drops back
    /// to `.skater` when the active one no longer does -- a filmer paused at
    /// three strikes, say. Always safe to call, and called with `initial: true`
    /// so it runs before anything reads `activeMode`.
    func reconcile(with capabilities: Set<Capability>) {
        let allowed = available(given: capabilities)

        if let restoredMode {
            self.restoredMode = nil
            if allowed.contains(restoredMode) {
                activeMode = restoredMode
                return
            }
        }

        guard !allowed.contains(activeMode) else { return }
        activeMode = .skater
        defaults.set(AppMode.skater.rawValue, forKey: Self.storageKey)
    }
}
