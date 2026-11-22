import SwiftUI

/// The canvas's `ProReply` artboard -- the pro's side of a paid
/// request. The artboard is driven by a status prop with two variants,
/// so `status` carries the same two cases: an open request with the
/// reply composer, or a closed window with no composer or footer.
struct ProReplyScreen: View {
    enum Status {
        case open, missedWindow
    }

    var status: Status = .open

    @Environment(\.dismiss) private var dismiss

    @State private var reply = ""

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Request from Rider Silva",
                subtitle: "Video breakdown",
                onBack: { dismiss() }
            )

            banner
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    question

                    if status == .open {
                        replySection
                    }
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            if status == .open {
                SCFooterBar {
                    Button("Send reply") {}
                        .buttonStyle(.scPrimary(fontSize: 14.5))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    @ViewBuilder
    private var banner: some View {
        switch status {
        case .open:
            HStack(spacing: 10) {
                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SCColor.accent)
                Group {
                    Text("Reply due in 3 days").bold()
                        + Text(" · Mon, Nov 23")
                }
                .font(.system(size: 13))
                .foregroundStyle(SCColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .scCard(
                cornerRadius: SCRadius.control,
                fill: SCColor.accent.opacity(0.12),
                borderColor: SCColor.accent.opacity(0.4)
            )
        case .missedWindow:
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SCColor.danger)
                Group {
                    Text("Reply window closed.").bold()
                        + Text(" Rider Silva was refunded automatically.")
                }
                .font(.system(size: 13))
                .lineSpacing(3)
                .foregroundStyle(SCColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .scCard(
                cornerRadius: SCRadius.control,
                fill: SCColor.danger.opacity(0.12),
                borderColor: SCColor.danger.opacity(0.45)
            )
        }
    }

    private var question: some View {
        HStack(alignment: .top, spacing: 12) {
            Avatar(
                initial: "S",
                size: 40,
                backgroundColor: SCColor.border,
                foregroundColor: SCColor.textPrimary
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("My kickflips keep flipping late on the Eggs ledge run-up. What am I doing wrong?")
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .foregroundStyle(SCColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(SCColor.surface)
                    .overlay(
                        UnevenRoundedRectangle(
                            cornerRadii: .init(
                                topLeading: 6,
                                bottomLeading: 16,
                                bottomTrailing: 16,
                                topTrailing: 16
                            )
                        )
                        .stroke(SCColor.border, lineWidth: 1)
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            cornerRadii: .init(
                                topLeading: 6,
                                bottomLeading: 16,
                                bottomTrailing: 16,
                                topTrailing: 16
                            )
                        )
                    )

                SCMediaPlaceholder(showsPlayBadge: true)
                    .aspectRatio(16.0 / 10.0, contentMode: .fit)
                    .accessibilityHidden(true)

                Text("C0043.MP4 · 0:16 · attached from vault")
                    .font(.system(size: 12))
                    .foregroundStyle(SCColor.textSecondary)
            }
        }
    }

    private var replySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR REPLY").scSectionLabel()

            Button {} label: {
                HStack(spacing: 10) {
                    Image(systemName: "record.circle")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Record video reply")
                        .font(SCFont.headingFixed(14))
                }
                .foregroundStyle(SCColor.background)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(SCColor.accent)
                .clipShape(RoundedRectangle(cornerRadius: SCRadius.cardSmall))
            }
            .buttonStyle(.plain)

            SCTextArea(
                placeholder: "Or type a text reply",
                text: $reply,
                accessibilityTitle: "Text reply"
            )

            payoutCard
        }
    }

    private var payoutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            payoutRow(label: "Skater paid", value: "$[PRICE]")
            payoutRow(label: "Spot Check fee (20%)", value: "−$[FEE]")
            SCColor.border.frame(height: 1)
            HStack {
                Text("You earn")
                    .fontWeight(.bold)
                    .foregroundStyle(SCColor.textPrimary)
                Spacer()
                Text("$[PAYOUT]")
                    .fontWeight(.semibold)
                    .foregroundStyle(SCColor.textPrimary)
            }
            .font(.system(size: 14))

            SCNoteRow(
                text: "Released as soon as you send your reply.",
                systemImage: "lock.fill",
                iconColor: SCColor.success
            )
        }
        .padding(16)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private func payoutRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(SCColor.textBody)
            Spacer()
            Text(value).fontWeight(.semibold).foregroundStyle(SCColor.textPrimary)
        }
        .font(.system(size: 14))
    }
}

#Preview("Open") {
    ProReplyScreen(status: .open)
}

#Preview("Missed window") {
    ProReplyScreen(status: .missedWindow)
}
