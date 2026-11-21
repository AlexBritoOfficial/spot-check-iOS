import CoreLocation
import Observation

/// Mirrors the web app's useGeolocation.ts. CLLocationManagerDelegate
/// callbacks arrive off the main actor, so each one hops back via
/// `Task { @MainActor in ... }` before touching observable state.
@MainActor
@Observable
final class LocationService: NSObject {
    enum Status: Equatable {
        case notDetermined
        case granted
        case denied
        case unavailable
    }

    private(set) var status: Status
    private(set) var coordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    /// Boston city center -- matches the web app's DEFAULT_CITY fallback
    /// for when location isn't available/granted yet.
    static let defaultCoordinate = CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589)

    override init() {
        status = Self.status(for: manager.authorizationStatus)
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard status == .granted else { return }
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // nonisolated: this is a pure mapping with no actor-isolated state,
    // and it must be callable synchronously from the nonisolated
    // delegate callbacks below.
    private nonisolated static func status(for clStatus: CLAuthorizationStatus) -> Status {
        switch clStatus {
        case .notDetermined: .notDetermined
        case .authorizedWhenInUse, .authorizedAlways: .granted
        case .denied, .restricted: .denied
        @unknown default: .unavailable
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = Self.status(for: manager.authorizationStatus)
        Task { @MainActor in
            self.status = newStatus
            if newStatus == .granted {
                self.startUpdating()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in
            self.coordinate = coordinate
        }
    }
}
