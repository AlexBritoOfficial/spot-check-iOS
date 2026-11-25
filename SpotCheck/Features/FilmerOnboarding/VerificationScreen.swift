import SwiftUI

/// The canvas's `Verification` artboard -- filmer background-check
/// status, not an auth/OTP step. The artboard draws two variants, in
/// review and passed; this reads the real rows through
/// `FilmerReviewProgress`, and adds a "Not approved" line the canvas never
/// drew, for a review a person turned down.
///
/// Re-checking while it's open belongs to FilmerOnboardingView, which owns
/// the flow; this screen only draws what it's given.
struct VerificationScreen: View {
    let progress: FilmerReviewProgress
    var onSetRates: () -> Void = {}
    /// Leaves the whole filmer flow ("Back to the map").
    var onLeave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    private var isPassed: Bool { progress.isCleared }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    statusBlock
                    checklist
                    serviceSection
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }

            SCFooterBar {
                if isPassed {
                    Button("Set rates & go live") { onSetRates() }
                        .buttonStyle(.scPrimary)
                } else {
                    Button("Back to the map") { (onLeave ?? { dismiss() })() }
                        .buttonStyle(.scSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, SCMetric.headerTop(52))
    }

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: isPassed ? "checkmark" : "clock")
                    .font(.system(size: 11, weight: .bold))
                Text(isPassed ? "PASSED" : "IN REVIEW")
                    .font(SCFont.headingFixed(11))
                    .tracking(0.5)
            }
            .foregroundStyle(isPassed ? SCColor.success : SCColor.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background((isPassed ? SCColor.success : SCColor.accent).opacity(0.14))
            .clipShape(Capsule())

            Text(isPassed ? "You're cleared to film"
                 : progress.hasFailure ? "Your application wasn't approved"
                 : "Your background check is in progress")
                .font(SCFont.heading(26))
                .foregroundStyle(SCColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(isPassed
                 ? "Your profile now shows a Background checked badge. Set your rates to start taking bookings."
                 : progress.hasFailure
                 ? "Contact Spot Check if you think this is a mistake."
                 : "We're also reviewing your camera and portfolio. This page updates by itself.")
                .font(.system(size: 15))
                .lineSpacing(4)
                .foregroundStyle(SCColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var checklist: some View {
        SCTimeline(
            steps: [
                .init(
                    title: "ID verified",
                    detail: progress.isIDVerified ? "Government ID and selfie match" : "Not verified yet",
                    marker: progress.isIDVerified ? .done : .pending
                ),
                .init(
                    title: "Consent signed",
                    detail: progress.isConsentSigned ? "You authorized the background check" : "Not signed yet",
                    marker: progress.isConsentSigned ? .done : .pending
                ),
                reviewStep(
                    title: "Gear & portfolio review",
                    status: progress.gearReview,
                    passed: "Pro camera and portfolio approved",
                    waiting: "Filming & photos: in review by our team"
                ),
                reviewStep(
                    title: "Background check",
                    status: progress.backgroundCheck,
                    passed: "Passed",
                    waiting: "In review with our screening partner"
                ),
                .init(
                    title: "Set rates & go live",
                    detail: isPassed ? "Ready when you are" : "Unlocks after your check passes",
                    marker: isPassed ? .numbered(4) : .locked
                )
            ],
            showsConnector: false,
            titleStyle: .heading,
            markerSize: 26,
            spacing: 18
        )
        .padding(18)
        .scCard()
    }

    private func reviewStep(title: String, status: ReviewStatus, passed: String, waiting: String) -> SCTimeline.Step {
        switch status {
        case .passed:
            .init(title: title, detail: passed, detailColor: SCColor.success, marker: .done)
        case .failed:
            .init(title: title, detail: "Not approved", detailColor: SCColor.danger, marker: .pending)
        case .pending, .inReview:
            .init(title: title, detail: waiting, detailColor: SCColor.accent, marker: .inProgress)
        }
    }

    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR SERVICE").scSectionLabel()
            HStack {
                Text("Filming & photos")
                    .font(SCFont.headingFixed(14))
                    .foregroundStyle(SCColor.textPrimary)
                Spacer()
                Text(isPassed ? "READY" : "LOCKED")
                    .font(SCFont.headingFixed(11))
                    .foregroundStyle(isPassed ? SCColor.success : SCColor.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .scCard(cornerRadius: SCRadius.cardSmall)
        }
    }
}

#Preview("In review") {
    VerificationScreen(progress: .preview(gear: .inReview, check: .pending))
}

#Preview("Passed") {
    VerificationScreen(progress: .preview(gear: .passed, check: .passed))
}

#Preview("Not approved") {
    VerificationScreen(progress: .preview(gear: .passed, check: .failed))
}

private extension FilmerReviewProgress {
    static func preview(gear: ReviewStatus, check: ReviewStatus) -> FilmerReviewProgress {
        FilmerReviewProgress(
            identity: IdentityVerification(status: .verified, lastErrorCode: nil, verifiedIsAdult: true),
            application: FilmerApplication(
                gear: [], styles: [], reelPath: nil, rawClipPath: "sample.mp4",
                hourlyRateCents: nil, parkDropInCents: nil, consentSignedAt: .now,
                gearReviewStatus: gear, backgroundCheckStatus: check, wentLiveAt: nil, pausedAt: nil
            )
        )
    }
}
