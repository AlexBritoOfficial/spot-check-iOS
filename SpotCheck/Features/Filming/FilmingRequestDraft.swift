import Foundation

/// What the skater has filled in on FilmBooking, before it becomes a request.
/// Kept free of SwiftUI so the rules can be tested directly.
struct FilmingRequestDraft: Equatable, Sendable {
    enum Place: Equatable, Sendable {
        /// A known spot -- a skatepark, or the spot the request was started from.
        case spot(id: UUID, name: String, lat: Double, lng: Double)
        /// A street pin that isn't a saved spot.
        case pin(lat: Double, lng: Double, label: String)

        var lat: Double {
            switch self {
            case .spot(_, _, let lat, _), .pin(let lat, _, _): lat
            }
        }

        var lng: Double {
            switch self {
            case .spot(_, _, _, let lng), .pin(_, let lng, _): lng
            }
        }

        var label: String {
            switch self {
            case .spot(_, let name, _, _): name
            case .pin(_, _, let label): label
            }
        }

        var spotID: UUID? {
            if case .spot(let id, _, _, _) = self { return id }
            return nil
        }
    }

    var package: FilmingPackage {
        // A drop-in is a fixed block, so switching to it snaps the length to
        // its only option instead of keeping a length it can't have.
        didSet {
            let options = Self.hourOptions(for: package)
            if !options.contains(hours), let first = options.first {
                hours = first
            }
        }
    }
    var startsAt: Date
    var hours: Int
    var place: Place
    var lighting: SessionLighting
    var securityRisk: SecurityRisk
    /// Set when the request started from a filmer's profile.
    var requestedFilmerID: UUID?

    var endsAt: Date { startsAt.addingTimeInterval(TimeInterval(hours) * 3600) }

    /// The hours dropdown. A park drop-in is the canvas's "30–60 min block",
    /// booked as one hour.
    static func hourOptions(for package: FilmingPackage) -> [Int] {
        switch package {
        case .parkDropIn: [1]
        case .hourlyStreet, .fullEdit: Array(1...6)
        }
    }

    /// Why the request can't be sent yet, or nil when it can. Mirrors the
    /// server's own check in `create_filming_request`.
    func problem(now: Date) -> String? {
        if startsAt <= now {
            return "Pick a start time in the future."
        }
        return nil
    }

    /// The filmer's price, when it can be known before anyone accepts: only
    /// for a request named for a filmer whose rates we have. An open request
    /// is priced by whichever filmer accepts it, and a full edit by their quote.
    func quotedRateCents(namedFilmerRates: FilmerRates?) -> Int? {
        guard let rates = namedFilmerRates, package != .fullEdit else { return nil }
        return FilmingPricing.rateCents(for: package, startsAt: startsAt, endsAt: endsAt, rates: rates)
    }
}
