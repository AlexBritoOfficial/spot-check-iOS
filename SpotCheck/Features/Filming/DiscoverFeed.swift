import Foundation

/// Discover's filter chips. Each maps to one package.
enum DiscoverFilter: CaseIterable, Sendable {
    case all, street, park, fullEdit

    var title: String {
        switch self {
        case .all: "All"
        case .street: "Street"
        case .park: "Park"
        case .fullEdit: "Full edit"
        }
    }

    func matches(_ package: FilmingPackage) -> Bool {
        switch self {
        case .all: true
        case .street: package == .hourlyStreet
        case .park: package == .parkDropIn
        case .fullEdit: package == .fullEdit
        }
    }
}

struct DiscoverSection: Identifiable, Equatable, Sendable {
    let title: String
    let requests: [FilmingRequest]

    var id: String { title }
}

/// Groups Discover's requests by the day they start, as the canvas does
/// ("Today · Fri 20"), earliest first.
enum DiscoverFeed {
    static func sections(
        _ requests: [FilmingRequest],
        filter: DiscoverFilter,
        now: Date,
        calendar: Calendar = .current
    ) -> [DiscoverSection] {
        let matching = requests
            .filter { filter.matches($0.package) }
            .sorted { $0.startsAt < $1.startsAt }

        var sections: [(day: Date, requests: [FilmingRequest])] = []
        for request in matching {
            let day = calendar.startOfDay(for: request.startsAt)
            if let index = sections.firstIndex(where: { $0.day == day }) {
                sections[index].requests.append(request)
            } else {
                sections.append((day, [request]))
            }
        }

        return sections.map { section in
            DiscoverSection(title: dayTitle(section.day, now: now, calendar: calendar),
                            requests: section.requests)
        }
    }

    static func dayTitle(_ day: Date, now: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = calendar.locale ?? .current

        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)

        if day == today {
            formatter.dateFormat = "EEE d"
            return "Today · \(formatter.string(from: day))"
        }
        if day == tomorrow {
            formatter.dateFormat = "EEE d"
            return "Tomorrow · \(formatter.string(from: day))"
        }
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: day)
    }
}
