import Foundation
import Observation

/// The routing decisions of "Earn with Spot Check", as pure functions.
///
/// The order is ID first (Alex, 2026-11-25), overriding the canvas, which
/// draws the ID check after the portfolio: an under-18 shouldn't upload a
/// portfolio they can never use.
///
///     ProApply → IDVerify → FilmerQualify → Verification → FilmerRates → live
enum FilmerOnboarding {
    /// Where the flow opens when the menu row is tapped.
    enum Entry: Equatable {
        /// Never applied (or revoked and free to apply again).
        case pitch
        /// Applied: the status checklist, which offers rates once cleared.
        case review
        case paused
        case live
    }

    /// Where the pitch's Continue goes.
    enum StepAfterPitch: Equatable {
        case verifyID
        case portfolio
        /// Verified, but under 18. The flow ends.
        case notAdult
    }

    static func entry(application: FilmerApplication?, filmerStatus: CapabilityStatus?) -> Entry {
        if filmerStatus == .paused || application?.pausedAt != nil { return .paused }
        if filmerStatus == .active { return .live }
        if filmerStatus == .revoked { return .pitch }
        return application == nil ? .pitch : .review
    }

    /// Only a verified adult moves on. "Stripe is still checking" waits on
    /// the ID screen (Alex: wait for the ID to be verified), which is also
    /// what `submit_filmer_application` enforces server-side.
    /// An unknown age (no readable date of birth) goes back to the ID screen,
    /// which offers another try; only a checked under-18 is `.notAdult`.
    static func stepAfterPitch(identity: IdentityVerification?) -> StepAfterPitch {
        guard let identity, identity.status == .verified else { return .verifyID }
        switch identity.verifiedIsAdult {
        case true?: return .portfolio
        case false?: return .notAdult
        case nil: return .verifyID
        }
    }
}

/// FilmerQualifyScreen's choices. The two reel rows are sample files for now
/// (Alex: "use dummy data"): there is no video picker yet, and nothing checks
/// that a portfolio path points at a real object.
struct FilmerApplicationDraft: Equatable {
    static let gearOptions = [
        "VX1000 / tapeless",
        "DSLR/mirrorless + fisheye",
        "Long lens (telephoto)",
        "External shotgun mic",
        "Filmer cruiser board"
    ]

    static let styleOptions = [
        "Street follow-lines",
        "Park / transition",
        "Night / external lighting",
        "Quick social clips"
    ]

    /// The canvas artboard's own selections.
    var gear: Set<String> = [
        "VX1000 / tapeless",
        "DSLR/mirrorless + fisheye",
        "External shotgun mic",
        "Filmer cruiser board"
    ]
    var styles: Set<String> = [
        "Street follow-lines",
        "Night / external lighting"
    ]
    var consentsToBackgroundCheck = false

    var canSubmit: Bool { consentsToBackgroundCheck }

    func request(userID: UUID) -> SubmitFilmerApplicationRequest {
        SubmitFilmerApplicationRequest(
            gear: Self.gearOptions.filter(gear.contains),
            styles: Self.styleOptions.filter(styles.contains),
            reelPath: Self.sampleClipPath(userID: userID, name: "sample-highlight-reel.mp4"),
            rawClipPath: Self.sampleClipPath(userID: userID, name: "sample-raw-follow-line.mp4"),
            consent: consentsToBackgroundCheck
        )
    }

    /// Lowercased: storage RLS compares the first folder with
    /// `auth.uid()::text`, and Swift's `uuidString` is uppercase.
    private static func sampleClipPath(userID: UUID, name: String) -> String {
        "\(userID.uuidString.lowercased())/\(name)"
    }
}

/// VerificationScreen's checklist, read from the stored rows.
struct FilmerReviewProgress: Equatable {
    let isIDVerified: Bool
    let isConsentSigned: Bool
    let gearReview: ReviewStatus
    let backgroundCheck: ReviewStatus

    init(identity: IdentityVerification?, application: FilmerApplication?) {
        isIDVerified = identity?.isVerifiedAdult == true
        isConsentSigned = application?.consentSignedAt != nil
        gearReview = application?.gearReviewStatus ?? .pending
        backgroundCheck = application?.backgroundCheckStatus ?? .pending
    }

    /// What `filmer_go_live()` requires, short of a rate.
    var isCleared: Bool { isIDVerified && gearReview == .passed && backgroundCheck == .passed }

