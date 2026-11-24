import SwiftUI

/// The canvas's `ProRequest` artboard -- a skater paying a pro for
/// feedback. The reply-type tray drives the footer's label, as on the
/// artboard; prices stay bracketed placeholders and paying is
/// intentionally unwired pending per-feature planning.
struct ProRequestScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var replyKind = 0
    @State private var question = ""

    private var footerLabel: String {
        switch replyKind {
        case 0: "Pay & send question"
        case 1: "Pay & request video"
        default: "Request coaching"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(title: "Ask a pro", onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    proCard
                    replyKindTray

                    VStack(alignment: .leading, spacing: 8) {
                        Text("WHAT DO YOU WANT HELP WITH?").scFieldLabel()
                        SCTextArea(
                            placeholder: "e.g. My kickflips keep flipping late. What am I doing wrong?",
                            text: $question,
                            rows: 4,
                            accessibilityTitle: "What do you want help with?"
                        )
                    }

                    attachClipButton
                    priceCard
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                Button(footerLabel) {}
                    .buttonStyle(.scPrimary(fontSize: 14.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var proCard: some View {
        HStack(spacing: 14) {
            Avatar(
                initial: "C",
                size: 56,
                backgroundColor: SCColor.border,
                foregroundColor: SCColor.textPrimary
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Rider Chen")
                        .font(SCFont.headingFixed(16))
                        .foregroundStyle(SCColor.textPrimary)
                    SCTag(text: "Pro")
                }
                Text("Pro skater · replies within 3 days")
                    .font(.system(size: 13))
                    .foregroundStyle(SCColor.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .scCard()
    }

    private var replyKindTray: some View {
        SCSegmentedTray(
            options: [
                .init(label: "Text answer", caption: "$[PRICE]"),
                .init(label: "Video breakdown", caption: "$[PRICE]"),
                .init(label: "Coaching", caption: "$[RATE]/hr")
            ],
            selection: $replyKind
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Reply type")
    }

    private var attachClipButton: some View {
        Button {} label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SCColor.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Attach a clip")
                        .font(SCFont.headingFixed(13))
                        .foregroundStyle(SCColor.textPrimary)
                    Text("From your vault or camera roll")
                        .font(.system(size: 12))
                        .foregroundStyle(SCColor.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(height: 56)
            .overlay(
                RoundedRectangle(cornerRadius: SCRadius.cardSmall)
                    .strokeBorder(
                        SCColor.textSecondary,
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Price").foregroundStyle(SCColor.textBody)
                Spacer()
                Text("$[PRICE]").fontWeight(.semibold).foregroundStyle(SCColor.textPrimary)
            }
            .font(.system(size: 14))

            HStack {
                Text("Reply due by").foregroundStyle(SCColor.textBody)
                Spacer()
                Text("Mon, Nov 23").fontWeight(.semibold).foregroundStyle(SCColor.textPrimary)
            }
            .font(.system(size: 14))

            SCColor.border.frame(height: 1)

            SCNoteRow(
                text: "No reply by then? You're refunded automatically.",
                systemImage: "clock",
                iconColor: SCColor.success
            )
        }
        .padding(16)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }
}

#Preview {
    ProRequestScreen()
}
