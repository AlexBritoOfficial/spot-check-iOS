import SwiftUI

/// The canvas's `BustLog` artboard -- the quick post-session log that
/// feeds a spot's bust rate. The bust choice, duration chips and star
/// rating are local view state, as on the artboard; saving is
/// intentionally unwired pending per-feature planning.
struct BustLogScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var gotBusted = false
    @State private var duration = "15–60 min"
    @State private var rating = 4

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Log a session",
                subtitle: "Under 30 seconds",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    spotRow
                    bustChoice

                    if gotBusted {
                        durationSection
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("RATE THE SPOT TODAY").scSectionLabel()
                        SCStarPicker(rating: $rating, accessibilityTitle: "Spot rating")
                    }

                    SCNoteRow(text: "Logs are anonymous and feed the bust rate on the spot page.")
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                Button("Save log") { dismiss() }
                    .buttonStyle(.scPrimary(fontSize: 14.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var spotRow: some View {
        HStack(spacing: 12) {
            SCPinGlyph(height: 29, showsHole: true, strokeColor: SCColor.background)

            VStack(alignment: .leading, spacing: 2) {
                Text("Eggs")
                    .font(SCFont.headingFixed(15))
                    .foregroundStyle(SCColor.textPrimary)
                Text("You're here · logged Fri, 5:42 PM")
                    .font(.system(size: 12.5))
                    .foregroundStyle(SCColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {} label: {
                Text("Change")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(SCColor.border, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private var bustChoice: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DID YOU GET BUSTED?").scSectionLabel()

            HStack(spacing: 10) {
                choiceTile(
                    title: "No bust",
                    caption: "Skated it clean",
                    tone: SCColor.success,
                    isSelected: !gotBusted
                ) {
                    gotBusted = false
                }

                choiceTile(
                    title: "Got busted",
                    caption: "Security or police",
                    tone: SCColor.danger,
                    isSelected: gotBusted
                ) {
                    gotBusted = true
                }
            }
        }
    }

    private func choiceTile(
        title: String,
        caption: String,
        tone: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(SCFont.headingFixed(16))
                Text(caption)
                    .font(.system(size: 12.5))
                    .opacity(0.8)
            }
            .foregroundStyle(isSelected ? tone : SCColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .scCard(
                fill: isSelected ? tone.opacity(0.15) : SCColor.surface,
                borderColor: isSelected ? tone : SCColor.border,
                borderWidth: 2
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOW LONG DID YOU GET?").scSectionLabel()
            FlowChips(spacing: 8) {
                ForEach(["Under 15 min", "15–60 min", "Over an hour"], id: \.self) { option in
                    let isActive = option == duration
                    Button {
                        duration = option
                    } label: {
                        Text(option.uppercased())
                            .font(SCFont.headingFixed(11.5))
                            .foregroundStyle(isActive ? SCColor.background : SCColor.textPrimary)
                            .padding(.horizontal, 14)
                            .frame(height: 40)
                            .background(isActive ? SCColor.accent : .clear)
                            .overlay(
                                Capsule().stroke(isActive ? SCColor.accent : SCColor.border, lineWidth: 1.5)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
                }
            }
        }
    }
}

#Preview {
    BustLogScreen()
}
