import SwiftUI

/// "Earn with Spot Check", from the menu: one navigation stack over the five
/// onboarding screens, sharing one `FilmerOnboardingFlow`.
///
///     ProApply → IDVerify → FilmerQualify → Verification → FilmerRates → live
///
/// It opens where the user left off (`FilmerOnboarding.entry`): the pitch if
/// they never applied, the status checklist once they have, the paused screen
/// for a paused filmer. Each screen draws its own back chevron, so the
/// system navigation bar is hidden throughout.
struct FilmerOnboardingView: View {
    /// Closes the whole flow.
    var onClose: () -> Void
    /// The filmer capability is now active and capabilities are refreshed:
    /// the caller switches into filmer mode and opens Discover.
    var onWentLive: () -> Void

    @Environment(AuthManager.self) private var authManager

    @State private var flow = FilmerOnboardingFlow()
    @State private var path: [Step] = []
    /// Decided once, when the flow opens. `flow.entry` moves as the user
    /// progresses (submitting creates the application), and the root
    /// changing under a pushed screen would show the checklist twice.
    @State private var entry: FilmerOnboarding.Entry?

    enum Step: Hashable {
        case verifyID
        case portfolio
        case review
        case rates
    }

    private var userID: UUID? {
        if case .signedIn(let id) = authManager.state { id } else { nil }
    }

    var body: some View {
        NavigationStack(path: $path) {
            root
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Step.self) { step in
                    destination(step)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
        .task {
            guard let userID else { return }
            await flow.load(userID: userID)
            entry = flow.entry
        }
    }

    @ViewBuilder
    private var root: some View {
        switch entry {
        case nil:
            ProgressView()
                .tint(SCColor.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SCColor.background)
        case let entry?:
            switch entry {
            case .pitch:
                ProApplyScreen(onContinue: continueFromPitch)
            case .review:
                review
            case .paused:
                StrikePausedScreen()
            case .live:
                // Already a filmer (the menu normally shows Filmer tools
                // instead): there is nothing to apply for, so go to Discover.
                Color.clear.onAppear(perform: onWentLive)
            }
        }
    }

    @ViewBuilder
    private func destination(_ step: Step) -> some View {
        switch step {
        case .verifyID:
            IDVerifyScreen(
                context: .filmerOnboarding,
                onContinue: {
                    path.append(.portfolio)
                    // The checklist's "ID verified" reads the flow's copy.
                    Task { if let userID { await flow.reload(userID: userID) } }
                },
                onLeave: onClose
            )
        case .portfolio:
            FilmerQualifyScreen(flow: flow, userID: userID) {
                // Not pushed on top: going back from the status checklist
                // shouldn't reopen a form that has already been sent.
                path = [.review]
            }
        case .review:
            review
        case .rates:
            FilmerRatesScreen(
                isGoingLive: flow.isGoingLive,
                errorMessage: flow.errorMessage,
                onGoLive: goLive
            )
        }
    }

    private var review: some View {
        VerificationScreen(
            progress: flow.reviewProgress,
            onSetRates: { path.append(.rates) },
            onLeave: onClose
        )
        // Cancelled when the screen goes away, which ends the loop.
        .task {
            guard let userID else { return }
            await flow.keepCheckingReview(userID: userID)
        }
    }

    private func continueFromPitch() {
        switch flow.stepAfterPitch {
        case .portfolio:
            path.append(.portfolio)
        // An under-18 ID is explained on the ID screen, whose Done ends the
        // flow; there is no step after it.
        case .verifyID, .notAdult:
            path.append(.verifyID)
        }
    }

    private func goLive() {
        guard let userID else { return }
        Task {
            _ = await flow.goLive(userID: userID) {
                await authManager.refreshProfile()
                onWentLive()
            }
        }
    }
}
