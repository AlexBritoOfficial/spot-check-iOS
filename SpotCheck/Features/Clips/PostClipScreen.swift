import SwiftUI

/// The canvas's `PostClip` artboard, reached from the raised button in
/// `SCBottomNavBar`. Posting itself is unwired pending per-feature
/// planning; `onAddSpot` is wired, because the canvas moved the
/// add-a-spot entry point here off the map.
struct PostClipScreen: View {
    var onAddSpot: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var caption = ""
    @State private var visibility = 0
    @State private var hasSpotTag = true
    @State private var entersChallenge = true

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Post a clip",
                subtitle: "Ready in a few taps",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    captionRow
                    spotTagSection
                    visibilitySection
                    creditCard
                    SCNoteRow(text: "Music must be licensed or muted. Unlicensed audio is muted on upload.")

                    Button("Or add a new spot instead", action: onAddSpot)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(SCColor.accent)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                Button("Post") { dismiss() }
                    .buttonStyle(.scPrimary(fontSize: 14.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var captionRow: some View {
        HStack(alignment: .top, spacing: 12) {
            SCMediaPlaceholder(showsPlayBadge: true)
                .aspectRatio(4.0 / 5.0, contentMode: .fit)
                .frame(width: 112)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("CAPTION").scFieldLabel()
                SCTextArea(placeholder: "What did you land?", text: $caption, rows: 4)
                Text("C0043.MP4 · 0:16 · from your vault")
                    .font(.system(size: 12))
                    .foregroundStyle(SCColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var spotTagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SPOT TAG (OPTIONAL)").scSectionLabel()

            if hasSpotTag {
                HStack(spacing: 10) {
                    SCPinGlyph(height: 13)
                    Text("Eggs")
                        .font(SCFont.headingFixed(14))
                        .foregroundStyle(SCColor.textPrimary)
                    Spacer()
                    Button {
                        hasSpotTag = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(SCColor.textSecondary)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove spot tag")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .scCard(cornerRadius: SCRadius.cardSmall)
            }

            SCNoteRow(
                text: "Only verified members see spot tags. We strip GPS and location data from every upload.",
                systemImage: "lock.fill",
                iconColor: SCColor.success
            )
        }
    }

    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHO CAN SEE IT").scSectionLabel()
            SCSegmentedTray(
                options: [
                    .init(label: "Public", caption: "Members can watch"),
                    .init(label: "Private", caption: "Only people you invite")
                ],
                selection: $visibility
            )
        }
    }

    private var creditCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Filmer credit")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SCColor.textPrimary)
                    Text("Links viewers to book them")
                        .font(.system(size: 12.5))
                        .foregroundStyle(SCColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Avatar(
                        initial: "O",
                        size: 22,
                        backgroundColor: SCColor.border,
                        foregroundColor: SCColor.textPrimary
                    )
                    Text("Rider Okafor")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SCColor.textPrimary)
                }
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(SCColor.border)
                .clipShape(Capsule())
            }

            SCColor.border.frame(height: 1)

            SCToggleRow(
                title: "Enter Flip In, Flip Out",
                caption: "November challenge · free entry",
                isOn: $entersChallenge
            )
        }
        .padding(16)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }
}

#Preview {
    PostClipScreen()
}
