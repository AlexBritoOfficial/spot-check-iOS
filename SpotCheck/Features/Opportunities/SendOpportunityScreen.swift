import SwiftUI

/// The canvas's `SendOpportunity` artboard -- an industry account
/// composing an offer to a skater. Type selection and the fields are
/// local view state; sending is intentionally unwired pending
/// per-feature planning.
struct SendOpportunityScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType = "Shop sponsorship"
    @State private var message = ""
    @State private var offering = ""

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Send an opportunity",
                subtitle: "To Rider Silva",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    typeSection

                    VStack(alignment: .leading, spacing: 8) {
                        Text("MESSAGE").scFieldLabel()
                        SCTextArea(
                            placeholder: "Why you're reaching out",
                            text: $message,
                            rows: 4,
                            accessibilityTitle: "Message"
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SCTextField(
                            label: "What you are offering",
                            placeholder: "e.g. 20% off gear, rep the shop at events",
                            text: $offering
                        )
                    }

                    notesCard
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                Button("Send to Rider Silva") { dismiss() }
                    .buttonStyle(.scPrimary(fontSize: 14.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TYPE").scSectionLabel()
            FlowChips(spacing: 8) {
                ForEach(SendOpportunityScreen.types, id: \.self) { type in
                    let isActive = type == selectedType
                    Button {
                        selectedType = type
                    } label: {
                        Text(type.uppercased())
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

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SCNoteRow(
                text: "Rider Silva can accept or decline. If they accept, we check in with both of you at 30 and 90 days.",
                systemImage: "clock",
                iconColor: SCColor.success
            )
            SCNoteRow(
                text: "Spot Check passes the offer along; any contract or pay is between you and the skater."
            )
        }
        .padding(16)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }
}

private extension SendOpportunityScreen {
    static let types = [
        "Shop sponsorship",
        "Flow",
        "Am team",
        "Pro",
        "Tryout",
        "Filming",
        "Event"
    ]
}

#Preview {
    SendOpportunityScreen()
}
