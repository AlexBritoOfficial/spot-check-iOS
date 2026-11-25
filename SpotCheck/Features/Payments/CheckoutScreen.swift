import SwiftUI

/// The canvas's `Checkout` artboard -- the skater reviewing a filming
/// request before sending it.
///
/// "Confirm request" creates the request (`create_filming_request`) and shows
/// that it was sent. Saving a card isn't part of this yet: that arrives with
/// the Stripe SDK, so the artboard's "Pay with" card row is left out rather
/// than showing a card nobody saved, and nothing is charged by this screen.
struct CheckoutScreen: View {
    let draft: FilmingRequestDraft
    /// Known only when the request is named for a filmer whose rates we have.
    let quotedRateCents: Int?
    let filmerName: String?
    /// Closes the whole booking flow once the request is sent.
    var onFinished: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @Environment(FilmingRequestsStore.self) private var requestsStore

    @State private var isSending = false
    @State private var isSent = false
    @State private var errorMessage: String?

    /// Pushes onto the enclosing stack (FilmBooking's), rather than making
    /// its own, so the whole booking flow shares one back stack.
    var body: some View {
        Group {
            if isSent {
                sentConfirmation
            } else {
                content
            }
        }
        .toolbar(.hidden)
    }

    private var content: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Review & pay",
                subtitle: draft.package.title,
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    requestCard
                    priceCard
                    chargeTimeline
                    SCNoteRow(
                        text: "Payments are processed by Stripe. Cancel 5+ hours before the session and it's free.",
                        systemImage: "lock.fill",
                        iconColor: SCColor.success
                    )
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SCColor.danger)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                Button(isSending ? "Sending…" : "Confirm request") {
                    Task { await send() }
                }
                .buttonStyle(.scPrimary(fontSize: 14.5))
                .disabled(isSending)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var requestCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR REQUEST").scSectionLabel()
            if let filmerName {
                SCDetailRow(label: "Filmer", value: filmerName)
            }
            SCDetailRow(label: "Where", value: draft.place.label)
            SCDetailRow(label: "When", value: whenText)
            SCDetailRow(
                label: "Conditions",
                value: "\(draft.lighting.title) · security \(draft.securityRisk.title.lowercased())"
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    /// "Sat, Nov 28 · 5–7 PM", as the artboard writes it.
    private var whenText: String {
        let day = draft.startsAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        let from = draft.startsAt.formatted(date: .omitted, time: .shortened)
        let to = draft.endsAt.formatted(date: .omitted, time: .shortened)
        return "\(day) · \(from)–\(to)"
    }

    private var hoursText: String {
        draft.hours == 1 ? "1 hr" : "\(draft.hours) hrs"
    }

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PRICE").scSectionLabel()
            if let rate = quotedRateCents {
                SCDetailRow(label: "Filmer rate (\(hoursText))", value: Money.dollars(rate))
                SCDetailRow(
                    label: PaymentFees.label(percent: PaymentFees.filmingSessionPercent),
                    value: Money.dollars(FilmingPricing.skaterFeeCents(onRate: rate))
                )
                SCColor.border.frame(height: 1)
                SCDetailRow(
                    label: "Total",
                    value: Money.dollars(FilmingPricing.skaterTotalCents(onRate: rate)),
                    isTotal: true
                )
            } else {
                SCDetailRow(
                    label: "Filmer rate (\(hoursText))",
                    value: draft.package == .fullEdit ? "Quoted by the filmer" : "Their rate"
                )
                SCDetailRow(
                    label: PaymentFees.label(percent: PaymentFees.filmingSessionPercent),
                    value: "Added on top"
                )
                SCColor.border.frame(height: 1)
                SCDetailRow(label: "Total", value: "Set when a filmer accepts", isTotal: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private var chargeTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHEN YOU'RE CHARGED").scSectionLabel()
            SCTimeline(steps: [
                .init(
                    title: "Now: nothing charged",
                    detail: filmerName.map { "Your request goes to \($0)" }
                        ?? "Your request goes out to filmers near you",
                    marker: .current
                ),
                .init(
                    title: "A filmer accepts",
                    detail: "Their rate + \(PaymentFees.filmingSessionPercent)% is charged and held by Spot Check",
                    marker: .pending
                ),
                .init(
                    title: "You both confirm the session",
                    detail: "The filmer is paid within a couple of days",
                    marker: .pending
                )
            ])
        }
    }

    private var sentConfirmation: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(SCColor.success)
                .accessibilityHidden(true)
            Text("Request sent")
                .font(SCFont.heading(24))
                .foregroundStyle(SCColor.textPrimary)
            Text(filmerName.map { "\($0) will see it in their Discover. You'll find it under My requests." }
                 ?? "Filmers near you will see it in their Discover. You'll find it under My requests.")
                .font(.system(size: 14))
                .foregroundStyle(SCColor.textBody)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("Done", action: onFinished)
                .buttonStyle(.scPrimary(fontSize: 14.5))
        }
        .padding(.horizontal, SCMetric.screenPadding)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private func send() async {
        if let problem = draft.problem(now: .now) {
            errorMessage = problem
            return
        }
        guard let userID = authManager.currentProfile?.id else {
            errorMessage = "Sign in to request a filmer."
            return
        }
        isSending = true
        defer { isSending = false }
        do {
            try await requestsStore.create(draft, userID: userID)
            isSent = true
        } catch {
            errorMessage = "Couldn't send your request: \(error.localizedDescription)"
        }
    }
}
