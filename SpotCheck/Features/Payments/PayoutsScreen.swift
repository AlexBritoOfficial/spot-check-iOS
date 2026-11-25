import SwiftUI

/// The canvas's `Payouts` artboard -- the earning side, shared by filmers
/// and pros ("For filmers and pros" on the artboard).
///
/// Reached from `FilmerTools/EarningsScreen`'s "Payout settings". The bank
/// account and tax details are Stripe-managed, as the artboard says: the
/// PAYOUT ACCOUNT rows are read from `payout_accounts`, and "Update" opens
/// Stripe's hosted Connect onboarding. The payout amounts and history below
/// are still the artboard's placeholders.
struct PayoutsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager

    @State private var showsAllTransactions = false
    @State private var payoutSetup = PayoutSetupFlow()

    private var userID: UUID? {
        if case .signedIn(let id) = authManager.state { id } else { nil }
    }

    var body: some View {
        content
            .toolbar(.hidden)
            .navigationDestination(isPresented: $showsAllTransactions) {
                TransactionsScreen()
            }
            .sheet(item: $payoutSetup.stripePage, onDismiss: stripeClosed) { page in
                SafariView(url: page.url) { payoutSetup.stripePage = nil }
                    .ignoresSafeArea()
            }
            .task {
                if let userID { await payoutSetup.load(userID: userID) }
            }
    }

    private func stripeClosed() {
        guard let userID else { return }
        Task { await payoutSetup.stripeClosed(userID: userID) }
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

            let summary = payoutSetup.summary
            Button {
                Task { await payoutSetup.openStripe() }
            } label: {
                SCIconDetailRow(
                    systemImage: "building.columns",
                    title: summary.bankTitle,
                    subtitle: summary.bankSubtitle
                ) {
                    if payoutSetup.isOpeningStripe {
                        ProgressView()
                            .tint(SCColor.accent)
                    } else {
                        Text(summary.actionTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SCColor.accent)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(payoutSetup.isOpeningStripe || payoutSetup.isLoading)

            SCIconDetailRow(
                systemImage: "doc.text",
                title: "Tax details",
                subtitle: summary.taxSubtitle
            ) {
                if summary.isTaxComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(SCColor.success)
                }
            }

            if let message = payoutSetup.errorMessage {
                SCNoteRow(
                    text: message,
                    systemImage: "exclamationmark.triangle.fill",
                    iconColor: SCColor.danger
                )
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
    .environment(AuthManager())
}
