import CoreLocation
import SwiftUI

/// A skater's own filming requests: where each one stands, and the place to
/// cancel. Not on the canvas -- the artboards have no screen where a skater
/// can see or cancel a request -- so it reuses Discover's card styling.
///
/// Cancelling warns first when it would cost the 15% late fee. The server
/// decides and records the outcome; the warning is shown so nobody finds out
/// afterwards.
struct MyRequestsScreen: View {
    var pinCoordinate: CLLocationCoordinate2D = LocationService.defaultCoordinate

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @Environment(FilmingRequestsStore.self) private var store

    @State private var cancelling: FilmingRequest?
    @State private var actionError: String?
    @State private var showsBooking = false

    private var userID: UUID? { authManager.currentProfile?.id }

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(title: "My requests", subtitle: "Filming sessions you've asked for", onBack: { dismiss() }) {
                Button {
                    showsBooking = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SCColor.accent)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Request a filmer")
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let message = actionError ?? store.lastError {
                        Text(message)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SCColor.danger)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if store.myRequests.isEmpty && !store.isLoading {
                        emptyState
                    }

                    ForEach(store.myRequests) { request in
                        card(request)
                    }
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
        .sheet(isPresented: $showsBooking, onDismiss: { Task { await load() } }) {
            FilmBookingScreen(pinCoordinate: pinCoordinate)
        }
        .confirmationDialog(
            "Cancel this request?",
            isPresented: Binding(get: { cancelling != nil }, set: { if !$0 { cancelling = nil } }),
            titleVisibility: .visible,
            presenting: cancelling
        ) { request in
            Button("Cancel request", role: .destructive) {
                Task { await cancel(request) }
            }
            Button("Keep it", role: .cancel) {}
        } message: { request in
            Text(LateCancellation.warning(for: .skater, request: request, at: .now)
                 ?? "Cancelling now is free.")
        }
    }

    private func load() async {
        guard let userID else { return }
        await store.loadMyRequests(userID: userID)
    }

    private func cancel(_ request: FilmingRequest) async {
        guard let userID else { return }
        do {
            try await store.cancel(request, userID: userID)
            actionError = nil
        } catch {
            actionError = "Couldn't cancel: \(error.localizedDescription)"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No requests yet")
                .font(SCFont.headingFixed(16))
                .foregroundStyle(SCColor.textPrimary)
            Text("Ask a background-checked filmer to shoot your next session.")
                .font(.system(size: 13.5))
                .foregroundStyle(SCColor.textSecondary)
                .multilineTextAlignment(.center)
            Button("Request a filmer") { showsBooking = true }
                .buttonStyle(.scPrimary(fontSize: 14))
                .frame(height: 46)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    private func card(_ request: FilmingRequest) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(request.package.title)
                        .font(SCFont.headingFixed(14.5))
                        .foregroundStyle(SCColor.textPrimary)
                    Text(whenText(request))
                        .font(.system(size: 13))
                        .foregroundStyle(SCColor.textBody)
                    HStack(spacing: 5) {
                        SCPinGlyph(height: 13)
                        Text(request.locationTitle)
                            .font(.system(size: 13))
                            .foregroundStyle(SCColor.textSecondary)
                    }
                }
                Spacer(minLength: 8)
                statusTag(request)
            }

            if let rate = request.rateCents {
                SCDetailRow(
                    label: "Total (rate + \(PaymentFees.filmingSessionPercent)%)",
                    value: Money.dollars(FilmingPricing.skaterTotalCents(onRate: rate))
                )
            }

            if canCancel(request) {
                Button("Cancel request") { cancelling = request }
                    .buttonStyle(.scSecondary(fontSize: 12.5))
                    .frame(height: 36)
            }
        }
        .padding(14)
        .scCard(borderColor: request.status == .accepted ? SCColor.success : SCColor.border, borderWidth: 1.5)
    }

    private func whenText(_ request: FilmingRequest) -> String {
        let day = request.startsAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        let from = request.startsAt.formatted(date: .omitted, time: .shortened)
        let to = request.endsAt.formatted(date: .omitted, time: .shortened)
        return "\(day) · \(from)–\(to)"
    }

    /// Open or accepted, and not over yet.
    private func canCancel(_ request: FilmingRequest) -> Bool {
        request.status != .cancelled && request.endsAt > .now
    }

    private func statusTag(_ request: FilmingRequest) -> some View {
        let (text, color): (String, Color) = switch request.status {
        case .requested: (request.startsAt > .now ? "Waiting" : "Expired", SCColor.textSecondary)
        case .accepted: ("Accepted", SCColor.success)
        case .cancelled: (request.cancellationWasLate == true ? "Cancelled late" : "Cancelled", SCColor.danger)
        }
        return SCTag(text: text, foreground: SCColor.background, background: color)
    }
}
