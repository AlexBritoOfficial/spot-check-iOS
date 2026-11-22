import SwiftUI

/// The canvas's `Discover` artboard -- a filmer's inbox of filming
/// requests, grouped by day. Filtering and the accept/pass state are
/// local view state over the artboard's sample requests, exactly as the
/// artboard itself behaves; nothing is persisted.
///
/// The artboard also draws a filmer-mode bottom nav (DISCOVER replacing
/// FEED). That role-dependent tab bar is a product decision still to be
/// planned, so this screen is presented from the menu instead and draws
/// no nav bar.
struct DiscoverScreen: View {
    private enum Status {
        case open, accepted, passed
    }

    @Environment(\.dismiss) private var dismiss

    @State private var selectedFilter = 0
    @State private var statuses: [String: Status] = [:]

    private let filters = ["All", "Street", "Park", "Full edit"]

    private var visibleRequests: [FilmingRequest] {
        DiscoverScreen.sampleRequests.filter { request in
            let kindMatches = selectedFilter == 0
                || request.kind == filters[selectedFilter].lowercased()
            return kindMatches && statuses[request.id] != .passed
        }
    }

    private var groupedByDay: [(day: String, items: [FilmingRequest])] {
        visibleRequests.reduce(into: [(day: String, items: [FilmingRequest])]()) { groups, request in
            if let index = groups.firstIndex(where: { $0.day == request.day }) {
                groups[index].items.append(request)
            } else {
                groups.append((day: request.day, items: [request]))
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    reliabilityRow
                    earningsRow

                    ForEach(groupedByDay, id: \.day) { group in
                        SCSectionHeader(group.day) {
                            Text(group.items.count == 1 ? "1 request" : "\(group.items.count) requests")
                                .scSectionLabel()
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 8)

                        ForEach(group.items) { request in
                            requestCard(request)
                        }
                    }

                    Text("Requests come from skaters who asked for any filmer, or chose you from your profile. Accepting charges them your rate + 15%, held until you both confirm. Cancelling late adds a strike.")
                        .font(.system(size: 12))
                        .lineSpacing(3)
                        .foregroundStyle(SCColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
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
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Discover")
                        .font(SCFont.heading(26))
                        .foregroundStyle(SCColor.textPrimary)
                    Text("Filming requests near you · this week")
                        .font(.system(size: 13))
                        .foregroundStyle(SCColor.textSecondary)
                }
                Spacer()
                availabilityPill
            }

            ScrollView(.horizontal, showsIndicators: false) {
                SCPillTabs(titles: filters, selection: $selectedFilter)
                    .padding(.horizontal, SCMetric.screenPadding)
            }
            .padding(.horizontal, -SCMetric.screenPadding)
        }
        .padding(.horizontal, SCMetric.screenPadding)
        .padding(.top, SCMetric.headerTop(56))
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) { SCColor.border.frame(height: 1) }
    }

    private var availabilityPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(SCColor.success)
                .frame(width: 8, height: 8)
            Text("AVAILABLE")
                .font(SCFont.headingFixed(11))
        }
        .foregroundStyle(SCColor.success)
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(SCColor.success.opacity(0.12))
        .overlay(Capsule().stroke(SCColor.success, lineWidth: 1.5))
        .clipShape(Capsule())
    }

    private var reliabilityRow: some View {
        HStack {
            Text("Your reliability")
                .foregroundStyle(SCColor.textBody)
            Spacer()
            HStack(spacing: 6) {
                Text("0 strikes")
                    .fontWeight(.bold)
                    .foregroundStyle(SCColor.success)
                Text("· 3 pauses your profile")
                    .foregroundStyle(SCColor.textSecondary)
            }
        }
        .font(.system(size: 12.5))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .scCard(cornerRadius: SCRadius.control)
    }

    private var earningsRow: some View {
        Button {} label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Earnings this week")
                        .font(.system(size: 12.5))
                        .foregroundStyle(SCColor.textSecondary)
                    Text("$[X]")
                        .font(SCFont.headingFixed(16))
                        .foregroundStyle(SCColor.textPrimary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("View")
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(SCColor.accent)
            }
            .padding(12)
            .scCard(cornerRadius: SCRadius.control)
        }
        .buttonStyle(.plain)
    }

    private func requestCard(_ request: FilmingRequest) -> some View {
        let isAccepted = statuses[request.id] == .accepted

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Avatar(
                    initial: request.skater,
                    size: 40,
                    backgroundColor: SCColor.border,
                    foregroundColor: SCColor.textPrimary
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(request.package)
                            .font(SCFont.headingFixed(14.5))
                            .foregroundStyle(SCColor.textPrimary)
                        Spacer(minLength: 4)
                        Text("You earn $[RATE]")
                            .font(SCFont.headingFixed(13))
                            .foregroundStyle(SCColor.accent)
                            .fixedSize()
                    }
                    Text("\(request.skater) · \(request.time)")
                        .font(.system(size: 13))
                        .foregroundStyle(SCColor.textBody)
                    HStack(spacing: 5) {
                        SCPinGlyph(height: 13)
                        Text(request.spot)
                            .font(.system(size: 13))
                            .foregroundStyle(SCColor.textSecondary)
                    }
                }
            }

            FlowChips(spacing: 6) {
                ForEach(request.tags, id: \.self) { tag in
                    Text(tag.uppercased())
                        .font(SCFont.headingFixed(9.5))
                        .foregroundStyle(SCColor.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .scCard(cornerRadius: SCRadius.badge, fill: SCColor.background)
                }
            }

            if isAccepted {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                        Text("Accepted · added to your sessions")
                            .font(.system(size: 13, weight: .bold))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(SCColor.success)

                    Spacer(minLength: 8)

                    Button {} label: {
                        Text("Message")
                            .font(SCFont.headingFixed(11.5))
                            .foregroundStyle(SCColor.textPrimary)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(SCColor.border, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 8) {
                    Button("Accept") {
                        statuses[request.id] = .accepted
                    }
                    .buttonStyle(.scPrimary(fontSize: 13.5))
                    .frame(height: 44)

                    Button("Pass") {
                        statuses[request.id] = .passed
                    }
                    .buttonStyle(.scSecondary(fontSize: 13.5))
                    .frame(width: 110, height: 44)
                }
            }
        }
        .padding(14)
        .scCard(
            borderColor: isAccepted ? SCColor.success : SCColor.border,
            borderWidth: 1.5
        )
    }
}

