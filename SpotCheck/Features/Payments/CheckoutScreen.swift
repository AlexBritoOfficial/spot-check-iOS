import SwiftUI

/// The canvas's `Checkout` artboard -- the skater reviewing a filming
/// request before confirming it.
///
/// Nothing is charged here: the canvas's own timeline says the card is
/// only saved now, charged when a filmer accepts, and released after both
/// confirm. Amounts stay the artboard's bracketed placeholders until the
/// payments schema lands; confirming is intentionally unwired pending the
/// Stripe integration.
struct CheckoutScreen: View {
    private enum Route: Hashable {
        case paymentStatus, paymentMethods
    }

    @Environment(\.dismiss) private var dismiss

    @State private var route: Route?

    /// Pushes onto the enclosing stack (FilmBooking's), rather than making
    /// its own, so the whole booking flow shares one back stack.
    var body: some View {
        content
            .toolbar(.hidden)
            .navigationDestination(item: $route) { route in
                switch route {
                case .paymentStatus: PaymentStatusScreen(status: .held)
                case .paymentMethods: PaymentMethodsScreen()
                }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Review & pay",
                subtitle: "Hourly Street Session",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    requestCard
                    priceCard
                    payWithSection
                    chargeTimeline
                    SCNoteRow(
                        text: "Payments are processed by Stripe. Cancel 24+ hours ahead for a full refund.",
                        systemImage: "lock.fill",
                        iconColor: SCColor.success
                    )
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                Button("Confirm request") { route = .paymentStatus }
                    .buttonStyle(.scPrimary(fontSize: 14.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var requestCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR REQUEST").scSectionLabel()
            SCDetailRow(label: "Where", value: "Pin near Copley Square")
            SCDetailRow(label: "When", value: "Sat, Nov 28 · 5–7 PM")
            SCDetailRow(label: "Conditions", value: "Golden hour · security sometimes")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PRICE").scSectionLabel()
            SCDetailRow(label: "Filmer rate (2 hrs)", value: "$[RATE]")
            SCDetailRow(
                label: PaymentFees.label(percent: PaymentFees.filmingSessionPercent),
                value: "$[FEE]"
            )
            SCColor.border.frame(height: 1)
            SCDetailRow(label: "Total", value: "$[TOTAL]", isTotal: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private var payWithSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SCSectionHeader("Pay with") {
                Button("Change") { route = .paymentMethods }
                    .font(.system(size: 13))
                    .foregroundStyle(SCColor.accent)
            }

            SCIconDetailRow(
                systemImage: "creditcard",
                title: "Visa •••• 4242",
                subtitle: "Expires 08/28 · default"
            ) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(SCColor.success)
            }
        }
    }

    private var chargeTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHEN YOU'RE CHARGED").scSectionLabel()
            SCTimeline(steps: [
                .init(
                    title: "Now: nothing charged",
                    detail: "Your card is saved for this request",
                    marker: .current
                ),
                .init(
                    title: "A filmer accepts",
                    detail: "$[TOTAL] is charged and held by Spot Check",
                    marker: .pending
                ),
                .init(
                    title: "You both confirm the session",
                    detail: "The filmer is paid within a couple of days",
                    marker: .pending
                )
            ])
        }
    }
}

#Preview {
    NavigationStack {
        CheckoutScreen()
    }
}
