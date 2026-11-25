import SwiftUI

/// The canvas's `Discover` artboard -- a filmer's inbox of filming
/// requests, grouped by day, backed by `filming_requests`.
///
/// What a filmer sees is decided by the database: open requests that haven't
/// started, sent to anyone or named for them, minus the ones they passed on --
/// and nothing at all while their profile is paused. Accept and Pass call the
/// backend; accepting a full edit asks for a quote first.
///
/// Below the inbox, "Your sessions" lists what this filmer has accepted, with
/// a Cancel that warns when cancelling now would be a strike.
struct DiscoverScreen: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(FilmingRequestsStore.self) private var store

    @State private var filter: DiscoverFilter = .all
    @State private var acting: UUID?
    @State private var actionError: String?
    @State private var quoting: FilmingRequest?
    @State private var quoteDollars = ""
    @State private var cancelling: FilmingRequest?

    private var userID: UUID? { authManager.currentProfile?.id }

    private var sections: [DiscoverSection] {
        DiscoverFeed.sections(store.discover, filter: filter, now: .now)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    reliabilityRow
                    earningsRow

                    if let message = actionError ?? store.lastError {
                        Text(message)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SCColor.danger)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 4)
                    }

                    if sections.isEmpty && !store.isLoading {
                        emptyInbox
                    }

                    ForEach(sections) { section in
                        SCSectionHeader(section.title) {
                            Text(section.requests.count == 1 ? "1 request" : "\(section.requests.count) requests")
                                .scSectionLabel()
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 8)

                        ForEach(section.requests) { request in
                            requestCard(request)
                        }
                    }

                    if !store.sessions.isEmpty {
                        sessionsSection
                    }

                    Text("Requests come from skaters who asked for any filmer, or chose you from your profile. Accepting charges them your rate + 15%, held until you both confirm. Cancelling less than 5 hours before a session adds a strike.")
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
            .refreshable { await load() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
        .task { await load() }
        .alert("Quote this full edit", isPresented: isQuoting) {
            TextField("Price in dollars", text: $quoteDollars)
                .keyboardType(.numberPad)
            Button("Accept") {
                if let request = quoting {
                    Task { await accept(request, quoteCents: quoteCents) }
                }
            }
            .disabled(quoteCents == nil)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("A full edit is priced by you. The skater pays your quote + 15%.")
        }
        .confirmationDialog(
            "Cancel this session?",
            isPresented: isCancelling,
            titleVisibility: .visible,
            presenting: cancelling
        ) { request in
            Button("Cancel session", role: .destructive) {
                Task { await cancel(request) }
            }
            Button("Keep it", role: .cancel) {}
        } message: { request in
            Text(LateCancellation.warning(for: .filmer, request: request, at: .now)
                 ?? "It's more than 5 hours away, so cancelling now is not a strike. The skater is refunded.")
        }
    }

    private var isQuoting: Binding<Bool> {
        Binding(get: { quoting != nil }, set: { if !$0 { quoting = nil } })
    }

    private var isCancelling: Binding<Bool> {
        Binding(get: { cancelling != nil }, set: { if !$0 { cancelling = nil } })
    }

    private var quoteCents: Int? {
        guard let dollars = Int(quoteDollars.trimmingCharacters(in: .whitespaces)), dollars > 0 else { return nil }
        return dollars * 100
    }

    // MARK: - Actions

    private func load() async {
        guard let userID else { return }
        await store.loadFilmerInbox(userID: userID)
    }

    private func accept(_ request: FilmingRequest, quoteCents: Int?) async {
        guard let userID else { return }
        await perform(on: request) {
            try await store.accept(request, quoteCents: quoteCents, userID: userID)
        }
    }

    private func pass(_ request: FilmingRequest) async {
        await perform(on: request) { try await store.pass(request) }
    }

    private func cancel(_ request: FilmingRequest) async {
        guard let userID else { return }
        await perform(on: request) { try await store.cancel(request, userID: userID) }
    }

    private func perform(on request: FilmingRequest, _ action: () async throws -> Void) async {
        acting = request.id
        defer { acting = nil }
        do {
            try await action()
            actionError = nil
        } catch {
            actionError = "Couldn't update that request: \(error.localizedDescription)"
        }
    }

    // MARK: - Header and summary rows

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Discover")
                        .font(SCFont.heading(26))
                        .foregroundStyle(SCColor.textPrimary)
                    Text("Filming requests that haven't started yet")
                        .font(.system(size: 13))
                        .foregroundStyle(SCColor.textSecondary)
                }
                Spacer()
                availabilityPill
            }

            ScrollView(.horizontal, showsIndicators: false) {
                SCPillTabs(
                    titles: DiscoverFilter.allCases.map(\.title),
                    selection: Binding(
                        get: { DiscoverFilter.allCases.firstIndex(of: filter) ?? 0 },
                        set: { filter = DiscoverFilter.allCases[$0] }
                    )
                )
                .padding(.horizontal, SCMetric.screenPadding)
            }
            .padding(.horizontal, -SCMetric.screenPadding)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Filter requests")
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
        let strikes = store.standing?.strikeCount ?? 0
        return HStack {
            Text("Your reliability")
                .foregroundStyle(SCColor.textBody)
            Spacer()
            HStack(spacing: 6) {
                Text(strikes == 1 ? "1 strike" : "\(strikes) strikes")
                    .fontWeight(.bold)
                    .foregroundStyle(strikes == 0 ? SCColor.success : SCColor.danger)
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

    private var emptyInbox: some View {
        Text(store.standing == nil
             ? "Loading requests…"
             : "No open requests right now. Pull down to check again.")
            .font(.system(size: 13.5))
            .foregroundStyle(SCColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
    }

    // MARK: - Cards

    /// What this filmer would earn: their own rate for this session, or a
    /// prompt to quote a full edit.
    private func earnLabel(for request: FilmingRequest) -> String {
        if request.package == .fullEdit { return "Quote on accept" }
        guard let rates = store.standing?.rates,
              let rate = FilmingPricing.rateCents(
                for: request.package, startsAt: request.startsAt, endsAt: request.endsAt, rates: rates)
        else { return "Set your rate" }
        return "You earn \(Money.dollars(rate))"
    }

    private func timeRange(_ request: FilmingRequest) -> String {
        let from = request.startsAt.formatted(date: .omitted, time: .shortened)
        let to = request.endsAt.formatted(date: .omitted, time: .shortened)
        return "\(from)–\(to)"
    }

    private func requestCard(_ request: FilmingRequest) -> some View {
        let isBusy = acting == request.id

        return VStack(alignment: .leading, spacing: 12) {
            requestSummary(request, trailing: earnLabel(for: request))

            HStack(spacing: 8) {
                Button("Accept") {
                    if request.package == .fullEdit {
                        quoteDollars = ""
                        quoting = request
                    } else {
                        Task { await accept(request, quoteCents: nil) }
                    }
                }
                .buttonStyle(.scPrimary(fontSize: 13.5))
                .frame(height: 44)

                Button("Pass") {
                    Task { await pass(request) }
                }
                .buttonStyle(.scSecondary(fontSize: 13.5))
                .frame(width: 110, height: 44)
            }
            .disabled(isBusy)
        }
        .padding(14)
        .scCard(borderColor: SCColor.border, borderWidth: 1.5)
    }

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SCSectionHeader("Your sessions") {
                Text(store.sessions.count == 1 ? "1 accepted" : "\(store.sessions.count) accepted")
                    .scSectionLabel()
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)

            ForEach(store.sessions) { session in
                VStack(alignment: .leading, spacing: 12) {
                    requestSummary(
                        session,
                        trailing: session.rateCents.map { "You earn \(Money.dollars($0))" } ?? ""
                    )

                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                            Text(session.startsAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(SCColor.success)

                        Spacer(minLength: 8)

                        Button("Cancel") { cancelling = session }
                            .buttonStyle(.scSecondary(fontSize: 12.5))
                            .frame(width: 96, height: 36)
                            .disabled(acting == session.id)
                    }
                }
                .padding(14)
                .scCard(borderColor: SCColor.success, borderWidth: 1.5)
            }
        }
    }

    private func requestSummary(_ request: FilmingRequest, trailing: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Avatar(
                    initial: request.skater?.username ?? "?",
                    size: 40,
                    backgroundColor: SCColor.border,
                    foregroundColor: SCColor.textPrimary
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(request.package.title)
                            .font(SCFont.headingFixed(14.5))
                            .foregroundStyle(SCColor.textPrimary)
                        Spacer(minLength: 4)
                        Text(trailing)
                            .font(SCFont.headingFixed(13))
                            .foregroundStyle(SCColor.accent)
                            .fixedSize()
                    }
                    Text("\(request.skater?.username ?? "A skater") · \(timeRange(request))")
                        .font(.system(size: 13))
                        .foregroundStyle(SCColor.textBody)
                    HStack(spacing: 5) {
                        SCPinGlyph(height: 13)
                        Text(request.locationTitle)
                            .font(.system(size: 13))
                            .foregroundStyle(SCColor.textSecondary)
                    }
                }
            }

            FlowChips(spacing: 6) {
                ForEach(tags(for: request), id: \.self) { tag in
                    Text(tag.uppercased())
                        .font(SCFont.headingFixed(9.5))
                        .foregroundStyle(SCColor.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .scCard(cornerRadius: SCRadius.badge, fill: SCColor.background)
                }
            }
        }
    }

    private func tags(for request: FilmingRequest) -> [String] {
        var tags = [request.lighting.title, "Security: \(request.securityRisk.title.lowercased())"]
        if request.requestedFilmerID != nil { tags.insert("Sent to you", at: 0) }
        return tags
    }
}