    var hasFailure: Bool { gearReview == .failed || backgroundCheck == .failed }

    /// Nothing more will change on its own once cleared or turned down.
    var shouldKeepChecking: Bool { !isCleared && !hasFailure }
}

/// What the flow needs from the backend. A protocol so the flow can be tested
/// against a fake (FilmerOnboardingTests).
protocol FilmerOnboardingAPI: Sendable {
    func verification(for userID: UUID) async throws -> IdentityVerification?
    /// Nil until `submit_filmer_application` has created the row.
    func application(for userID: UUID) async throws -> FilmerApplication?
    /// The filmer capability's status, whatever it is; nil if there's no row.
    func filmerStatus(for userID: UUID) async throws -> CapabilityStatus?
    func submit(_ request: SubmitFilmerApplicationRequest) async throws
    func saveRates(_ rates: FilmerRates, for userID: UUID) async throws
    func goLive() async throws
}

/// The state shared by every screen of "Earn with Spot Check", so each step
/// reads the same rows rather than fetching its own.
@MainActor
@Observable
final class FilmerOnboardingFlow {
    /// How often VerificationScreen re-reads while a review is pending. On QA
    /// the mock check passes about a minute after submitting.
    static let reviewCheckInterval: Duration = .seconds(10)

    private(set) var isLoading = true
    private(set) var identity: IdentityVerification?
    private(set) var application: FilmerApplication?
    private(set) var filmerStatus: CapabilityStatus?
    private(set) var isSubmitting = false
    private(set) var isGoingLive = false
    private(set) var errorMessage: String?

    private let api: FilmerOnboardingAPI
    private let sleep: @MainActor (Duration) async throws -> Void

    init(api: FilmerOnboardingAPI = FilmerOnboardingRepository(),
         sleep: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
        self.api = api
        self.sleep = sleep
    }

    var entry: FilmerOnboarding.Entry {
        FilmerOnboarding.entry(application: application, filmerStatus: filmerStatus)
    }

    var stepAfterPitch: FilmerOnboarding.StepAfterPitch {
        FilmerOnboarding.stepAfterPitch(identity: identity)
    }

    var reviewProgress: FilmerReviewProgress {
        FilmerReviewProgress(identity: identity, application: application)
    }

    func load(userID: UUID) async {
        defer { isLoading = false }
        await reload(userID: userID)
    }

    /// Re-reads all three rows. A failed read keeps what was shown and says so.
    func reload(userID: UUID) async {
        do {
            async let identity = api.verification(for: userID)
            async let application = api.application(for: userID)
            async let status = api.filmerStatus(for: userID)
            (self.identity, self.application, self.filmerStatus) = try await (identity, application, status)
            errorMessage = nil
        } catch {
            errorMessage = error.edgeFunctionUserMessage
        }
    }

    /// - Returns: whether the application went in, so the screen can move on.
    func submit(_ draft: FilmerApplicationDraft, userID: UUID) async -> Bool {
        guard draft.canSubmit, !isSubmitting else { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await api.submit(draft.request(userID: userID))
            errorMessage = nil
        } catch {
            errorMessage = error.edgeFunctionUserMessage
            return false
        }
        await reload(userID: userID)
        return true
    }

    /// Re-reads every `interval` until the review is cleared or turned down.
    /// Returns when the calling task is cancelled, i.e. the screen goes away.
    func keepCheckingReview(userID: UUID, every interval: Duration = reviewCheckInterval) async {
        while reviewProgress.shouldKeepChecking {
            do { try await sleep(interval) } catch { return }
            await reload(userID: userID)
        }
    }

    /// Saves the sample rates, then goes live. The order matters:
    /// `filmer_go_live()` refuses a profile with no hourly rate.
    ///
    /// - Parameter onLive: runs once the capability is active, before this
    ///   returns, so the caller can refresh capabilities and switch mode.
    func goLive(userID: UUID, onLive: @MainActor () async -> Void) async -> Bool {
        guard !isGoingLive else { return false }
        isGoingLive = true
        defer { isGoingLive = false }
        do {
            try await api.saveRates(.sample, for: userID)
            try await api.goLive()
            errorMessage = nil
        } catch {
            errorMessage = error.edgeFunctionUserMessage
            return false
        }
        await onLive()
        return true
    }
}
