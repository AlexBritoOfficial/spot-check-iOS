import SwiftUI

/// The canvas's `PaymentMethods` artboard -- picking a saved method, or
/// adding a card.
///
/// IMPORTANT: the "add a card" fields below are the artboard's layout
/// only. They are local view state, bound to nothing, and must stay that
/// way: the canvas's own note says card details go straight to Stripe and
/// that Spot Check never stores a full card number. When Stripe lands,
/// this block is replaced by Stripe's own card input (which renders its
/// own fields so the PAN never touches our process) -- raw card numbers
/// must never be sent to our backend.
struct PaymentMethodsScreen: View {
    private enum Method: String, CaseIterable, Identifiable {
        case applePay, visa

        var id: Self { self }

        var title: String {
            switch self {
            case .applePay: "Apple Pay"
            case .visa: "Visa •••• 4242"
            }
        }

        var subtitle: String {
            switch self {
            case .applePay: "Confirm with Face ID"
            case .visa: "Expires 08/28"
            }
        }

        var isDefault: Bool { self == .visa }
    }

    var onUseSelected: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var selected: Method = .visa
    @State private var cardNumber = ""
    @State private var expiry = ""
    @State private var cvc = ""
    @State private var zip = ""

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(title: "Payment methods", onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    savedSection
                    addCardSection
                    SCNoteRow(
                        text: "Card details go straight to Stripe. Spot Check never stores your full card number.",
                        systemImage: "lock.fill",
                        iconColor: SCColor.success
                    )
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                Button("Use selected method", action: onUseSelected)
                    .buttonStyle(.scPrimary(fontSize: 14.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
        .toolbar(.hidden)
    }

    private var savedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SAVED").scSectionLabel()
            ForEach(Method.allCases) { method in
                methodRow(method)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Saved payment methods")
    }

    private func methodRow(_ method: Method) -> some View {
        let isActive = method == selected
        return Button {
            selected = method
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .strokeBorder(
                        isActive ? SCColor.accent : SCColor.textSecondary,
                        lineWidth: isActive ? 6 : 2
                    )
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(method.title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(SCColor.textPrimary)
                    Text(method.subtitle)
                        .font(.system(size: 12.5))
                        .foregroundStyle(SCColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if method.isDefault {
                    Text("DEFAULT")
                        .font(SCFont.headingFixed(10.5))
                        .foregroundStyle(SCColor.accent)
                }
            }
            .padding(14)
            .scCard(
                cornerRadius: SCRadius.cardSmall,
                borderColor: isActive ? SCColor.accent : SCColor.border,
                borderWidth: 2
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }

    private var addCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ADD A CARD").scSectionLabel()

            SCTextField(
                label: "Card number",
                placeholder: "1234 5678 9012 3456",
                text: $cardNumber,
                contentType: .creditCardNumber,
                keyboard: .numberPad
            )

            HStack(alignment: .top, spacing: 10) {
                SCTextField(
                    label: "Expiry",
                    placeholder: "MM/YY",
                    text: $expiry,
                    keyboard: .numberPad
                )
                SCTextField(
                    label: "CVC",
                    placeholder: "123",
                    text: $cvc,
                    keyboard: .numberPad
                )
                SCTextField(
                    label: "ZIP",
                    placeholder: "02116",
                    text: $zip,
                    contentType: .postalCode,
                    keyboard: .numberPad
                )
            }

            Button("Save card") {}
                .buttonStyle(.scSecondary(fontSize: 13.5))
        }
    }
}

#Preview {
    PaymentMethodsScreen()
}
