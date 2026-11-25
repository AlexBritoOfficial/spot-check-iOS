import SwiftUI

/// Mirrors the design canvas's "FilmerRates" artboard: the last step of
/// filmer onboarding, where a filmer sets prices and marks the weekly
/// slots they're free.
///
/// The availability grid is live local state (as the canvas mockup is) —
/// the open-slot count below it is derived from the taps, and isn't saved.
///
/// Rates are on hold (Alex, 2026-11-25: "let's circle back"), so "Go live"
/// saves `FilmerRates.sample`. The two price fields show those values and
/// are locked, rather than accepting input that would be ignored.
struct FilmerRatesScreen: View {
    var isGoingLive = false
    var errorMessage: String?
    var onGoLive: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var hourlyRate = Self.dollars(FilmerRates.sample.hourlyRateCents)
    @State private var parkDropIn = Self.dollars(FilmerRates.sample.parkDropInCents)
    @State private var fullEdit = ""
    @State private var openSlots = initiallyOpenSlots

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Rates & availability",
                subtitle: "Last step · then you go live",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SCNoteRow(
                        text: "Sample rates for testing. Setting your own rates comes later.",
                        systemImage: "info.circle",
                        iconColor: SCColor.accent
                    )

                    Group {
                        hourlyField

                        HStack(alignment: .top, spacing: 10) {
                            RateField(label: "Park drop-in", placeholder: "$[PRICE]", text: $parkDropIn, keyboard: .decimalPad)
                            RateField(label: "Full edit", placeholder: "Quote on request", text: $fullEdit)
                        }
                    }
                    .disabled(true)

                    feeCard

                    availabilitySection
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                VStack(spacing: 10) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(SCColor.danger)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    Button(isGoingLive ? "Going live…" : "Go live") { onGoLive() }
                        .buttonStyle(.scPrimary(fontSize: 14.5))
                        .disabled(isGoingLive)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private static func dollars(_ cents: Int?) -> String {
        cents.map { String($0 / 100) } ?? ""
    }

    private var hourlyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hourly street session rate").scFieldLabel()

            HStack(spacing: 0) {
                Text("$")
                    .font(SCFont.headingFixed(16))
                    .foregroundStyle(SCColor.textSecondary)
                    .accessibilityHidden(true)

                ZStack(alignment: .leading) {
                    if hourlyRate.isEmpty {
                        Text("[RATE]")
                            .font(SCFont.headingFixed(16))
                            .foregroundStyle(SCColor.textSecondary)
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $hourlyRate)
                        .font(SCFont.headingFixed(16))
                        .foregroundStyle(SCColor.textPrimary)
                        .tint(SCColor.accent)
                        .keyboardType(.decimalPad)
                }
                .padding(.leading, 8)

                Text("/ hr")
                    .font(.system(size: 14))
                    .foregroundStyle(SCColor.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .scFieldContainerChrome()
        }
    }

    private var feeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            FeeRow(label: "You keep", value: "100% of your rate")
            FeeRow(label: "Skaters pay", value: "Your rate + 15% fee")
            SCNoteRow(
                text: "Charged when you accept a request, held until you both confirm the session, then paid out within a couple of days.",
                systemImage: "lock",
                iconColor: SCColor.success
            )
        }
        .padding(16)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WEEKLY AVAILABILITY")
                .scSectionLabel()
                .padding(.bottom, 0)

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Color.clear.frame(width: 44, height: 1)
                    ForEach(availabilityColumns) { column in
                        Text(column.header)
                            .font(.system(size: 11))
                            .foregroundStyle(SCColor.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 3)
                .accessibilityHidden(true)

                ForEach(availabilityDays, id: \.self) { day in
                    HStack(spacing: 6) {
                        Text(day)
                            .font(SCFont.headingFixed(11.5))
                            .foregroundStyle(SCColor.textPrimary)
                            .frame(width: 44)
                        ForEach(availabilityColumns) { column in
                            slotButton(day: day, column: column)
                        }
                    }
                }
            }

            Text("\(openSlots.count) slots open · skaters only see times you're free")
                .font(.system(size: 12.5))
                .foregroundStyle(SCColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func slotButton(day: String, column: AvailabilityColumn) -> some View {
        let key = "\(day)-\(column.key)"
        let isOpen = openSlots.contains(key)

        return Button {
            if isOpen {
                openSlots.remove(key)
            } else {
                openSlots.insert(key)
            }
        } label: {
            RoundedRectangle(cornerRadius: 8)
                .fill(isOpen ? SCColor.accent : .clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isOpen ? SCColor.accent : SCColor.border, lineWidth: 1.5)
                )
                .frame(height: 36)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day) \(column.spoken)")
        .accessibilityAddTraits(isOpen ? [.isSelected, .isButton] : .isButton)
    }
}

/// The canvas's sentence-case variant of the filled 52pt input (the
/// shared `SCTextField` uppercases its label, which these don't).
private struct RateField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).scFieldLabel()

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(SCFont.headingFixed(15))
                        .foregroundStyle(SCColor.textSecondary)
                        .padding(.horizontal, 16)
                        .allowsHitTesting(false)
                }
                TextField("", text: $text)
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
                    .scTextFieldTextStyle()
            }
            .scFieldContainerChrome()
        }
    }
}

private struct FeeRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
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

private struct AvailabilityColumn: Identifiable {
    var id: String { key }
    let key: String
    let header: String
    let spoken: String
}

private let availabilityDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

private let availabilityColumns: [AvailabilityColumn] = [
    .init(key: "am", header: "AM", spoken: "morning"),
    .init(key: "midday", header: "MIDDAY", spoken: "midday"),
    .init(key: "eve", header: "EVE", spoken: "evening"),
    .init(key: "night", header: "NIGHT", spoken: "night")
]

private let initiallyOpenSlots: Set<String> = [
    "Mon-eve", "Tue-eve", "Wed-eve", "Fri-eve", "Fri-night",
    "Sat-am", "Sat-midday", "Sat-eve", "Sun-midday"
]

#Preview {
    FilmerRatesScreen()
        .background(SCColor.background)
}
