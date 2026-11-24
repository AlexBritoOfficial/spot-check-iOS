import SwiftUI

/// The canvas's `Earnings` artboard -- a filmer's week, split between
/// paid out and held funds. Amounts stay the artboard's `$[X]`
/// placeholders. "Payout settings" opens the canvas's `Payouts` artboard.
struct EarningsScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showsPayouts = false

    var body: some View {
        NavigationStack {
            content
                .toolbar(.hidden)
                .navigationDestination(isPresented: $showsPayouts) {
                    PayoutsScreen()
                }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Earnings",
                subtitle: "This week · Nov 16–22",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    totals
                    byOutcome
                    sessions
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                Button("Payout settings") { showsPayouts = true }
                    .buttonStyle(.scSecondary(fontSize: 14.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var totals: some View {
        HStack(alignment: .top, spacing: 10) {
            totalCard(
                title: "Paid out",
                value: "$[X]",
                caption: "2 sessions",
                captionColor: SCColor.success
            )
            totalCard(
                title: "Held, pending",
                value: "$[X]",
                valueColor: SCColor.accent,
                caption: "Releases after both confirm",
                captionColor: SCColor.textSecondary
            )
        }
    }

    private func totalCard(
        title: String,
        value: String,
        valueColor: Color = SCColor.textPrimary,
        caption: String,
        captionColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12.5))
                .foregroundStyle(SCColor.textSecondary)
            Text(value)
                .font(SCFont.headingFixed(24))
                .foregroundStyle(valueColor)
            Text(caption)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(captionColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private var byOutcome: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BY OUTCOME").scSectionLabel()

            ForEach(EarningsScreen.outcomes, id: \.label) { outcome in
                HStack {
                    Text(outcome.label)
                        .foregroundStyle(SCColor.textBody)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 12)
                    Text(outcome.amount)
                        .fontWeight(.semibold)
                        .foregroundStyle(SCColor.textPrimary)
                }
                .font(.system(size: 14))
            }

            SCColor.border.frame(height: 1)

            HStack {
                Text("Total this week")
                    .fontWeight(.bold)
                    .foregroundStyle(SCColor.textPrimary)
                Spacer()
                Text("$[X]")
                    .fontWeight(.semibold)
                    .foregroundStyle(SCColor.textPrimary)
            }
            .font(.system(size: 14))
        }
        .padding(16)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private var sessions: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SESSIONS").scSectionLabel()

            VStack(spacing: 0) {
                ForEach(EarningsScreen.sessionRows) { session in
                    HStack(spacing: 12) {
                        VStack(spacing: 0) {
                            Text(session.weekday)
                                .font(.system(size: 11))
                                .foregroundStyle(SCColor.textSecondary)
                            Text(session.day)
                                .font(SCFont.headingFixed(16))
                                .foregroundStyle(SCColor.textPrimary)
                        }
                        .frame(width: 44)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SCColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(session.detail)
                                .font(.system(size: 12.5))
                                .foregroundStyle(SCColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(session.amount)
                                .font(SCFont.headingFixed(14))
                                .foregroundStyle(SCColor.textPrimary)
                            Text(session.status)
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundStyle(session.statusColor)
                        }
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .top) { SCColor.border.frame(height: 1) }
                }
            }
        }
    }
}

private struct EarningsSession: Identifiable {
    let id = UUID()
    let weekday: String
    let day: String
    let title: String
    let detail: String
    let amount: String
    let status: String
    let statusColor: Color
}

private extension EarningsScreen {
    static let outcomes: [(label: String, amount: String)] = [
        ("Completed", "$[X]"),
        ("Busted (time filmed, 1-hr min)", "$[X]"),
        ("Late cancel by skater (50%)", "$[X]"),
        ("Skater no-show (100%)", "$[X]")
    ]

    static let sessionRows: [EarningsSession] = [
        EarningsSession(
            weekday: "FRI",
            day: "20",
            title: "Rider Silva · Street",
            detail: "Completed · 2 hrs filmed",
            amount: "$[X]",
            status: "PAID",
            statusColor: SCColor.success
        ),
        EarningsSession(
            weekday: "THU",
            day: "19",
            title: "Rider Chen · Park drop-in",
            detail: "Busted after 40 min · 1-hr minimum",
            amount: "$[X]",
            status: "HELD",
            statusColor: SCColor.accent
        ),
        EarningsSession(
            weekday: "TUE",
            day: "17",
            title: "Rider Nguyen · Street",
            detail: "Skater cancelled under 24 hrs · 50%",
            amount: "$[X]",
            status: "PAID",
            statusColor: SCColor.success
        ),
        EarningsSession(
            weekday: "MON",
            day: "16",
            title: "Rider Silva · Street",
            detail: "Skater cancelled 24+ hrs ahead · no charge",
            amount: "—",
            status: "$0",
            statusColor: SCColor.textSecondary
        )
    ]
}

#Preview {
    EarningsScreen()
}
