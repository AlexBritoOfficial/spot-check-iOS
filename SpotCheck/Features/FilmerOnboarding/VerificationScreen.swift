import SwiftUI

/// The canvas's `Verification` artboard -- filmer background-check
/// status, not an auth/OTP step. The artboard is driven by a status
/// prop with two variants, so `status` carries the same two cases and
/// both are previewed.
struct VerificationScreen: View {
    enum Status {
        case inReview, passed

        var isPassed: Bool { self == .passed }
    }

    var status: Status = .inReview

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    statusBlock
                    checklist
                    serviceSection
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }

            SCFooterBar {
                if status.isPassed {
                    Button("Set rates & go live") {}
                        .buttonStyle(.scPrimary)
                } else {
                    Button("Back to the map") { dismiss() }
                        .buttonStyle(.scSecondary)
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
        }
        .padding(.horizontal, 10)
        .padding(.top, SCMetric.headerTop(52))
    }

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: status.isPassed ? "checkmark" : "clock")
                    .font(.system(size: 11, weight: .bold))
                Text(status.isPassed ? "PASSED" : "IN REVIEW")
                    .font(SCFont.headingFixed(11))
                    .tracking(0.5)
            }
            .foregroundStyle(status.isPassed ? SCColor.success : SCColor.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background((status.isPassed ? SCColor.success : SCColor.accent).opacity(0.14))
            .clipShape(Capsule())

            Text(status.isPassed ? "You're cleared to film" : "Your background check is in progress")
                .font(SCFont.heading(26))
                .foregroundStyle(SCColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(status.isPassed
                 ? "Your profile now shows a Background checked badge. Set your rates to start taking bookings."
                 : "We're also reviewing your camera and portfolio. We'll notify you when both are done.")
                .font(.system(size: 15))
                .lineSpacing(4)
                .foregroundStyle(SCColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: 18) {
            checklistRow(
                marker: .done,
                title: "ID verified",
                detail: "Government ID and selfie match"
            )
            checklistRow(
                marker: .done,
                title: "Consent signed",
                detail: "You authorized the background check"
            )
            checklistRow(
                marker: status.isPassed ? .done : .inProgress,
                title: "Gear & portfolio review",
                detail: status.isPassed
                    ? "Pro camera and portfolio approved"
                    : "Filming & photos: in review by our team",
                detailColor: status.isPassed ? SCColor.success : SCColor.accent
            )
            checklistRow(
                marker: status.isPassed ? .done : .inProgress,
                title: "Background check",
                detail: status.isPassed ? "Passed" : "In review with our screening partner",
                detailColor: status.isPassed ? SCColor.success : SCColor.accent
            )
            checklistRow(
                marker: status.isPassed ? .numbered(4) : .locked,
                title: "Set rates & go live",
                detail: status.isPassed ? "Ready when you are" : "Unlocks after your check passes"
            )
        }
        .padding(18)
        .scCard()
    }

    private enum ChecklistMarker {
        case done, inProgress, locked
        case numbered(Int)
    }

    private func checklistRow(
        marker: ChecklistMarker,
        title: String,
        detail: String,
        detailColor: Color = SCColor.textSecondary
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            markerView(marker)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SCFont.headingFixed(14))
                    .foregroundStyle(SCColor.textPrimary)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(detailColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func markerView(_ marker: ChecklistMarker) -> some View {
        switch marker {
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(SCColor.background)
                .frame(width: 26, height: 26)
                .background(SCColor.success)
                .clipShape(Circle())
        case .inProgress:
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(SCColor.accent, lineWidth: 2.5)
                .rotationEffect(.degrees(-90))
                .frame(width: 26, height: 26)
        case .locked:
            Image(systemName: "lock.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(SCColor.textSecondary)
                .frame(width: 26, height: 26)
                .overlay(Circle().stroke(SCColor.border, lineWidth: 1.5))
        case .numbered(let number):
            Text("\(number)")
                .font(SCFont.headingFixed(12))
                .foregroundStyle(SCColor.background)
                .frame(width: 26, height: 26)
                .background(SCColor.accent)
                .clipShape(Circle())
        }
    }

    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR SERVICE").scSectionLabel()
            HStack {
                Text("Filming & photos")
                    .font(SCFont.headingFixed(14))
                    .foregroundStyle(SCColor.textPrimary)
                Spacer()
                Text(status.isPassed ? "READY" : "LOCKED")
                    .font(SCFont.headingFixed(11))
                    .foregroundStyle(status.isPassed ? SCColor.success : SCColor.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .scCard(cornerRadius: SCRadius.cardSmall)
        }
    }
}

#Preview("In review") {
    VerificationScreen(status: .inReview)
}

#Preview("Passed") {
    VerificationScreen(status: .passed)
}
