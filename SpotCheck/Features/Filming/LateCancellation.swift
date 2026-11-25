import Foundation

/// The 5-hour rule (Alex, 2026-11-24), for both sides of a booking:
///
/// - Late means **less than** 5 hours before the session starts. Exactly 5
///   hours before is still on time.
/// - A filmer cancelling an accepted session late takes a strike; the third
///   pauses their profile.
/// - A skater cancelling an accepted session late owes 15% of the rate, paid
///   to Spot Check.
///
/// The server decides and records all of this (`is_late_cancellation`,
/// `cancel_filming_request`). This copy exists to warn people *before* they
/// confirm, so the boundary must match it exactly.
enum LateCancellation {
    static let window: TimeInterval = 5 * 3600

    /// A statement of its own, not `PaymentFees.filmingSessionPercent`: it
    /// happens to be the same 15% today, and if one changes the other should
    /// not silently follow.
    static let skaterFeePercent = 15

    static func isLate(startsAt: Date, cancelledAt: Date) -> Bool {
        cancelledAt > startsAt.addingTimeInterval(-window)
    }

    /// The warning to show before someone confirms a cancellation, or nil when
    /// cancelling now costs them nothing.
    ///
    /// A request nobody accepted is free to cancel even inside the window:
    /// no filmer kept the slot, and there's no rate to take 15% of.
    static func warning(for party: RequestParty, request: FilmingRequest, at now: Date) -> String? {
        guard request.status == .accepted,
              isLate(startsAt: request.startsAt, cancelledAt: now)
        else { return nil }

        switch party {
        case .skater:
            guard let rate = request.rateCents else { return nil }
            let fee = FilmingPricing.lateCancelFeeCents(onRate: rate)
            return "The session starts in under 5 hours, so cancelling now costs \(Money.dollars(fee)) "
                + "(\(skaterFeePercent)% of the \(Money.dollars(rate)) rate), paid to Spot Check."
        case .filmer:
            return "The session starts in under 5 hours, so cancelling now counts as a strike. "
                + "Three strikes pause your profile."
        }
    }

    /// FilmBooking's CANCELLATION POLICY card, replacing the canvas's
    /// 24-hour / 50% terms with the rule Alex chose.
    static let policyTerms: [(term: String, value: String)] = [
        ("Cancel 5+ hours ahead", "Free"),
        ("Cancel under 5 hours", "You pay \(skaterFeePercent)%"),
        ("Nobody accepted yet", "Always free"),
        ("Filmer cancels late", "Full refund"),
    ]
}
