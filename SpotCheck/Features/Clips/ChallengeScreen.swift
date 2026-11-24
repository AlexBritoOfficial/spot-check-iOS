import SwiftUI

/// The canvas's `Challenge` artboard -- the monthly challenge brief.
/// Entry counts and the prize stay the artboard's bracketed
/// placeholders; actions are intentionally unwired pending per-feature
/// planning.
struct ChallengeScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Monthly challenge",
                subtitle: "November · 9 days left",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    promo
                    howItWorks
                    judgesAndPrizes
                    entries

                    Button("Official rules") {}
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(SCColor.accent)
                        .padding(.vertical, 6)
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                Button("Submit your clip") {}
                    .buttonStyle(.scPrimary(fontSize: 14.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var promo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LEDGE TRICK")
                .font(SCFont.headingFixed(11))
                .tracking(1)
                .foregroundStyle(SCColor.accent)

            Text("Flip In, Flip Out")
                .font(SCFont.heading(30))
                .foregroundStyle(SCColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Film a flip trick into a ledge trick, then flip out.")
                .font(.system(size: 15))
                .lineSpacing(4)
                .foregroundStyle(SCColor.textBody)
                .fixedSize(horizontal: false, vertical: true)

            FlowChips(spacing: 8) {
                ForEach(["Free entry", "Skill-judged", "[N] entries"], id: \.self) { tag in
                    Text(tag.uppercased())
                        .font(SCFont.headingFixed(9.5))
                        .foregroundStyle(SCColor.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .scCard(cornerRadius: SCRadius.badge, fill: SCColor.background)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .scCard(
            cornerRadius: 18,
            fill: SCColor.accent.opacity(0.1),
            borderColor: SCColor.accent,
            borderWidth: 1.5
        )
    }

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HOW IT WORKS").scSectionLabel()

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(ChallengeScreen.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(SCFont.headingFixed(12))
                            .foregroundStyle(SCColor.accent)
                            .frame(width: 26, height: 26)
                            .overlay(Circle().stroke(SCColor.accent, lineWidth: 1.5))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SCColor.textPrimary)
                            Text(step.detail)
                                .font(.system(size: 12.5))
                                .foregroundStyle(SCColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var judgesAndPrizes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("JUDGES & PRIZES").scSectionLabel()

            VStack(spacing: 10) {
                judgeRow(name: "Bricktown Skate Shop", tag: "Shop", isPro: false)
                judgeRow(name: "Rider Chen", tag: "Pro", isPro: true)
            }

            SCColor.border.frame(height: 1)

            HStack {
                Text("Prize")
                    .foregroundStyle(SCColor.textBody)
                Spacer()
                Text("[Prize from partner shop]")
                    .fontWeight(.semibold)
                    .foregroundStyle(SCColor.textPrimary)
            }
            .font(.system(size: 14))
        }
        .padding(16)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private func judgeRow(name: String, tag: String, isPro: Bool) -> some View {
        HStack(spacing: 10) {
            Avatar(
                initial: name,
                size: 32,
                backgroundColor: SCColor.border,
                foregroundColor: SCColor.textPrimary
            )
            Text(name)
                .font(.system(size: 14))
                .foregroundStyle(SCColor.textPrimary)
            Spacer()
            SCTag(
                text: tag,
                foreground: isPro ? SCColor.background : SCColor.textPrimary,
                background: isPro ? SCColor.accent : SCColor.border
            )
        }
    }

    private var entries: some View {
        VStack(alignment: .leading, spacing: 10) {
            SCSectionHeader("Entries") {
                Button("See all") {}
                    .font(.system(size: 13))
                    .foregroundStyle(SCColor.accent)
            }

            HStack(alignment: .top, spacing: 8) {
                ForEach(ChallengeScreen.entryNames, id: \.self) { name in
                    VStack(alignment: .leading, spacing: 6) {
                        SCMediaPlaceholder(showsPlayBadge: true)
                            .aspectRatio(4.0 / 5.0, contentMode: .fit)
                            .overlay(alignment: .topLeading) {
                                if name == "New rider" {
                                    SCTag(text: "Fresh pick", background: SCColor.success)
                                        .padding(6)
                                }
                            }
                        Text(name)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(SCColor.textPrimary)
                    }
                }
            }

            Text("Fresh picks keep newer skaters visible next to the top entries.")
                .font(.system(size: 12.5))
                .foregroundStyle(SCColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension ChallengeScreen {
    static let steps: [(title: String, detail: String)] = [
        ("Post your clip", "Tag it to the challenge when you post"),
        ("Community votes", "Members pick the finalists"),
        ("Shops and pros judge", "Partner judges choose the winners"),
        ("Winners announced", "Shown on profiles and in the feed")
    ]

    static let entryNames = ["Rider Silva", "Rider Chen", "New rider"]
}

#Preview {
    ChallengeScreen()
}
