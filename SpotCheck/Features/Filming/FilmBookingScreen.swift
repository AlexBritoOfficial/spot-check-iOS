import CoreLocation
import SwiftUI

/// The canvas's `FilmBooking` artboard: the skater's request for a
/// background-checked filmer.
///
/// Opened from three places: a spot's page (the spot is filled in), a
/// filmer's profile (the request is named for them, so the price is known),
/// and the menu (a skatepark or a pin at the skater's location). The WHEN
/// section isn't on the artboard -- the artboard has no way to pick a time,
/// yet Checkout shows one and the server requires one -- so it uses the
/// system calendar picker plus an hours dropdown.
///
/// The street pin is placed at the skater's current location and can't be
/// dragged yet; the map beneath it is the artboard's decorative art.
struct FilmBookingScreen: View {
    /// The filmer a request is named for, when it starts from their profile.
    struct RequestedFilmer: Equatable {
        let id: UUID
        let name: String
    }

    private enum Place {
        case skatepark, streetPin
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(SpotsStore.self) private var spotsStore
    @Environment(FilmingRequestsStore.self) private var requestsStore

    private let fixedSpot: Spot?
    private let requestedFilmer: RequestedFilmer?
    private let pinCoordinate: CLLocationCoordinate2D

    @State private var draft: FilmingRequestDraft
    @State private var place: Place
    @State private var selectedParkID: UUID?
    @State private var filmerRates: FilmerRates?
    @State private var showsCheckout = false

    init(
        spot: Spot? = nil,
        requestedFilmer: RequestedFilmer? = nil,
        pinCoordinate: CLLocationCoordinate2D = LocationService.defaultCoordinate
    ) {
        fixedSpot = spot
        self.requestedFilmer = requestedFilmer
        self.pinCoordinate = pinCoordinate

        let startPlace: FilmingRequestDraft.Place = if let spot {
            .spot(id: spot.id, name: spot.name, lat: spot.lat, lng: spot.lng)
        } else {
            .pin(lat: pinCoordinate.latitude, lng: pinCoordinate.longitude, label: Self.pinLabel)
        }
        let package: FilmingPackage = spot?.spotType == .park ? .parkDropIn : .hourlyStreet
        _draft = State(initialValue: FilmingRequestDraft(
            package: package,
            startsAt: Self.defaultStart(),
            hours: FilmingRequestDraft.hourOptions(for: package).contains(2) ? 2 : 1,
            place: startPlace,
            lighting: .goldenHour,
            securityRisk: .sometimes,
            requestedFilmerID: requestedFilmer?.id
        ))
        _place = State(initialValue: spot?.spotType == .park ? .skatepark : .streetPin)
    }

    private static let pinLabel = "Pin at your location"

