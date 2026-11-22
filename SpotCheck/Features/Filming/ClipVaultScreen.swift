import SwiftUI

/// The canvas's `ClipVault` artboard -- where a skater picks up the raw
/// clips from a session, with the escrow trail above them. The
/// makes/bails tab is local view state; downloads and rating are
/// intentionally unwired pending per-feature planning.
struct ClipVaultScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showsMakes = true

    private var makes: [VaultClip] { ClipVaultScreen.clips.filter(\.isMake) }
    private var bails: [VaultClip] { ClipVaultScreen.clips.filter { !$0.isMake } }
    private var shown: [VaultClip] { showsMakes ? makes : bails }

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Raw Clip Vault",
                subtitle: "Filmed by Rider Okafor · Eggs · Today",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    escrowTrail
                    confirmationCallout
                    rateRow
                    clipTabs
                    clipGrid

                    SCNoteRow(
                        text: "Full-resolution files stay in your vault for [X] days. Download the ones you want to keep.",
                        systemImage: "clock"
                    )
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                Button(showsMakes ? "Download makes" : "Download bails") {}
                    .buttonStyle(.scPrimary(fontSize: 14))
                Button("Post a clip") {}
                    .buttonStyle(.scSecondary(fontSize: 14))
                    .frame(width: 130)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var escrowTrail: some View {
        HStack(alignment: .top, spacing: 0) {
            escrowStep(title: "Charged & held", isCurrent: false)
            escrowStep(title: "Both confirmed", isCurrent: false)
            escrowStep(title: "Raw clips delivered", isCurrent: false)
            escrowStep(title: "Filmer paid", isCurrent: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .scCard(cornerRadius: SCRadius.cardSmall)
        .accessibilityLabel("Payment status")
    }

    private func escrowStep(title: String, isCurrent: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: isCurrent ? "plus" : "checkmark")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(SCColor.background)
                .frame(width: 24, height: 24)
                .background(isCurrent ? SCColor.accent : SCColor.success)
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 11, weight: isCurrent ? .bold : .regular))
                .foregroundStyle(isCurrent ? SCColor.accent : SCColor.textBody)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var confirmationCallout: some View {
        SCCallout(tone: .success, systemImage: "checkmark", cornerRadius: SCRadius.cardSmall) {
            Text("You and Rider Okafor both confirmed this session happened. Payment goes to the filmer within a couple of days.")
                .font(.system(size: 12.5))
                .lineSpacing(3)
                .foregroundStyle(SCColor.textBody)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var rateRow: some View {
        Button {} label: {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(SCColor.accent)
                Text("Rate Rider Okafor")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SCColor.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .scCard(cornerRadius: SCRadius.cardSmall, borderColor: SCColor.accent)
        }
        .buttonStyle(.plain)
    }

    private var clipTabs: some View {
        HStack(spacing: 4) {
            vaultTab(title: "Makes (\(makes.count))", isActive: showsMakes) { showsMakes = true }
            vaultTab(title: "Bails (\(bails.count))", isActive: !showsMakes) { showsMakes = false }
        }
        .padding(4)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private func vaultTab(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(SCFont.headingFixed(13))
                .foregroundStyle(isActive ? SCColor.background : SCColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(isActive ? SCColor.accent : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }

    private var clipGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(shown) { clip in
                VStack(alignment: .leading, spacing: 8) {
                    SCMediaPlaceholder(showsPlayBadge: true)
                        .aspectRatio(16.0 / 10.0, contentMode: .fit)
                        .overlay(alignment: .topLeading) {
                            SCTag(
                                text: clip.isMake ? "Make" : "Bail",
                                background: clip.isMake ? SCColor.success : SCColor.textSecondary,
                                size: 9
                            )
                            .padding(8)
                        }

                    HStack(spacing: 6) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(clip.name)
                                .font(SCFont.headingFixed(12))
                                .foregroundStyle(SCColor.textPrimary)
                            Text(clip.meta)
                                .font(.system(size: 11))
                                .foregroundStyle(SCColor.textSecondary)
                        }
                        Spacer(minLength: 0)
                        Button {} label: {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(SCColor.accent)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Download \(clip.name) at full resolution")
                    }
                }
            }
        }
    }
}

private struct VaultClip: Identifiable {
    var id: String { name }
    let name: String
    let meta: String
    let isMake: Bool
}

private extension ClipVaultScreen {
    static let clips: [VaultClip] = [
        VaultClip(name: "C0043.MP4", meta: "4K · 120fps · 0:16", isMake: true),
        VaultClip(name: "C0045.MP4", meta: "4K · 120fps · 0:14", isMake: true),
        VaultClip(name: "C0041.MP4", meta: "4K · 120fps · 0:18", isMake: false),
        VaultClip(name: "C0042.MP4", meta: "4K · 120fps · 0:22", isMake: false),
        VaultClip(name: "C0044.MP4", meta: "4K · 60fps · 0:25", isMake: false)
    ]
}

#Preview {
    ClipVaultScreen()
}
