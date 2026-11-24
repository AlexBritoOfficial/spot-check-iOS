import SwiftUI

/// The canvas's `FilmerQualify` artboard -- step 1 of filmer
/// onboarding. Chip selections are local view state; the upload rows
/// are presentation only, with no picker attached, pending per-feature
/// planning.
struct FilmerQualifyScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedGear: Set<String> = [
        "VX1000 / tapeless",
        "DSLR/mirrorless + fisheye",
        "External shotgun mic",
        "Filmer cruiser board"
    ]
    @State private var selectedStyles: Set<String> = [
        "Street follow-lines",
        "Night / external lighting"
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    intro
                    gearSection
                    reelsSection
                    styleSection
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                Button("Submit for review") {}
                    .buttonStyle(.scPrimary)
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

            Text("Step 1 of 4")
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
                ForEach(FilmerQualifyScreen.gearOptions, id: \.self) { option in
                    qualifyChip(option, in: $selectedGear)
                }
            }
        }
    }

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FILMING STYLE").scSectionLabel()
            FlowChips(spacing: 8) {
                ForEach(FilmerQualifyScreen.styleOptions, id: \.self) { option in
                    qualifyChip(option, in: $selectedStyles)
                }
            }
        }
    }

    private var reelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DEMO REELS").scSectionLabel()

            Button {} label: {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(SCColor.background)
                        .frame(width: 44, height: 44)
                        .background(SCColor.success)
                        .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Edited highlight reel")
                            .font(SCFont.headingFixed(14))
                            .foregroundStyle(SCColor.textPrimary)
                        Text("okafor_reel_2026.mp4 · 2:14")
                            .font(.system(size: 12.5))
                            .foregroundStyle(SCColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .scCard(cornerRadius: SCRadius.cardSmall)
            }
            .buttonStyle(.plain)

            Button {} label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 14) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(SCColor.accent)
                            .frame(width: 44, height: 44)
                            .background(SCColor.border)
                            .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("+ Raw follow-line clip")
                                .font(SCFont.headingFixed(14))
                                .foregroundStyle(SCColor.textPrimary)
                            Text("Required · 30–60 sec · unedited")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(SCColor.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text("No cuts, stabilization or speed ramps. It shows you can hold a steady frame at speed.")
                        .font(.system(size: 12.5))
                        .lineSpacing(3)
                        .foregroundStyle(SCColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SCColor.accent.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: SCRadius.cardSmall)
                        .strokeBorder(
                            SCColor.accent,
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: SCRadius.cardSmall))
            }
            .buttonStyle(.plain)
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

private extension FilmerQualifyScreen {
    static let gearOptions = [
        "VX1000 / tapeless",
        "DSLR/mirrorless + fisheye",
        "Long lens (telephoto)",
        "External shotgun mic",
        "Filmer cruiser board"
    ]

    static let styleOptions = [
        "Street follow-lines",
        "Park / transition",
        "Night / external lighting",
        "Quick social clips"
    ]
}

#Preview {
    FilmerQualifyScreen()
}
