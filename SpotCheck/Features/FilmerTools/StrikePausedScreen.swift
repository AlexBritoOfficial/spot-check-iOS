import SwiftUI

/// The canvas's `StrikePaused` artboard -- what a filmer sees once late
/// cancellations have paused their profile. Read-only by nature;
/// contacting support is intentionally unwired pending per-feature
/// planning.
struct StrikePausedScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(title: "Filmer profile", onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusBlock
                    strikesSection
                    whilePausedCard
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                VStack(spacing: 10) {
                    Button("Contact Spot Check") {}
                        .buttonStyle(.scPrimary(fontSize: 14.5))
                    Button("View the policy") {}
                        .buttonStyle(.scSecondary(fontSize: 14.5))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PAUSED · 3 OF 3 STRIKES")
                .font(SCFont.headingFixed(11))
                .tracking(0.5)
                .foregroundStyle(SCColor.danger)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(SCColor.danger.opacity(0.14))
                .clipShape(Capsule())

            Text("Your profile is paused")
                .font(SCFont.heading(26))
                .foregroundStyle(SCColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("You cancelled three sessions late, so your profile was paused automatically.")
                .font(.system(size: 15))
                .lineSpacing(4)
                .foregroundStyle(SCColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var strikesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("STRIKES").scSectionLabel()

            VStack(spacing: 0) {
                ForEach(Array(StrikePausedScreen.strikes.enumerated()), id: \.offset) { index, strike in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(SCFont.headingFixed(12))
                            .foregroundStyle(SCColor.danger)
                            .frame(width: 26, height: 26)
                            .background(SCColor.danger.opacity(0.15))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(strike.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SCColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(strike.detail)
                                .font(.system(size: 12.5))
                                .foregroundStyle(SCColor.textSecondary)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .top) { SCColor.border.frame(height: 1) }
                }
            }
        }
    }

    private var whilePausedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHILE PAUSED").scSectionLabel()

            VStack(alignment: .leading, spacing: 6) {
                ForEach(StrikePausedScreen.consequences, id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(line)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.system(size: 14))
                    .lineSpacing(3)
                    .foregroundStyle(SCColor.textBody)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }
}

private extension StrikePausedScreen {
    static let strikes: [(title: String, detail: String)] = [
        ("Cancelled 3 hrs before a session", "Nov 2 · Rider Chen refunded + credit"),
        ("Cancelled 1 hr before a session", "Nov 9 · Rider Silva refunded + credit"),
        ("Cancelled 30 min before a session", "Nov 18 · Rider Nguyen refunded + credit")
    ]

    static let consequences = [
        "Skaters can't find or request you",
        "Your Discover inbox is empty",
        "Money already held for finished sessions still pays out"
    ]
}

#Preview {
    StrikePausedScreen()
}
