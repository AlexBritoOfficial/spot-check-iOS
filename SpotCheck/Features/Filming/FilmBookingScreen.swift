import SwiftUI

/// Mirrors the canvas's `FilmBooking` artboard: the skater's request for
/// a background-checked filmer. The WHERE tray swaps the block beneath
/// it between a skatepark picker and a dropped-pin map preview (the
/// artboard's two `sc-if` variants, both previewed below); that preview
/// is decorative art, not a live map. Selections are local view state;
/// "Request session" opens the canvas's `Checkout` artboard, and the rest
/// stays unwired pending per-feature planning.
struct FilmBookingScreen: View {
    enum Place {
        case skatepark, streetPin
    }

    @Environment(\.dismiss) private var dismiss

    @State private var place: Place
    @State private var selectedPackage = 0
    @State private var skatepark = skateparks[0]
    @State private var lighting = 1
    @State private var securityRisk = 1

    @State private var showsCheckout = false

    init(place: Place = .streetPin) {
        _place = State(initialValue: place)
    }

    var body: some View {
        NavigationStack {
            content
                .toolbar(.hidden)
                .navigationDestination(isPresented: $showsCheckout) {
                    CheckoutScreen()
                }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    packageSection
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
                    Text("$[TOTAL]")
                        .font(SCFont.headingFixed(18))
                        .foregroundStyle(SCColor.textPrimary)
                }

                Button("Request session") { showsCheckout = true }
                    .buttonStyle(.scPrimary)
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
                Text("Request a filmer")
                    .font(SCFont.heading(18))
                    .foregroundStyle(SCColor.textPrimary)
                Text("Sent to background-checked filmers near you")
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
                ForEach(Array(filmingPackages.enumerated()), id: \.element.id) { index, package in
                    let isActive = index == selectedPackage
                    Button {
                        selectedPackage = index
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
                                Text(package.name)
                                    .font(SCFont.headingFixed(14.5))
                                    .foregroundStyle(SCColor.textPrimary)
                                Text(package.detail)
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(SCColor.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text(package.price)
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

    private var whereSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHERE").scSectionLabel()

            WhereTray(
                options: ["Skatepark", "Street spot (pin)"],
                selection: Binding(
                    get: { place == .skatepark ? 0 : 1 },
                    set: { place = $0 == 0 ? .skatepark : .streetPin }
                )
            )

            switch place {
            case .skatepark:
                skateparkPicker
            case .streetPin:
                VStack(alignment: .leading, spacing: 8) {
                    DroppedPinMap()
                    Text("Pin dropped near Copley Square · drag to adjust")
                        .font(.system(size: 13))
                        .foregroundStyle(SCColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var skateparkPicker: some View {
        Menu {
            ForEach(skateparks, id: \.self) { park in
                Button(park) { skatepark = park }
            }
        } label: {
            HStack(spacing: 8) {
                Text(skatepark)
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
        .accessibilityLabel("Skatepark")
    }

    private var lightingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LIGHTING").scSectionLabel()
            FlowChips {
                ForEach(Array(lightingOptions.enumerated()), id: \.offset) { index, option in
                    FilmBookingChip(label: option, isActive: index == lighting) {
                        lighting = index
                    }
                }
            }
        }
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SECURITY RISK").scSectionLabel()
            FlowChips {
                ForEach(Array(securityRiskOptions.enumerated()), id: \.offset) { index, option in
                    FilmBookingChip(label: option, isActive: index == securityRisk) {
                        securityRisk = index
                    }
                }
            }
        }
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PAYMENT").scSectionLabel()

            SCDetailRow(label: "Filmer rate", value: "$[RATE]")
            SCDetailRow(label: "Spot Check fee (15%)", value: "$[FEE]")

            SCColor.border.frame(height: 1)

            HStack(spacing: 12) {
                Text("Charged when a filmer accepts")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SCColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Text("$[TOTAL]")
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

            ForEach(cancellationTerms, id: \.term) { term in
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

private struct FilmingPackage: Identifiable {
    let id: String
    let name: String
    let detail: String
    let price: String
}

private let filmingPackages: [FilmingPackage] = [
    FilmingPackage(
        id: "street",
        name: "Hourly Street Session",
        detail: "Grind out one spot, billed by the hour",
        price: "$[RATE]/hr"
    ),
    FilmingPackage(
        id: "park",
        name: "Park Drop-In",
        detail: "A 30–60 min block at a skatepark",
        price: "$[RATE]"
    ),
    FilmingPackage(
        id: "full",
        name: "Full Edit Package",
        detail: "Multi-day filming plus post-production",
        price: "$[RATE]"
    )
]

private let skateparks = ["Lynch Family Skatepark"]

private let lightingOptions = ["DAYLIGHT", "GOLDEN HOUR", "NIGHT · BRING LIGHTS"]

private let securityRiskOptions = ["LOW", "SOMETIMES", "KICKS OUT FAST"]

private let cancellationTerms: [(term: String, value: String)] = [
    ("Cancel 24+ hours ahead", "Free"),
    ("Cancel under 24 hours", "You pay 50%"),
    ("No-show", "You pay 100%"),
    ("Kicked out by security", "Pay for time filmed, 1-hr min"),
    ("Filmer cancels late", "Full refund + credit")
]

#Preview("Street spot") {
    FilmBookingScreen()
        .background(SCColor.background)
}

#Preview("Skatepark") {
    FilmBookingScreen(place: .skatepark)
        .background(SCColor.background)
}
