import SwiftUI

/// The canvas's `ProfileVisits` artboard -- profile insights. The
/// metric cards are a taller shape than `SCStatTile` (caption above a
/// 24px value, with a second caption below), so they're built here.
/// All counts stay the artboard's bracketed placeholders.
struct ProfileVisitsScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Profile insights",
                subtitle: "This month",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    metricGrid
                    industryVisits
                    SCNoteRow(
                        text: "Industry accounts are invite-only and tied to a verified shop or brand, so you see who they are. Member visits show as totals only.",
                        systemImage: "eye"
                    )
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                Button("View opportunities") {}
                    .buttonStyle(.scPrimary(fontSize: 14.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var metricGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
            spacing: 10
        ) {
            ForEach(ProfileVisitsScreen.metrics, id: \.title) { metric in
                metricCard(metric)
            }
        }
    }

    private func metricCard(_ metric: InsightMetric) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(metric.title)
                .font(.system(size: 12.5))
                .foregroundStyle(SCColor.textSecondary)
            Text(metric.value)
                .font(SCFont.headingFixed(24))
                .foregroundStyle(SCColor.textPrimary)
            Text(metric.caption)
                .font(.system(size: 12))
                .foregroundStyle(SCColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private var industryVisits: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("INDUSTRY VISITS").scSectionLabel()

            VStack(spacing: 0) {
                ForEach(ProfileVisitsScreen.visits, id: \.name) { visit in
                    HStack(spacing: 12) {
                        Avatar(
                            initial: visit.name,
                            size: 40,
                            backgroundColor: SCColor.border,
                            foregroundColor: SCColor.textPrimary
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(visit.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(SCColor.textPrimary)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(SCColor.success)
                            }
                            Text(visit.detail)
                                .font(.system(size: 12.5))
                                .foregroundStyle(SCColor.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .top) { SCColor.border.frame(height: 1) }
                }
            }
        }
    }
}

private struct InsightMetric {
    let title: String
    let value: String
    let caption: String
}

private extension ProfileVisitsScreen {
    static let metrics: [InsightMetric] = [
        InsightMetric(title: "Profile visits", value: "[N]", caption: "From members"),
        InsightMetric(title: "From challenges", value: "[N]", caption: "Visits after an entry"),
        InsightMetric(title: "Clip views", value: "[N]", caption: "Across [N] clips"),
        InsightMetric(title: "Watch-through", value: "[X]%", caption: "Watched to the end")
    ]

    static let visits: [(name: String, detail: String)] = [
        ("Bricktown Skate Shop", "Skate shop · 2 days ago"),
        ("Low Tide Wheels", "Brand · team manager · Last week")
    ]
}

#Preview {
    ProfileVisitsScreen()
}
