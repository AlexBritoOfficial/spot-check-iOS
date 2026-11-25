import SwiftUI

/// The canvas's `IDVerify` artboard -- the 18+ ID and age check that
/// gates booking and payouts. "Start verification" runs Stripe Identity
/// through `IdentityVerificationFlow`; the result arrives by webhook, so the
/// footer can also show "Check status" while Stripe decides, and re-checks
/// by itself every few seconds while the screen is open.
///
/// Opened from "Earn with Spot Check" it is a step that can't be skipped:
/// Continue unlocks once the user is a verified adult.
struct IDVerifyScreen: View {
    var context: IDVerifyContext = .standalone
    /// The filmer flow's next step. Unused from the menu.
    var onContinue: () -> Void = {}
    /// Leaves the whole filmer flow (an under-18 ID ends it). Defaults to
    /// closing just this screen.
    var onLeave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager

    @State private var flow: IdentityVerificationFlow?

    private var userID: UUID? {
        if case .signedIn(let id) = authManager.state { id } else { nil }
    }

    private var state: IdentityVerificationFlow.State { flow?.state ?? .loading }

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Verify your age and ID",
                subtitle: "Spot Check is 18+",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Everyone who books, pays or gets paid verifies once. It takes about two minutes.")
                        .font(.system(size: 15))
                        .lineSpacing(4)
                        .foregroundStyle(SCColor.textBody)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        stepCard(
                            systemImage: "person.text.rectangle",
                            title: "1. Scan a photo ID",
                            detail: "Driver's license, state ID or passport"
                        )
                        stepCard(
                            systemImage: "person.crop.circle",
                            title: "2. Take a quick selfie",
                            detail: "Matched to your ID photo"
                        )
                    }

                    if let message = state.statusMessage {
                        statusNote(message)
                    }

                    SCNoteRow(
                        text: "Checks run through our verification partner. Spot Check only keeps your verified status and age.",
                        systemImage: "lock.fill",
                        iconColor: SCColor.success
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("WITHOUT IT YOU CAN").scSectionLabel()
                        Text("Browse spots, watch clips and chat. Booking, paying and getting paid need verification.")
                            .font(.system(size: 14))
                            .lineSpacing(4)
                            .foregroundStyle(SCColor.textBody)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scCard(cornerRadius: SCRadius.cardSmall)
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                VStack(spacing: 10) {
                    primaryButton
                    if state.offersSkip(in: context) {
                        Button("Skip for now") { dismiss() }
                            .buttonStyle(.scSecondary(fontSize: 14.5))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
        .task {
            guard flow == nil, let userID else { return }
            let flow = IdentityVerificationFlow(onVerified: { [authManager] in
                await authManager.refreshProfile()
            })
            self.flow = flow
            await flow.load(userID: userID)
        }
        // Restarts whenever "processing" begins or ends, and is cancelled
        // when the screen goes away, which ends the loop.
        .task(id: state == .processing) {
            guard let flow, let userID, state == .processing else { return }
            await flow.keepCheckingWhileProcessing(userID: userID)
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch state.primaryAction(in: context) {
        case .start(let title):
            Button(title) { run { flow, userID in
                await flow.start(userID: userID, present: StripeIdentitySheet.present(clientSecret:))
            } }
            .buttonStyle(.scPrimary(fontSize: 14.5))
        case .refresh(let title):
            Button(title) { run { flow, userID in await flow.refresh(userID: userID) } }
                .buttonStyle(.scPrimary(fontSize: 14.5))
        case .busy(let title):
            Button(title) {}
                .buttonStyle(.scPrimary(fontSize: 14.5))
                .disabled(true)
        case .done:
            Button("Done") { (onLeave ?? { dismiss() })() }
                .buttonStyle(.scPrimary(fontSize: 14.5))
        case .continueOnboarding:
            Button("Continue") { onContinue() }
                .buttonStyle(.scPrimary(fontSize: 14.5))
        }
    }

    private func run(_ action: @escaping @MainActor (IdentityVerificationFlow, UUID) async -> Void) {
        guard let flow, let userID else { return }
        Task { await action(flow, userID) }
    }

    private func statusNote(_ message: String) -> some View {
        let isGood = state == .verified
        let isProblem: Bool = switch state {
        case .needsRetry, .failed, .notAdult: true
        default: false
        }
        return SCNoteRow(
            text: message,
            systemImage: isGood ? "checkmark.seal.fill" : isProblem ? "exclamationmark.triangle.fill" : "clock",
            iconColor: isGood ? SCColor.success : isProblem ? SCColor.danger : SCColor.accent
        )
    }

    private func stepCard(systemImage: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 20))
                .foregroundStyle(SCColor.accent)
                .frame(width: 44, height: 44)
                .background(SCColor.accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                Text(detail)
                    .font(.system(size: 12.5))
                    .foregroundStyle(SCColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }
}

#Preview {
    IDVerifyScreen()
        .environment(AuthManager())
}
