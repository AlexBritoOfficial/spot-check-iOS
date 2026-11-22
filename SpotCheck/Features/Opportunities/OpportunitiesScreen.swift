import SwiftUI

/// Mirrors the design canvas's "Opportunities" artboard: a skater's
/// inbound offers from verified shops and brands.
///
/// The first card carries the canvas's three-way variant -- open,
/// accepted, declined -- which Accept/Decline flip locally; the
/// initializer takes a starting variant so each one can be previewed.
/// Nothing beyond that local state is wired up, pending per-feature
/// planning.
struct OpportunitiesScreen: View {
    enum OfferState {
        case open, accepted, declined
    }

    @Environment(\.dismiss) private var dismiss

    @State private var offerState: OfferState
    @State private var checkInResponse: String? = nil

    init(offerState: OfferState = .open) {
        _offerState = State(initialValue: offerState)
    }

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Opportunities",
                subtitle: "From verified shops and brands",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    flowOfferCard

                    shopSponsorCard

                    SCNoteRow(
                        text: "Spot Check helps shops and brands find you. It doesn't decide who gets sponsored."
                    )
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var flowOfferCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            senderRow(initial: "L", name: "Low Tide Wheels", meta: "Brand · sent today") {
                SCTag(text: "Flow")
            }

            Text("Saw your Flip In, Flip Out entry. We'd like to send you product and see how it goes.")
                .font(.system(size: 14.5))
                .lineSpacing(4)
                .foregroundStyle(SCColor.textBody)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                detailRow(label: "Offering", value: "Free wheels each season")
                detailRow(label: "Contract or pay", value: "None")
            }
            .padding(12)
            .scCard(cornerRadius: SCRadius.cardSmall, fill: SCColor.background)

            switch offerState {
            case .open:
                decisionButtons
            case .accepted:
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .heavy))
                    Text("Accepted · we'll check in at 30 and 90 days")
                        .font(.system(size: 13, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(SCColor.success)
            case .declined:
                Text("Declined · Low Tide Wheels was told politely")
                    .font(.system(size: 13))
                    .foregroundStyle(SCColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .scCard(
            borderColor: offerState == .accepted ? SCColor.success : SCColor.accent,
            borderWidth: 1.5
        )
    }

    private var shopSponsorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            senderRow(initial: "B", name: "Bricktown Skate Shop", meta: "Shop · accepted Oct 22") {
                SCTag(
                    text: "Shop sponsor",
                    foreground: SCColor.textPrimary,
                    background: SCColor.border
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("30-day check-in: how's it going?")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                FlowChips {
                    ForEach(checkInOptions, id: \.self) { option in
                        TintedChip(label: option, isSelected: checkInResponse == option) {
                            checkInResponse = checkInResponse == option ? nil : option
                        }
                    }
                }
            }
            .padding(12)
            .scCard(
                cornerRadius: SCRadius.control,
                fill: SCColor.accent.opacity(0.1),
                borderColor: SCColor.accent.opacity(0.4)
            )
        }
        .padding(16)
        .scCard()
    }

    private var decisionButtons: some View {
        GeometryReader { proxy in
            let unit = (proxy.size.width - 8) / 2.4
            HStack(spacing: 8) {
                Button {
                    offerState = .accepted
                } label: {
                    Text("Accept")
                        .font(SCFont.headingFixed(13.5))
                        .foregroundStyle(SCColor.background)
                        .frame(width: unit * 1.4, height: 46)
                        .background(SCColor.accent)
                        .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))
                }
                .buttonStyle(.plain)

                Button {
                    offerState = .declined
                } label: {
                    Text("Decline")
                        .font(SCFont.headingFixed(13.5))
                        .foregroundStyle(SCColor.textPrimary)
                        .frame(width: unit, height: 46)
                        .overlay(
                            RoundedRectangle(cornerRadius: SCRadius.control)
                                .stroke(SCColor.border, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 46)
    }

    private func senderRow<Tag: View>(
        initial: String,
        name: String,
        meta: String,
        @ViewBuilder tag: () -> Tag
    ) -> some View {
        HStack(spacing: 12) {
            Avatar(
                initial: initial,
                size: 44,
                backgroundColor: SCColor.border,
                foregroundColor: SCColor.textPrimary
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SCColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(SCColor.success)
                        .accessibilityLabel("Verified")
                }
                Text(meta)
                    .font(.system(size: 12.5))
                    .foregroundStyle(SCColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            tag()
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(SCColor.textBody)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SCColor.textPrimary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The canvas's 36pt chip sitting on a tinted block: `Chip` is the same
/// size but fills its unselected state with the screen background,
/// which would punch a dark hole in the gold check-in tint.
private struct TintedChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(SCFont.headingFixed(11.5))
                .foregroundStyle(isSelected ? SCColor.background : SCColor.textPrimary)
                .padding(.horizontal, 14)
                .frame(height: SCMetric.chipHeight)
                .background(isSelected ? SCColor.accent : .clear)
                .overlay(
                    Capsule().stroke(isSelected ? SCColor.accent : SCColor.border, lineWidth: 1.5)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

private let checkInOptions = ["Going well", "Slow start", "Ended"]

#Preview("Open") {
    OpportunitiesScreen()
}

#Preview("Accepted") {
    OpportunitiesScreen(offerState: .accepted)
}

#Preview("Declined") {
    OpportunitiesScreen(offerState: .declined)
}
