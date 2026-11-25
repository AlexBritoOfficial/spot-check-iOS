import SwiftUI

/// Mirrors the canvas's "ProApply" artboard: the "Become a filmer" pitch
/// that opens filmer onboarding. The artboard tops out in a bare back
/// chevron rather than a titled bar, so this draws its own 44pt row
/// instead of using `SCNavHeader`.
///
/// The step list puts "Verify your ID" first, unlike the canvas: Alex
/// (2026-11-25) moved the ID check ahead of the portfolio.
struct ProApplyScreen: View {
    /// Where Continue goes is FilmerOnboardingView's call: the ID check, or
    /// the portfolio for someone already verified.
    var onContinue: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            backRow

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    pitch
                    serviceCard
                    backgroundCheckCallout
                    SCStepList(steps: ProApplyScreen.onboardingSteps)
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }

            SCFooterBar {
                VStack(spacing: 10) {
                    Button("Continue") { onContinue() }
                        .buttonStyle(.scPrimary)

                    Text("You must be 18 or older to film for Spot Check.")
                        .font(.system(size: 12))
                        .foregroundStyle(SCColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var backRow: some View {
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

    private var pitch: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SPOT CHECK FILMERS")
                .font(SCFont.headingFixed(12))
                .tracking(1)
                .foregroundStyle(SCColor.accent)

            Text("Get paid to film")
                .font(SCFont.heading(28))
                .foregroundStyle(SCColor.textPrimary)

            Text("Film tricks and shoot photos for other skaters, and get paid for every session.")
                .font(.system(size: 15))
                .lineSpacing(4)
                .foregroundStyle(SCColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var serviceCard: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: SCRadius.control)
                .fill(SCColor.accent.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "video")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(SCColor.accent)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Filming & photos")
                    .font(SCFont.headingFixed(16))
                    .foregroundStyle(SCColor.textPrimary)

                Text("Get paid by skaters to film their tricks or shoot photos.")
                    .font(.system(size: 13.5))
                    .lineSpacing(3)
                    .foregroundStyle(SCColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Pro camera and portfolio required")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(SCColor.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .scCard(cornerRadius: SCRadius.card, borderColor: SCColor.accent, borderWidth: 2)
    }

    private var backgroundCheckCallout: some View {
        SCCallout(
            tone: .success,
            systemImage: "checkmark.shield",
            cornerRadius: SCRadius.cardSmall
        ) {
            (
                Text("Every filmer passes a background check.")
                    .foregroundStyle(SCColor.textPrimary)
                    .bold()
                    + Text(" Your services stay hidden until it clears.")
                    .foregroundStyle(SCColor.textBody)
            )
            .font(.system(size: 13.5))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension ProApplyScreen {
    static let onboardingSteps: [SCStepList.Step] = [
        .init(title: "Verify your ID", isReached: true),
        .init(title: "Show your gear and portfolio"),
        .init(title: "Pass a background check"),
        .init(title: "Set your rates and go live")
    ]
}

#Preview {
    ProApplyScreen()
        .background(SCColor.background)
}
