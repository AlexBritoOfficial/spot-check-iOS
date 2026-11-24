import SwiftUI

/// The canvas's `TransactionDetail` artboard -- the receipt for one
/// payment.
///
/// The STATUS timeline is a record of what happened, so it belongs to the
/// payment's own event history rather than being derived from a single
/// current state. Amounts and the receipt number stay the artboard's
/// bracketed placeholders pending the payments schema.
struct TransactionDetailScreen: View {
    var onGetHelp: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Receipt",
                subtitle: "SC-[RECEIPT #]",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    statusSection
                    breakdownCard
                    actionRows
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
        .toolbar(.hidden)
    }

    private var hero: some View {
        VStack(spacing: 8) {
            Text("$[TOTAL]")
                .font(SCFont.heading(40))
                .foregroundStyle(SCColor.textPrimary)

            Text("HELD")
                .font(SCFont.headingFixed(11))
                .tracking(0.5)
                .foregroundStyle(SCColor.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(SCColor.accent.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: SCRadius.cardSmall))

            Text("Filming with Rider Okafor · Eggs")
                .font(.system(size: 14))
                .foregroundStyle(SCColor.textBody)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATUS").scSectionLabel()
            SCTimeline(steps: [
                .init(
                    title: "Requested",
                    detail: "Nov 19, 3:12 PM",
                    marker: .done
                ),
                .init(
                    title: "Charged and held",
                    detail: "Nov 19, 4:40 PM · Rider Okafor accepted",
                    marker: .done
                ),
                .init(
                    title: "Waiting for both to confirm",
                    detail: "Session Nov 20, 5–7 PM",
                    marker: .current
                ),
                .init(
                    title: "Released to filmer",
                    detail: "Within a couple of days of confirming",
                    marker: .pending
                )
            ])
        }
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BREAKDOWN").scSectionLabel()
            SCDetailRow(label: "Filmer rate (2 hrs)", value: "$[RATE]")
            SCDetailRow(
                label: PaymentFees.label(percent: PaymentFees.filmingSessionPercent),
                value: "$[FEE]"
            )
            SCColor.border.frame(height: 1)
            SCDetailRow(label: "Total charged", value: "$[TOTAL]", isTotal: true)
            SCDetailRow(label: "Paid with", value: "Visa •••• 4242")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private var actionRows: some View {
        VStack(spacing: 10) {
            // Generating the PDF needs the payments schema, so this stays
            // unwired rather than offering a download that cannot be built.
            SCIconDetailRow(
                systemImage: "arrow.down.to.line",
                title: "Download receipt",
                subtitle: "PDF for your records"
            ) {
                chevron
            }

            Button(action: onGetHelp) {
                SCIconDetailRow(
                    systemImage: "info.circle",
                    title: "Get help with this payment",
                    subtitle: "Disputes and refunds go to the Spot Check team"
                ) {
                    chevron
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(SCColor.textSecondary)
    }
}

#Preview {
    TransactionDetailScreen()
}
