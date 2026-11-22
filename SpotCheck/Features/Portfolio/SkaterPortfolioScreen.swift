import SwiftUI

/// Mirrors the canvas's "Your profile" (SkaterPortfolio) artboard -- the
/// signed-in skater's own portfolio, not the other-skater profile in
/// `Features/SkaterProfile`. The artboard also draws the main bottom nav;
/// that belongs to the shared `SCBottomNavBar` in the tab shell, so the
/// scroll content only reserves `SCMetric.bottomNavClearance` for it.
/// Actions are intentionally unwired pending per-feature planning.
struct SkaterPortfolioScreen: View {
    var body: some View {
        VStack(spacing: 0) {
            handleRow

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    identityRow
                    statGrid
                    sponsorshipLadderSection
                    videoPartsSection
                    clipsSection
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 6)
                .padding(.bottom, SCMetric.bottomNavClearance)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var handleRow: some View {
        HStack(spacing: 6) {
            Text("@rider.nguyen")
                .font(SCFont.headingFixed(14))
                .foregroundStyle(SCColor.textSecondary)

            Spacer(minLength: 0)

            Button {} label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Menu")
        }
        .padding(.leading, SCMetric.screenPadding)
        .padding(.trailing, 10)
        .padding(.top, SCMetric.headerTop(52))
    }

    private var identityRow: some View {
        HStack(spacing: 16) {
            Avatar(initial: "R", size: 80)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Rider Nguyen")
                    .font(SCFont.heading(22))
                    .foregroundStyle(SCColor.textPrimary)

                Text("Boston · Regular · Street")
                    .font(.system(size: 13))
                    .foregroundStyle(SCColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    microTag("SHOP SPONSORED", foreground: SCColor.accent)
                    microTag("1 VIDEO PART", foreground: SCColor.textSecondary)
                }
            }
        }
    }

    private func microTag(_ text: String, foreground: Color) -> some View {
        Text(text)
            .font(SCFont.headingFixed(9.5))
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(SCColor.background)
            .overlay(
                RoundedRectangle(cornerRadius: SCRadius.badge)
                    .stroke(SCColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: SCRadius.badge))
    }

    private var statGrid: some View {
        Button {} label: {
            HStack(spacing: 8) {
                SCStatTile(value: "[N]", label: "Profile visits")
                SCStatTile(value: "2", label: "Industry visits", valueColor: SCColor.accent)
                SCStatTile(value: "[N]", label: "Clip views")
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens profile insights")
    }

    private var sponsorshipLadderSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SCSectionHeader("Sponsorship ladder") {
                Button("Add a step") {}
                    .font(.system(size: 13))
                    .foregroundStyle(SCColor.accent)
                    .padding(.vertical, 6)
            }
            .padding(.bottom, 4)

            SCStepList(
                steps: sponsorshipLadder.map { step in
                    .init(
                        title: step.title,
                        detail: step.detail,
                        isReached: step.isReached,
                        trailingNote: step.note,
                        trailingNoteColor: step.isVerified ? SCColor.success : SCColor.textSecondary,
                        trailingNoteSystemImage: step.isVerified ? "checkmark" : nil
                    )
                },
                showsDividers: true,
                markerSize: 28
            )

            Text("A step shows Verified only when the shop or brand confirms it on Spot Check.")
                .font(.system(size: 12))
                .lineSpacing(3)
                .foregroundStyle(SCColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
    }

    private var videoPartsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SCSectionHeader("Video parts")

            HStack(spacing: 12) {
                SCMediaPlaceholder(cornerRadius: SCRadius.control, showsPlayBadge: true)
                    .frame(width: 96, height: 60)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Bricktown shop video")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SCColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Part · 2026 · filmed by Rider Okafor")
                        .font(.system(size: 12.5))
                        .foregroundStyle(SCColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .scCard(cornerRadius: SCRadius.cardSmall)
        }
    }

    private var clipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SCSectionHeader("Clips")

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
                spacing: 6
            ) {
                ForEach(portfolioClips) { clip in
                    SCMediaPlaceholder(cornerRadius: SCRadius.control)
                        .aspectRatio(4.0 / 5.0, contentMode: .fit)
                        .overlay(alignment: .topTrailing) {
                            if clip.isPrivate {
                                privateLockBadge
                            }
                        }
                        .accessibilityElement()
                        .accessibilityLabel(clip.isPrivate ? "Private clip" : "Clip")
                }
            }
        }
    }

    private var privateLockBadge: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(SCColor.textPrimary)
            .frame(width: 22, height: 22)
            .background(SCColor.backgroundDeep.opacity(0.85))
            .clipShape(Circle())
            .padding(6)
    }
}

private struct LadderStep {
    let title: String
    let detail: String
    var isReached: Bool = false
    var note: String?
    var isVerified: Bool = false
}

private let sponsorshipLadder: [LadderStep] = [
    LadderStep(
        title: "Shop Sponsor",
        detail: "Bricktown Skate Shop",
        isReached: true,
        note: "Verified",
        isVerified: true
    ),
    LadderStep(title: "Flow", detail: "Low Tide Wheels", isReached: true, note: "Self-reported"),
    LadderStep(title: "Am", detail: "Official team rider"),
    LadderStep(title: "Pro", detail: "Pro model or signature product")
]

private struct PortfolioClip: Identifiable {
    let id: Int
    var isPrivate: Bool = false
}

private let portfolioClips: [PortfolioClip] = [
    PortfolioClip(id: 0),
    PortfolioClip(id: 1),
    PortfolioClip(id: 2, isPrivate: true)
]

#Preview {
    SkaterPortfolioScreen()
        .background(SCColor.background)
}
