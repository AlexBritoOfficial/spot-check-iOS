import SwiftUI

/// The canvas's `FilmerQualify` artboard -- step 2 of filmer onboarding,
/// after the ID check. "Submit for review" sends the application through
/// FilmerOnboardingFlow.
///
/// The two reel rows are sample clips for now (Alex: "use dummy data"):
/// there is no video picker yet. The consent row is not on the canvas, which
/// draws "Consent signed" on Verification but never where it's given.
struct FilmerQualifyScreen: View {
    let flow: FilmerOnboardingFlow
    var userID: UUID?
    var onSubmitted: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var draft = FilmerApplicationDraft()

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    intro
                    gearSection
                    reelsSection
                    styleSection
                    consentSection
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                VStack(spacing: 10) {
                    if let message = flow.errorMessage {
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundStyle(SCColor.danger)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    Button(flow.isSubmitting ? "Submitting…" : "Submit for review") { submit() }
                        .buttonStyle(.scPrimary)
                        .disabled(!draft.canSubmit || flow.isSubmitting || userID == nil)
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

            Text("Step 2 of 4")
                .font(.system(size: 13))
                .foregroundStyle(SCColor.textSecondary)
                .padding(.trailing, 14)
        }
        .padding(.horizontal, 10)
        .padding(.top, SCMetric.headerTop(52))
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prove you can keep up")
                .font(SCFont.heading(26))
                .foregroundStyle(SCColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Skaters book filmers who can hold a line at speed and never miss the landing. Show us your rig and your raw footage.")
                .font(.system(size: 15))
                .lineSpacing(4)
                .foregroundStyle(SCColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var gearSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("GEAR & RIG").scSectionLabel()
                Text("Select everything you own. Phones don't count.")
                    .font(.system(size: 13))
                    .foregroundStyle(SCColor.textSecondary)
            }

            FlowChips(spacing: 8) {
                ForEach(FilmerApplicationDraft.gearOptions, id: \.self) { option in
                    qualifyChip(option, in: $draft.gear)
                }
            }
        }
    }

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FILMING STYLE").scSectionLabel()
            FlowChips(spacing: 8) {
                ForEach(FilmerApplicationDraft.styleOptions, id: \.self) { option in
                    qualifyChip(option, in: $draft.styles)
                }
            }
        }
    }

    private var reelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DEMO REELS").scSectionLabel()

            sampleClipRow(title: "Edited highlight reel")
            sampleClipRow(title: "Raw follow-line clip")
        }
    }

    /// A clip that is already "attached": the sample file the application
    /// sends until there's a video picker.
    private func sampleClipRow(title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SCColor.background)
                .frame(width: 44, height: 44)
                .background(SCColor.success)
                .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(SCFont.headingFixed(14))
                    .foregroundStyle(SCColor.textPrimary)
                Text("Sample clip (testing)")
                    .font(.system(size: 12.5))
                    .foregroundStyle(SCColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .scCard(cornerRadius: SCRadius.cardSmall)
        .accessibilityElement(children: .combine)
    }

    private var consentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BACKGROUND CHECK").scSectionLabel()
            SCToggleRow(
                title: "I authorize a background check",
                caption: "Required to film. Your services stay hidden until it clears.",
                isOn: $draft.consentsToBackgroundCheck
            )
            .padding(16)
            .scCard(cornerRadius: SCRadius.cardSmall)
        }
    }

    private func submit() {
        guard let userID else { return }
        Task {
            if await flow.submit(draft, userID: userID) { onSubmitted() }
        }
    }

    private func qualifyChip(_ label: String, in selection: Binding<Set<String>>) -> some View {
        let isActive = selection.wrappedValue.contains(label)
        return Button {
            if isActive {
                selection.wrappedValue.remove(label)
            } else {
                selection.wrappedValue.insert(label)
            }
        } label: {
            Text(label.uppercased())
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

#Preview {
    FilmerQualifyScreen(flow: FilmerOnboardingFlow())
}
