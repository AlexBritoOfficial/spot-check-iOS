import Foundation

/// What a filming session costs, worked out the same way
/// `accept_filming_request` and `cancel_filming_request` work it out on the
/// server. The server's numbers are the ones recorded and charged; these exist
/// so the app shows the same figure *before* asking, rather than a placeholder.
enum FilmingPricing {
    /// The filmer's price for a session, or nil when there isn't one yet:
    /// a full edit with no quote, or a package the filmer hasn't priced.
    ///
    /// - hourly: billed by the minute at the hourly rate, rounded to the cent
    ///   half away from zero -- Postgres `round(numeric)`, and also Swift's
    ///   default `.rounded()`.
    /// - park drop-in: the filmer's flat price, whatever the length.
    /// - full edit: the filmer's quote.
    static func rateCents(
        for package: FilmingPackage,
        startsAt: Date,
        endsAt: Date,
        rates: FilmerRates,
        quoteCents: Int? = nil
    ) -> Int? {
        switch package {
        case .hourlyStreet:
            guard let hourly = rates.hourlyRateCents else { return nil }
            let hours = endsAt.timeIntervalSince(startsAt) / 3600
            return Int((Double(hourly) * hours).rounded())
        case .parkDropIn:
            return rates.parkDropInCents
        case .fullEdit:
            return quoteCents
        }
    }

    /// Spot Check's 15%, added on top of the rate and paid by the skater.
    static func skaterFeeCents(onRate rateCents: Int) -> Int {
        percent(PaymentFees.filmingSessionPercent, of: rateCents)
    }

    static func skaterTotalCents(onRate rateCents: Int) -> Int {
        rateCents + skaterFeeCents(onRate: rateCents)
    }

    /// What a skater owes Spot Check for cancelling an accepted session late.
    static func lateCancelFeeCents(onRate rateCents: Int) -> Int {
        percent(LateCancellation.skaterFeePercent, of: rateCents)
    }

    private static func percent(_ percent: Int, of cents: Int) -> Int {
        Int((Double(cents) * Double(percent) / 100).rounded())
    }
}

/// Dollar amounts as the canvas writes them: "$120", not "$120.00", but
/// "$12.50" when there are cents to show.
enum Money {
    static func dollars(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        let hasCents = cents % 100 != 0
        formatter.minimumFractionDigits = hasCents ? 2 : 0
        formatter.maximumFractionDigits = hasCents ? 2 : 0
        return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$\(cents / 100)"
    }
}
