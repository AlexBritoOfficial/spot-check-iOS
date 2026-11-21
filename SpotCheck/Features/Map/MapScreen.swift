import MapKit
import SwiftUI

struct MapScreen: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(SpotsStore.self) private var spotsStore
    @State private var locationService = LocationService()

    @State private var cameraPosition: MapCameraPosition
    @State private var selectedSpotID: UUID?
    @State private var activeTypes: Set<SpotType> = Set(SpotType.allCases)
    @State private var activeFeatures: Set<Feature> = Set(Feature.allCases)
    @State private var showAddSpot = false
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
            ZStack(alignment: .bottom) {
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
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .ignoresSafeArea(edges: .top)

                VStack(spacing: 12) {
                    FilterChipsBar(activeTypes: $activeTypes, activeFeatures: $activeFeatures)
                        .padding(.vertical, 10)
                        .background(SCColor.backgroundDeep.opacity(0.92))

                    if let selectedSpot {
                        SpotPeekCard(spot: selectedSpot) {
                            spotIDForDetail = selectedSpot.id
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
                .frame(maxHeight: .infinity, alignment: .top)

                Button {
                    showAddSpot = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(SCColor.background)
                        .frame(width: 60, height: 60)
                        .background(SCColor.accent)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(SCColor.backgroundDeep, lineWidth: 4))
                        .shadow(color: .black.opacity(0.45), radius: 8, y: 4)
                }
                .padding(.bottom, 16)
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SCColor.backgroundDeep, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await loadInitialSpots() }
            .sheet(isPresented: $showAddSpot) {
                AddSpotScreen(initialCoordinate: effectiveCoordinate)
            }
            .navigationDestination(item: $spotIDForDetail) { spotID in
                SpotDetailScreen(spotID: spotID)
            }
        }
    }

    private var effectiveCoordinate: CLLocationCoordinate2D {
        locationService.coordinate ?? LocationService.defaultCoordinate
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
