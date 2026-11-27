import Foundation
import Observation

/// IDVerifyScreen's state, from its first load through Stripe's sheet and
/// back. Kept free of StripeIdentity: the sheet is handed in as a closure, so
/// every outcome is testable without presenting anything.
///
/// The sheet finishing is *not* a verification. The result reaches the
/// database by webhook, usually seconds later, so after the sheet the flow
/// re-reads the row and shows "processing" until the webhook has landed.
@MainActor
@Observable
final class IdentityVerificationFlow {
    enum State: Equatable {
        case loading
        case notStarted
        /// Stripe asked for another attempt, and said why.
        case needsRetry(reason: String)
        case starting
        /// Stripe's sheet is on screen.
        case inProgress
        /// Submitted; waiting on Stripe's answer.
        case processing
        case verified
        /// Verified, but the ID says under 18. Spot Check is 18+.
        case notAdult
        /// Verified, but Stripe returned no readable date of birth, so whether
        /// the user is 18+ is unknown. Never shown as under 18.
        case ageUnknown
        /// Couldn't start, or the sheet itself failed.
        case failed(message: String)
    }

    /// How Stripe's sheet closed, in the app's own terms.
    enum SheetOutcome: Equatable, Sendable {
        case completed
        case canceled
        case failed(message: String)
    }

    private(set) var state: State = .loading

    /// How often the screen re-reads while Stripe is checking.
    static let processingCheckInterval: Duration = .seconds(3)

    private let api: IdentityVerificationAPI
    private let onVerified: @MainActor () async -> Void
    private let sleep: @MainActor (Duration) async throws -> Void

    /// - Parameter onVerified: called once the user becomes a verified adult,
    ///   so session-wide state (the menu's "Verify your ID" row) can refresh.
    /// - Parameter sleep: `Task.sleep`, replaceable so tests needn't wait.
    init(api: IdentityVerificationAPI = IdentityVerificationRepository(),
         onVerified: @escaping @MainActor () async -> Void = {},
         sleep: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
        self.api = api
        self.onVerified = onVerified
        self.sleep = sleep
    }

    func load(userID: UUID) async {
        state = .loading
        await refresh(userID: userID)
    }

    /// Re-reads the stored row, e.g. after "Check status".
    func refresh(userID: UUID) async {
        do {
            let row = try await api.verification(for: userID)
            // Once submitted, a requires_input row with no error only means
            // Stripe's first webhook hasn't landed yet -- not "never started".
            // Reading it as notStarted dropped the "checking" note and offered
            // "Start verification" again, which replaced the submitted session.
            if state == .processing, row?.status == .requiresInput, row?.lastErrorCode == nil {
                return
            }
            await setState(State(row: row))
        } catch {
            state = .failed(message: error.edgeFunctionUserMessage)
        }
    }

    /// Re-reads every `interval` while Stripe is checking, so the screen moves
    /// on by itself when the webhook lands. Returns on a final answer, or when
    /// the calling task is cancelled -- i.e. the screen goes away.
    func keepCheckingWhileProcessing(userID: UUID, every interval: Duration = processingCheckInterval) async {
        while state == .processing {
            do { try await sleep(interval) } catch { return }
            await refresh(userID: userID)
        }
    }

    func start(userID: UUID, present: @MainActor (String) async -> SheetOutcome) async {
        let before = state
        state = .starting

        let start: IdentitySessionStart
        do {
            start = try await api.startSession()
        } catch {
            state = .failed(message: error.edgeFunctionUserMessage)
            return
        }

        switch start {
        case .alreadyVerified, .alreadySubmitted:
            await afterSubmitting(userID: userID)
        case .verify(let clientSecret):
            state = .inProgress
            switch await present(clientSecret) {
            case .completed:
                await afterSubmitting(userID: userID)
            case .canceled:
                // Closing the sheet isn't a failure; nothing changed.
                state = before == .loading ? .notStarted : before
            case .failed(let message):
                state = .failed(message: message)
            }
        }
    }

    /// The user has submitted, so whatever the row says, "Start verification"
    /// is wrong -- unless the webhook has already given a final answer.
    private func afterSubmitting(userID: UUID) async {
        let answer = State(row: try? await api.verification(for: userID))
        if answer.isFinal {
            await setState(answer)
        } else {
            state = .processing
        }
    }

