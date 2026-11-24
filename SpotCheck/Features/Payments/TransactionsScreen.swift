import SwiftUI

/// The canvas's `Transactions` artboard -- one ledger covering both
/// directions, money paid and money received.
///
/// The rows are the artboard's sample set with its bracketed amounts,
/// pending the payments schema. Filtering is live local state, as on the
/// artboard, including its empty result.
struct TransactionsScreen: View {
    private enum Kind: String {
        case paid, held, refund, payout

        var glyphColor: Color {
            switch self {
            case .paid, .held: SCColor.accent
            case .refund, .payout: SCColor.success
            }
        }

        var amountColor: Color {
            switch self {
            case .paid, .held: SCColor.textPrimary
            case .refund, .payout: SCColor.success
            }
        }
    }

    private struct Entry: Identifiable, Hashable {
        let id = UUID()
        let kind: Kind
        let glyph: String
        let title: String
        let subtitle: String
        let amount: String
        let status: String
        let statusColor: Color
    }

    private enum Filter: Int, CaseIterable {
        case all, payments, held, refunds, payouts

        var title: String {
            switch self {
            case .all: "All"
            case .payments: "Payments"
            case .held: "Held"
            case .refunds: "Refunds"
            case .payouts: "Payouts"
            }
        }

        var kind: Kind? {
            switch self {
            case .all: nil
            case .payments: .paid
            case .held: .held
            case .refunds: .refund
            case .payouts: .payout
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var selectedFilter = Filter.all.rawValue
    @State private var selectedEntry: Entry?

    private var visibleEntries: [Entry] {
        guard let kind = Filter(rawValue: selectedFilter)?.kind else { return Self.entries }
        return Self.entries.filter { $0.kind == kind }
    }

    /// Deliberately does not own a `NavigationStack`: this screen is both a
    /// drawer destination (the shell wraps it in one) and a push target from
    /// `PayoutsScreen`, and a nested stack would break the latter.
    var body: some View {
        content
            .toolbar(.hidden)
            .navigationDestination(item: $selectedEntry) { _ in
                TransactionDetailScreen()
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Transactions",
                subtitle: "Everything you've paid and been paid",
                onBack: { dismiss() }
            )

            VStack(spacing: 12) {
                summaryGrid
                filterRow
            }
            .padding(.top, 14)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    Text("NOVEMBER")
                        .scSectionLabel()
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    ForEach(visibleEntries) { entry in
                        entryRow(entry)
                    }

                    if visibleEntries.isEmpty {
                        Text("Nothing here this month.")
                            .font(.system(size: 14))
                            .foregroundStyle(SCColor.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    }
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var summaryGrid: some View {
        HStack(spacing: 8) {
            SCStatTile(value: "$[X]", label: "Spent in Nov")
            SCStatTile(value: "$[X]", label: "Held now", valueColor: SCColor.accent)
            SCStatTile(value: "$[X]", label: "Refunds + credit", valueColor: SCColor.success)
        }
        .padding(.horizontal, SCMetric.screenPadding)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            SCPillTabs(
                titles: Filter.allCases.map(\.title),
                selection: $selectedFilter
            )
            .padding(.horizontal, SCMetric.screenPadding)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filter transactions")
    }

    private func entryRow(_ entry: Entry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            HStack(spacing: 12) {
                Text(entry.glyph)
                    .font(SCFont.headingFixed(15))
                    .foregroundStyle(entry.kind.glyphColor)
                    .frame(width: 40, height: 40)
                    .background(SCColor.border)
                    .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SCColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(entry.subtitle)
                        .font(.system(size: 12.5))
                        .foregroundStyle(SCColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(entry.amount)
                        .font(SCFont.headingFixed(14))
                        .foregroundStyle(entry.kind.amountColor)
                    Text(entry.status)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(entry.statusColor)
                }
            }
            .padding(.vertical, 12)
            .overlay(alignment: .top) { SCColor.border.frame(height: 1) }
        }
        .buttonStyle(.plain)
    }
}

private extension TransactionsScreen {
    private static let entries: [Entry] = [
        .init(
            kind: .held, glyph: "F",
            title: "Filming · Rider Okafor",
            subtitle: "Nov 20 · Eggs · Visa 4242",
            amount: "−$[TOTAL]", status: "HELD", statusColor: SCColor.accent
        ),
        .init(
            kind: .paid, glyph: "P",
            title: "Pro request · Rider Chen",
            subtitle: "Nov 18 · Video breakdown",
            amount: "−$[PRICE]", status: "PAID", statusColor: SCColor.textSecondary
        ),
        .init(
            kind: .refund, glyph: "R",
            title: "Refund · filming cancelled",
            subtitle: "Nov 16 · cancelled 24+ hrs ahead",
            amount: "+$[TOTAL]", status: "REFUNDED", statusColor: SCColor.success
        ),
        .init(
            kind: .payout, glyph: "$",
            title: "Payout to bank •••• 6789",
            subtitle: "Nov 15 · 2 filming sessions",
            amount: "+$[X]", status: "PAID OUT", statusColor: SCColor.success
        ),
        .init(
            kind: .refund, glyph: "C",
            title: "Credit · filmer cancelled late",
            subtitle: "Nov 12 · added to your balance",
            amount: "+$[CREDIT]", status: "CREDIT", statusColor: SCColor.success
        ),
        .init(
            kind: .paid, glyph: "F",
            title: "Late-cancel fee (50%)",
            subtitle: "Nov 9 · cancelled under 24 hrs",
            amount: "−$[X]", status: "PAID", statusColor: SCColor.textSecondary
        )
    ]
}

#Preview {
    NavigationStack {
        TransactionsScreen()
    }
}
