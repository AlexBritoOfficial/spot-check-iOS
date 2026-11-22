import SwiftUI

/// The canvas's `IndustryScout` artboard -- the industry-account view
/// for scouting skaters. Filter selection is local view state; the
/// cards are the artboard's sample skaters and their actions are
/// intentionally unwired pending per-feature planning.
struct IndustryScoutScreen: View {
    @State private var selectedFilter = 0

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(IndustryScoutScreen.sampleSkaters) { skater in
                        skaterCard(skater)
                    }

                    SCNoteRow(
                        text: "Skaters see that Bricktown Skate Shop viewed their profile. Members only see totals.",
                        systemImage: "eye"
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Scout")
                    .font(SCFont.heading(26))
                    .foregroundStyle(SCColor.textPrimary)
                HStack(spacing: 6) {
                    Text("Bricktown Skate Shop")
                        .font(.system(size: 12.5))
                        .foregroundStyle(SCColor.textSecondary)
                    SCTag(
                        text: "Industry",
                        foreground: SCColor.textPrimary,
                        background: SCColor.border
                    )
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                SCPillTabs(
                    titles: ["Challenge finalists", "Fresh picks", "Most consistent", "Street"],
                    selection: $selectedFilter
                )
                .padding(.horizontal, SCMetric.screenPadding)
            }
            .padding(.horizontal, -SCMetric.screenPadding)
        }
        .padding(.horizontal, SCMetric.screenPadding)
        .padding(.top, SCMetric.headerTop(52))
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) { SCColor.border.frame(height: 1) }
    }

    private func skaterCard(_ skater: ScoutedSkater) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Avatar(
                    initial: skater.name,
                    size: 44,
                    backgroundColor: SCColor.border,
                    foregroundColor: SCColor.textPrimary
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(skater.name)
                        .font(SCFont.headingFixed(14.5))
                        .foregroundStyle(SCColor.textPrimary)
                    Text(skater.detail)
                        .font(.system(size: 12.5))
                        .foregroundStyle(SCColor.textSecondary)
                }
            }

            FlowChips(spacing: 6) {
                ForEach(skater.tags) { tag in
                    Text(tag.text.uppercased())
                        .font(SCFont.headingFixed(9.5))
                        .foregroundStyle(tag.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .scCard(cornerRadius: SCRadius.badge, fill: SCColor.background)
                }
            }

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    SCMediaPlaceholder()
                        .aspectRatio(4.0 / 5.0, contentMode: .fit)
                }
            }
            .accessibilityHidden(true)

            HStack(spacing: 8) {
                Button("View profile") {}
                    .buttonStyle(.scSecondary(fontSize: 13))
                    .frame(height: 44)

                Button("Send opportunity") {}
                    .buttonStyle(.scPrimary(fontSize: 13))
                    .frame(height: 44)
            }
        }
        .padding(14)
        .scCard()
    }
}

private struct ScoutedSkater: Identifiable {
    struct Tag: Identifiable {
        let id = UUID()
        let text: String
        let color: Color
    }

    let id = UUID()
    let name: String
    let detail: String
    let tags: [Tag]
}

private extension IndustryScoutScreen {
    static let sampleSkaters: [ScoutedSkater] = [
        ScoutedSkater(
            name: "Rider Silva",
            detail: "Boston · Goofy · Street",
            tags: [
                .init(text: "Flip in, flip out finalist", color: SCColor.accent),
                .init(text: "No sponsor yet", color: SCColor.textSecondary)
            ]
        ),
        ScoutedSkater(
            name: "Rider Chen",
            detail: "Boston · Regular · Transition",
            tags: [
                .init(text: "Fresh pick", color: SCColor.success),
                .init(text: "Flow · self-reported", color: SCColor.textSecondary)
            ]
        )
    ]
}

#Preview {
    IndustryScoutScreen()
}
