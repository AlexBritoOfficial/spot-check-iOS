import SwiftUI

/// The canvas's `Report` artboard. It's drawn as a bottom sheet over
/// the conversation rather than a pushed screen, so this is meant to be
/// presented with `.sheet` -- the grabber and rounded top come from the
/// presentation itself. Sending is intentionally unwired pending
/// per-feature planning.
struct ReportScreen: View {
    var subjectName: String = "Rider Silva"

    @Environment(\.dismiss) private var dismiss

    @State private var reason = "No-show or payment scam"
    @State private var details = ""
    @State private var alsoBlock = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Report \(subjectName)")
                    .font(SCFont.heading(20))
                    .foregroundStyle(SCColor.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SCColor.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(.leading, SCMetric.screenPadding)
            .padding(.trailing, 12)
            .padding(.top, 14)
            .padding(.bottom, 6)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    reasonSection

                    VStack(alignment: .leading, spacing: 8) {
                        Text("DETAILS (OPTIONAL)").scFieldLabel()
                        SCTextArea(
                            placeholder: "Tell the team what happened",
                            text: $details,
                            rows: 2,
                            accessibilityTitle: "Details"
                        )
                    }

                    blockRow

                    SCNoteRow(
                        text: "Reports go to the Spot Check team. \(subjectName) won't see who reported them.",
                        systemImage: "lock.fill"
                    )
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }

            SCFooterBar {
                Button("Send report") { dismiss() }
                    .buttonStyle(.scPrimary(fontSize: 14.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHAT HAPPENED?")
                .scSectionLabel()
                .padding(.bottom, 2)

            ForEach(ReportScreen.reasons, id: \.self) { option in
                let isSelected = option == reason
                Button {
                    reason = option
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                            .font(.system(size: 19))
                            .foregroundStyle(isSelected ? SCColor.accent : SCColor.textSecondary)
                        Text(option)
                            .font(.system(size: 15))
                            .foregroundStyle(SCColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: SCRadius.control)
                            .stroke(isSelected ? SCColor.accent : SCColor.border, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
    }

    private var blockRow: some View {
        SCToggleRow(
            title: "Also block \(subjectName)",
            caption: "They won't be able to message you or request sessions with you.",
            isOn: $alsoBlock
        )
        .padding(14)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }
}

private extension ReportScreen {
    static let reasons = [
        "Harassment or threats",
        "No-show or payment scam",
        "Unsafe behavior at a session",
        "Spam or fake profile",
        "Something else"
    ]
}

#Preview {
    ReportScreen()
}