private struct FilmingRequest: Identifiable {
    let id: String
    let day: String
    let kind: String
    let package: String
    let skater: String
    let time: String
    let spot: String
    let tags: [String]
}

private extension DiscoverScreen {
    static let sampleRequests: [FilmingRequest] = [
        FilmingRequest(
            id: "r1",
            day: "Today · Fri 20",
            kind: "street",
            package: "Hourly Street Session",
            skater: "Rider Silva",
            time: "5–7 PM",
            spot: "Copley Library · 0.8 mi",
            tags: ["Golden hour", "Security: sometimes"]
        ),
        FilmingRequest(
            id: "r2",
            day: "Sat 21",
            kind: "park",
            package: "Park Drop-In",
            skater: "Rider Chen",
            time: "10–11 AM",
            spot: "Lynch Family Skatepark · 2.1 mi",
            tags: ["Daylight", "Transition"]
        ),
        FilmingRequest(
            id: "r3",
            day: "Sun 22",
            kind: "full edit",
            package: "Full Edit Package",
            skater: "Rider Nguyen",
            time: "Sun + Tue",
            spot: "Eggs + 2 more spots",
            tags: ["Multi-day", "Post-production"]
        ),
        FilmingRequest(
            id: "r4",
            day: "Tue 24",
            kind: "street",
            package: "Hourly Street Session",
            skater: "Rider Silva",
            time: "8–10 PM",
            spot: "Eggs · 0.4 mi",
            tags: ["Night · bring lights", "Security: low"]
        )
    ]
}

#Preview {
    DiscoverScreen()
}
