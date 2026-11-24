import SwiftUI

/// The canvas's `Payouts` artboard -- the earning side, shared by filmers
/// and pros ("For filmers and pros" on the artboard).
///
/// Reached from `FilmerTools/EarningsScreen`'s "Payout settings". The bank
/// account and tax details are Stripe-managed, as the artboard says, so
/// both rows stay unwired until Connect onboarding exists.
struct PayoutsScreen: View {
    /// Changing the bank account means Stripe Connect onboarding, which does
    /// not exist yet, so the presenter decides what this does.
    var onUpdateBankAccount: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var showsAllTransactions = false

    var body: some View {
        content
            .toolbar(.hidden)
            .navigationDestination(isPresented: $showsAllTransactions) {
                TransactionsScreen()
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Payouts",
                subtitle: "For filmers and pros",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    nextPayoutCard
                    payoutAccountSection
                    howYouArePaidCard
                    recentSection
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var nextPayoutCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Next payout")
                .font(.system(size: 12.5))
                .foregroundStyle(SCColor.textBody)
            Text("$[X]")
                .font(SCFont.heading(30))
                .foregroundStyle(SCColor.textPrimary)
            Text("For 2 confirmed sessions · arrives in 1–2 business days")
                .font(.system(size: 13))
                .foregroundStyle(SCColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .scCard(
            cornerRadius: SCRadius.card,
            fill: SCColor.accent.opacity(0.1),
            borderColor: SCColor.accent,
            borderWidth: 1.5
        )
    }

    private var payoutAccountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PAYOUT ACCOUNT").scSectionLabel()

            Button(action: onUpdateBankAccount) {
                SCIconDetailRow(
                    systemImage: "building.columns",
                    title: "Bank account •••• 6789",
                    subtitle: "Verified · managed with Stripe"
                ) {
                    Text("Update")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SCColor.accent)
                }
            }
            .buttonStyle(.plain)

            SCIconDetailRow(
                systemImage: "doc.text",
                title: "Tax details",
                subtitle: "Complete · collected by Stripe for payouts"
            ) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(SCColor.success)
            }
        }
    }

    private var howYouArePaidCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOW YOU'RE PAID").scSectionLabel()
            SCDetailRow(label: "Filming", value: "You keep 100% of your rate")
            SCDetailRow(
                label: "Pro requests",
                value: "Price minus \(PaymentFees.proRequestPercent)% fee"
            )
            SCDetailRow(label: "Timing", value: "After both confirm")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SCSectionHeader("Recent") {
                Button("All transactions") { showsAllTransactions = true }
                    .font(.system(size: 13))
                    .foregroundStyle(SCColor.accent)
            }

            VStack(spacing: 0) {
                payoutRow(date: "Nov 15", detail: "2 filming sessions")
                payoutRow(date: "Nov 8", detail: "1 filming session · 1 late-cancel fee")
            }
        }
    }

    private func payoutRow(date: String, detail: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(date)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                Text(detail)
                    .font(.system(size: 12.5))
                    .foregroundStyle(SCColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 3) {
                Text("+$[X]")
                    .font(SCFont.headingFixed(14))
                    .foregroundStyle(SCColor.success)
                Text("PAID OUT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(SCColor.success)
            }
        }
        .padding(.vertical, 12)
        .overlay(alignment: .top) { SCColor.border.frame(height: 1) }
    }
}

#Preview {
    NavigationStack {
        PayoutsScreen()
    }
}