    /// Tomorrow at 5 PM: a plausible session, and always in the future.
    private static func defaultStart(now: Date = .now, calendar: Calendar = .current) -> Date {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        return calendar.date(bySettingHour: 17, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    private var skateparks: [Spot] {
        spotsStore.allCachedSpots
            .filter { $0.spotType == .park }
            .sorted { $0.name < $1.name }
    }

    private var quotedRate: Int? {
        draft.quotedRateCents(namedFilmerRates: filmerRates)
    }

    var body: some View {
        NavigationStack {
            content
                .toolbar(.hidden)
                .navigationDestination(isPresented: $showsCheckout) {
                    CheckoutScreen(
                        draft: draft,
                        quotedRateCents: quotedRate,
                        filmerName: requestedFilmer?.name,
                        onFinished: { dismiss() }
                    )
                }
        }
        .task {
            if let requestedFilmer {
                filmerRates = await requestsStore.standing(ofFilmer: requestedFilmer.id)?.rates
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    packageSection
                    whenSection
                    whereSection
                    lightingSection
                    securitySection
                    paymentSection
                    cancellationSection
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            SCFooterBar(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total incl. fee")
                        .font(.system(size: 12))
                        .foregroundStyle(SCColor.textSecondary)
                    Text(quotedRate.map { Money.dollars(FilmingPricing.skaterTotalCents(onRate: $0)) }
                         ?? "On accept")
                        .font(SCFont.headingFixed(18))
                        .foregroundStyle(SCColor.textPrimary)
                }

                Button("Request session") { showsCheckout = true }
                    .buttonStyle(.scPrimary)
                    .disabled(draft.problem(now: .now) != nil)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 2) {
                Text(requestedFilmer.map { "Request \($0.name)" } ?? "Request a filmer")
                    .font(SCFont.heading(18))
                    .foregroundStyle(SCColor.textPrimary)
                Text(requestedFilmer == nil
                     ? "Sent to background-checked filmers near you"
                     : "Sent only to this filmer")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SCColor.success)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 10)
        .padding(.trailing, SCMetric.screenPadding)
        .padding(.top, SCMetric.headerTop(52))
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) { SCColor.border.frame(height: 1) }
    }

    private var packageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PACKAGE").scSectionLabel()

            VStack(spacing: 8) {
                ForEach(FilmingPackage.allCases, id: \.self) { package in
                    let isActive = package == draft.package
                    Button {
                        draft.package = package
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .strokeBorder(
                                    isActive ? SCColor.accent : SCColor.textSecondary,
                                    lineWidth: isActive ? 6 : 2
                                )
                                .frame(width: 20, height: 20)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(package.title)
                                    .font(SCFont.headingFixed(14.5))
                                    .foregroundStyle(SCColor.textPrimary)
                                Text(package.detail)
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(SCColor.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text(packagePrice(package))
                                .font(SCFont.headingFixed(13))
                                .foregroundStyle(SCColor.accent)
                                .lineLimit(1)
                        }
                        .multilineTextAlignment(.leading)
                        .padding(SCMetric.cardPadding)
                        .scCard(
                            cornerRadius: SCRadius.cardSmall,
                            borderColor: isActive ? SCColor.accent : SCColor.border,
                            borderWidth: isActive ? 2 : 1
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
                }
            }
        }
    }

    /// A named filmer's own prices; an open request can't show one.
    private func packagePrice(_ package: FilmingPackage) -> String {
        guard let rates = filmerRates else { return package == .fullEdit ? "Quote" : "" }
        switch package {
        case .hourlyStreet: return rates.hourlyRateCents.map { "\(Money.dollars($0))/hr" } ?? ""
        case .parkDropIn: return rates.parkDropInCents.map(Money.dollars) ?? ""
        case .fullEdit: return "Quote"
        }
    }

    private var whenSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHEN").scSectionLabel()

            DatePicker(
                "Session start",
                selection: $draft.startsAt,
                in: Date.now...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .tint(SCColor.accent)
            .padding(8)
            .scCard(cornerRadius: SCRadius.cardSmall)

            Menu {
                ForEach(FilmingRequestDraft.hourOptions(for: draft.package), id: \.self) { hours in
                    Button(hoursLabel(hours)) { draft.hours = hours }
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Length")
                        .font(.system(size: 14))
                        .foregroundStyle(SCColor.textBody)
                    Spacer(minLength: 0)
                    Text(hoursLabel(draft.hours))
                        .font(SCFont.headingFixed(15))
                        .foregroundStyle(SCColor.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SCColor.textSecondary)
                }
                .padding(.horizontal, 16)
                .scFieldContainerChrome()
            }
            .disabled(FilmingRequestDraft.hourOptions(for: draft.package).count == 1)
            .accessibilityLabel("Session length, \(hoursLabel(draft.hours))")

            Text(sessionWindow)
                .font(.system(size: 13))
                .foregroundStyle(SCColor.textSecondary)
        }
    }

    private func hoursLabel(_ hours: Int) -> String {
        hours == 1 ? "1 hour" : "\(hours) hours"
    }

    private var sessionWindow: String {
        let day = draft.startsAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        let from = draft.startsAt.formatted(date: .omitted, time: .shortened)
        let to = draft.endsAt.formatted(date: .omitted, time: .shortened)
        return "\(day) · \(from)–\(to)"
    }

