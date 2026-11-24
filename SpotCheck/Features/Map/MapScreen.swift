import MapKit
import SwiftUI

/// The canvas's `Map` artboard. The header, search field, filter row,
/// locate button and peek card all float over the map -- the canvas
/// draws no system navigation bar or map controls, so both are hidden.
///
/// The search field is presentation only; narrowing by name isn't wired
/// up yet. Adding a spot moved off this screen in the canvas: the raised
/// bottom-bar button posts a clip, and `PostClipScreen` is where "add a
/// new spot instead" lives.
struct MapScreen: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(SpotsStore.self) private var spotsStore
    @Environment(MenuCoordinator.self) private var menuCoordinator
    @State private var locationService = LocationService()

    @State private var cameraPosition: MapCameraPosition
    @State private var selectedSpotID: UUID?
    @State private var activeTypes: Set<SpotType> = Set(SpotType.allCases)
    @State private var activeFeatures: Set<Feature> = Set(Feature.allCases)
    @State private var searchText = ""
    @State private var spotIDForDetail: UUID?

    init() {
        _cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: LocationService.defaultCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        )
    }

    private var filteredSpots: [Spot] {
        spotsStore.nearbySpots.filter { spot in
            activeTypes.contains(spot.spotType)
                && (spot.features.isEmpty || spot.features.contains { activeFeatures.contains($0) })
        }
    }

    private var selectedSpot: Spot? {
        selectedSpotID.flatMap { spotsStore.spot(id: $0) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    ForEach(filteredSpots) { spot in
                        Annotation(spot.name, coordinate: spot.coordinate) {
                            SpotPin(
                                isOwnedByMe: spot.isOwned(by: authManager.currentProfile?.id),
                                isSelected: selectedSpotID == spot.id
                            )
                            .onTapGesture { selectedSpotID = spot.id }
                        }
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .excludingAll))
                .ignoresSafeArea()

                floatingHeader
            }
            .overlay(alignment: .bottom) { mapOverlays }
            .background(SCColor.backgroundDeep)
            .toolbar(.hidden)
            .task { await loadInitialSpots() }
            .navigationDestination(item: $spotIDForDetail) { spotID in
                SpotDetailScreen(spotID: spotID)
            }
        }
    }

    private var floatingHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Button {
                    menuCoordinator.isOpen = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SCColor.textPrimary)
                        .frame(width: 50, height: 50)
                        .scCard(cornerRadius: SCRadius.cardSmall, fill: SCColor.background)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open menu")

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SCColor.textSecondary)
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("SEARCH A SPOT...")
                                .font(SCFont.headingFixed(13))
                                .foregroundStyle(SCColor.textSecondary)
                                .allowsHitTesting(false)
                        }
                        TextField("", text: $searchText)
                            .font(SCFont.headingFixed(13))
                            .foregroundStyle(SCColor.textPrimary)
                            .tint(SCColor.accent)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityLabel("Search a spot")
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 50)
                .scCard(cornerRadius: SCRadius.cardSmall, fill: SCColor.background)
            }

            FilterChipsBar(activeTypes: $activeTypes, activeFeatures: $activeFeatures)
                .padding(.horizontal, -16)
        }
        .padding(.horizontal, 16)
        .padding(.top, SCMetric.headerTop(56))
    }

    private var mapOverlays: some View {
        VStack(alignment: .trailing, spacing: 16) {
            SCCircleIconButton(
                systemImage: "location",
                accessibilityTitle: "Center on my location",
                diameter: 50,
                background: SCColor.background,
                borderColor: SCColor.border
            ) {
                centerOnUser()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            if let selectedSpot {
                SpotPeekCard(spot: selectedSpot) {
                    spotIDForDetail = selectedSpot.id
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, SCMetric.bottomNavHeight + 12)
    }

    private var effectiveCoordinate: CLLocationCoordinate2D {
        locationService.coordinate ?? LocationService.defaultCoordinate
    }

    private func centerOnUser() {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: effectiveCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        )
    }

    private func loadInitialSpots() async {
        locationService.requestWhenInUseAuthorization()
        let coordinate = effectiveCoordinate
        cameraPosition = .region(
            MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        )
        await spotsStore.loadNearby(lat: coordinate.latitude, lng: coordinate.longitude)
    }
}
