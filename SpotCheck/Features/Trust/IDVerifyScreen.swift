import SwiftUI

/// The canvas's `IDVerify` artboard -- the 18+ ID and age check that
/// gates booking and payouts. Starting verification is intentionally
/// unwired pending per-feature planning.
struct IDVerifyScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Verify your age and ID",
                subtitle: "Spot Check is 18+",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Everyone who books, pays or gets paid verifies once. It takes about two minutes.")
                        .font(.system(size: 15))
                        .lineSpacing(4)
                        .foregroundStyle(SCColor.textBody)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        stepCard(
                            systemImage: "person.text.rectangle",
                            title: "1. Scan a photo ID",
                            detail: "Driver's license, state ID or passport"
                        )
                        stepCard(
                            systemImage: "person.crop.circle",
                            title: "2. Take a quick selfie",
                            detail: "Matched to your ID photo"
                        )
                    }

                    SCNoteRow(
                        text: "Checks run through our verification partner. Spot Check only keeps your verified status and age.",
                        systemImage: "lock.fill",
                        iconColor: SCColor.success
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("WITHOUT IT YOU CAN").scSectionLabel()
                        Text("Browse spots, watch clips and chat. Booking, paying and getting paid need verification.")
                            .font(.system(size: 14))
                            .lineSpacing(4)
                            .foregroundStyle(SCColor.textBody)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scCard(cornerRadius: SCRadius.cardSmall)
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                VStack(spacing: 10) {
                    Button("Start verification") {}
                        .buttonStyle(.scPrimary(fontSize: 14.5))
                    Button("Skip for now") { dismiss() }
                        .buttonStyle(.scSecondary(fontSize: 14.5))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private func stepCard(systemImage: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 20))
                .foregroundStyle(SCColor.accent)
                .frame(width: 44, height: 44)
                .background(SCColor.accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                Text(detail)
                    .font(.system(size: 12.5))
                    .foregroundStyle(SCColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }
}

#Preview {
    IDVerifyScreen()
}