    @ViewBuilder
    private var whereSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHERE").scSectionLabel()

            if let fixedSpot {
                SCIconDetailRow(
                    systemImage: fixedSpot.spotType == .park ? "figure.skateboarding" : "mappin.and.ellipse",
                    title: fixedSpot.name,
                    subtitle: fixedSpot.city
                )
                .padding(12)
                .scCard(cornerRadius: SCRadius.cardSmall)
            } else {
                WhereTray(
                    options: ["Skatepark", "Street spot (pin)"],
                    selection: Binding(
                        get: { place == .skatepark ? 0 : 1 },
                        set: { choosePlace($0 == 0 ? .skatepark : .streetPin) }
                    )
                )

                switch place {
                case .skatepark:
                    skateparkPicker
                case .streetPin:
                    VStack(alignment: .leading, spacing: 8) {
                        DroppedPinMap()
                        Text("Pinned at your current location")
                            .font(.system(size: 13))
                            .foregroundStyle(SCColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func choosePlace(_ newPlace: Place) {
        place = newPlace
        switch newPlace {
        case .skatepark:
            if let park = skateparks.first(where: { $0.id == selectedParkID }) ?? skateparks.first {
                selectPark(park)
            }
        case .streetPin:
            draft.place = .pin(lat: pinCoordinate.latitude, lng: pinCoordinate.longitude, label: Self.pinLabel)
        }
    }

    private func selectPark(_ park: Spot) {
        selectedParkID = park.id
        draft.place = .spot(id: park.id, name: park.name, lat: park.lat, lng: park.lng)
    }

    private var skateparkPicker: some View {
        Menu {
            ForEach(skateparks) { park in
                Button(park.name) { selectPark(park) }
            }
        } label: {
            HStack(spacing: 8) {
                Text(skateparks.isEmpty ? "No skateparks loaded nearby" : draft.place.label)
                    .font(SCFont.headingFixed(15))
                    .foregroundStyle(SCColor.textPrimary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SCColor.textSecondary)
            }
            .padding(.horizontal, 16)
            .scFieldContainerChrome()
        }
        .disabled(skateparks.isEmpty)
        .accessibilityLabel("Skatepark")
    }

    private var lightingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LIGHTING").scSectionLabel()
            FlowChips {
                ForEach(SessionLighting.allCases, id: \.self) { option in
                    FilmBookingChip(label: option.title.uppercased(), isActive: option == draft.lighting) {
                        draft.lighting = option
                    }
                }
            }
        }
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SECURITY RISK").scSectionLabel()
            FlowChips {
                ForEach(SecurityRisk.allCases, id: \.self) { option in
                    FilmBookingChip(label: option.title.uppercased(), isActive: option == draft.securityRisk) {
                        draft.securityRisk = option
                    }
                }
            }
        }
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PAYMENT").scSectionLabel()

            if let rate = quotedRate {
                SCDetailRow(label: "Filmer rate (\(hoursLabel(draft.hours)))", value: Money.dollars(rate))
                SCDetailRow(
                    label: PaymentFees.label(percent: PaymentFees.filmingSessionPercent),
                    value: Money.dollars(FilmingPricing.skaterFeeCents(onRate: rate))
                )
            } else {
                SCDetailRow(
                    label: "Filmer rate",
                    value: draft.package == .fullEdit ? "Quoted by the filmer" : "Set by the filmer who accepts"
                )
                SCDetailRow(
                    label: PaymentFees.label(percent: PaymentFees.filmingSessionPercent),
                    value: "Added on top"
                )
            }

            SCColor.border.frame(height: 1)

            HStack(spacing: 12) {
                Text("Charged when a filmer accepts")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SCColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Text(quotedRate.map { Money.dollars(FilmingPricing.skaterTotalCents(onRate: $0)) } ?? "—")
                    .font(SCFont.headingFixed(14))
                    .foregroundStyle(SCColor.textPrimary)
            }

            SCNoteRow(
                text: "We hold the money until you and the filmer both confirm the session happened. Then the filmer is paid within a couple of days.",
                systemImage: "lock",
                iconColor: SCColor.success
            )
        }
        .padding(16)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private var cancellationSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("CANCELLATION POLICY").scSectionLabel()
                .padding(.bottom, 1)

            ForEach(LateCancellation.policyTerms, id: \.term) { term in
                HStack(alignment: .top, spacing: 12) {
                    Text(term.term)
                        .font(.system(size: 13))
                        .foregroundStyle(SCColor.textBody)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Text(term.value)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SCColor.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }
}

/// The artboard's 40pt WHERE tray: shorter and label-only, where
/// `SCSegmentedTray` is the 52pt two-line form used on PostClip.
private struct WhereTray: View {
    let options: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                let isActive = index == selection
                Button {
                    selection = index
                } label: {
                    Text(option)
                        .font(SCFont.headingFixed(12.5))
                        .foregroundStyle(isActive ? SCColor.background : SCColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(isActive ? SCColor.accent : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(4)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }
}

/// The artboard's 40pt chip, one size up from the map's 36pt `Chip`.
private struct FilmBookingChip: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(SCFont.headingFixed(11.5))
                .foregroundStyle(isActive ? SCColor.background : SCColor.textPrimary)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(isActive ? SCColor.accent : .clear)
                .overlay(
                    Capsule().stroke(isActive ? SCColor.accent : SCColor.border, lineWidth: 1.5)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }
}

/// Decorative stand-in for the street-spot map: the artboard's own five
/// road strokes plus the brand pin, traced at the canvas's coordinates
/// (350x128) and scaled to whatever width the screen gives it. No
/// MapKit -- nothing here is a real location.
private struct DroppedPinMap: View {
    private static let majorRoads: [[CGPoint]] = [
        [CGPoint(x: -10, y: 46), CGPoint(x: 360, y: 62)],
        [CGPoint(x: 110, y: -10), CGPoint(x: 134, y: 140)],
        [CGPoint(x: 250, y: -10), CGPoint(x: 238, y: 140)]
    ]

    private static let minorRoads: [[CGPoint]] = [
        [CGPoint(x: -10, y: 100), CGPoint(x: 360, y: 92)],
        [CGPoint(x: 40, y: -10), CGPoint(x: 52, y: 140)]
    ]

    var body: some View {
        GeometryReader { proxy in
            let scaleX = proxy.size.width / 350
            let scaleY = proxy.size.height / 128

            ZStack(alignment: .topLeading) {
                SCColor.backgroundDeep

                ForEach(Array(Self.majorRoads.enumerated()), id: \.offset) { _, road in
                    path(road, scaleX: scaleX, scaleY: scaleY)
                        .stroke(SCColor.border, lineWidth: 3)
                }

                ForEach(Array(Self.minorRoads.enumerated()), id: \.offset) { _, road in
                    path(road, scaleX: scaleX, scaleY: scaleY)
                        .stroke(SCColor.surface, lineWidth: 1.5)
                }

                SCPinGlyph(height: 39, showsHole: true, strokeColor: SCColor.background)
                    .offset(x: 160 * scaleX, y: 30 * scaleY)
            }
        }
        .frame(height: 128)
        .scCard(cornerRadius: SCRadius.cardSmall, fill: SCColor.backgroundDeep)
        .accessibilityElement()
        .accessibilityLabel("Map with a dropped pin")
    }

    private func path(_ points: [CGPoint], scaleX: CGFloat, scaleY: CGFloat) -> Path {
        var path = Path()
        for (index, point) in points.enumerated() {
            let scaled = CGPoint(x: point.x * scaleX, y: point.y * scaleY)
            if index == 0 {
                path.move(to: scaled)
            } else {
                path.addLine(to: scaled)
            }
        }
        return path
    }
}

#Preview("Open request") {
    FilmBookingScreen()
        .environment(SpotsStore())
        .environment(FilmingRequestsStore())
}