    private func setState(_ new: State) async {
        let wasVerified = state == .verified
        state = new
        if new == .verified, !wasVerified {
            await onVerified()
        }
    }
}

extension IdentityVerificationFlow.State {
    /// What a stored row means on screen.
    init(row: IdentityVerification?) {
        guard let row else {
            self = .notStarted
            return
        }
        switch row.status {
        case .verified:
            // false is "checked, and a minor"; nil is "couldn't tell".
            switch row.verifiedIsAdult {
            case true?: self = .verified
            case false?: self = .notAdult
            case nil: self = .ageUnknown
            }
        case .processing:
            self = .processing
        case .canceled:
            self = .notStarted
        case .requiresInput:
            // A fresh session also starts at requires_input; only an error
            // code means an attempt was actually made and turned down.
            if let code = row.lastErrorCode {
                self = .needsRetry(reason: Self.reason(forStripeError: code))
            } else {
                self = .notStarted
            }
        }
    }

    /// An answer from Stripe the user acts on, as opposed to "still waiting".
    var isFinal: Bool {
        switch self {
        case .verified, .notAdult, .ageUnknown, .needsRetry: true
        default: false
        }
    }

    /// Shown with a warning on IDVerifyScreen: something the user has to act
    /// on or can't get past.
    var isProblem: Bool {
        switch self {
        case .needsRetry, .failed, .notAdult, .ageUnknown: true
        default: false
        }
    }

    enum PrimaryAction: Equatable {
        case start(title: String)
        case refresh(title: String)
        case busy(title: String)
        case done
        /// Inside "Earn with Spot Check": on to the portfolio step.
        case continueOnboarding
    }

    var primaryAction: PrimaryAction {
        switch self {
        case .loading: .busy(title: "Loading…")
        case .notStarted: .start(title: "Start verification")
        // identity-session starts a fresh session for an unknown age.
        case .needsRetry, .failed, .ageUnknown: .start(title: "Try again")
        case .starting: .busy(title: "Starting…")
        case .inProgress: .busy(title: "Verifying…")
        case .processing: .refresh(title: "Check status")
        case .verified, .notAdult: .done
        }
    }

    /// Inside the filmer flow a verified adult continues to the next step,
    /// while an under-18 gets Done: the flow ends there.
    func primaryAction(in context: IDVerifyContext) -> PrimaryAction {
        if context == .filmerOnboarding, self == .verified { return .continueOnboarding }
        return primaryAction
    }

    /// The filmer flow can't be skipped past: Alex, 2026-11-25, wait for the
    /// ID to be verified. From the menu it can, until there's nothing to do.
    func offersSkip(in context: IDVerifyContext) -> Bool {
        context == .standalone && primaryAction != .done
    }

    /// A line under the steps saying where things stand, when there is one.
    var statusMessage: String? {
        switch self {
        case .needsRetry(let reason): reason
        case .failed(let message): message
        case .processing: "Stripe is checking your ID. This usually takes a minute or two."
        case .verified: "You're verified. You can book, pay and get paid."
        case .notAdult: "Your ID shows you're under 18. Booking, paying and getting paid on Spot Check are 18+."
        case .ageUnknown: "Your ID was verified, but we couldn't read the date of birth on it. Try again with an ID where it's clear."
        case .loading, .notStarted, .starting, .inProgress: nil
        }
    }

    /// Stripe's `last_error.code` values for a VerificationSession, in plain
    /// words. Anything not listed still gets a reason, never the raw code.
    static func reason(forStripeError code: String) -> String {
        switch code {
        case "document_expired":
            "Your ID has expired. Try again with a current one."
        case "document_type_not_supported":
            "That kind of ID isn't accepted. Use a driver's license, state ID or passport."
        case "document_unverified_other":
            "We couldn't read your ID. Try again somewhere well lit."
        case "selfie_face_mismatch", "selfie_document_missing_photo",
             "selfie_manipulated", "selfie_unverified_other":
            "Your selfie didn't match your ID photo. Try again in good light."
        case "consent_declined":
            "Verification needs your consent to continue."
        case "under_supported_age":
            "Spot Check is 18+, and your ID shows you're under 18."
        default:
            "We couldn't verify your ID. Try again."
        }
    }
}


/// Where IDVerifyScreen was opened from.
enum IDVerifyContext: Equatable {
    /// The menu's "Verify your ID" row.
    case standalone
    /// Step 2 of "Earn with Spot Check".
    case filmerOnboarding
}
