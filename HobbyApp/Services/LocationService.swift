import Foundation
import CoreLocation
import Combine

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled: Bool = false
    @Published var locationError: Error?
    
    private let locationManager = CLLocationManager()
    private let locationSubject = PassthroughSubject<CLLocation?, Never>()
    
    var locationPublisher: AnyPublisher<CLLocation?, Never> {
        locationSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Update when user moves 100 meters
        
        authorizationStatus = locationManager.authorizationStatus
        updateLocationEnabled()
    }
    
    func requestLocationPermission() async {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Permission denied, could show alert to go to settings
            break
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
    }
    
    func requestOneTimeLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
                continuation.resume(throwing: LocationError.unauthorized)
                return
            }
            
            // Store the continuation to resume when location is received
            oneTimeLocationContinuation = continuation
            locationManager.requestLocation()
        }
    }
    
    private var oneTimeLocationContinuation: CheckedContinuation<CLLocation, Error>?
    
    private func updateLocationEnabled() {
        isLocationEnabled = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    // MARK: - Vancouver-specific helpers
    
    func isInVancouver(_ location: CLLocation) -> Bool {
        // Vancouver approximate boundaries
        let vancouverBounds = CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207)
        let vancouverLocation = CLLocation(latitude: vancouverBounds.latitude, longitude: vancouverBounds.longitude)
        
        // Within 50km of Vancouver center
        let distance = location.distance(from: vancouverLocation)
        return distance <= 50000 // 50km
    }
    
    func getVancouverNeighborhood(for location: CLLocation) -> String? {
        // Simple neighborhood detection based on coordinates
        // In a real app, you'd use reverse geocoding or a more sophisticated system
        
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        
        // Rough neighborhood boundaries
        switch (lat, lng) {
        case (49.275...49.295, -123.14...(-123.11)):
            return "Downtown"
        case (49.27...49.29, -123.15...(-123.13)):
            return "West End"
        case (49.265...49.275, -123.14...(-123.12)):
            return "Yaletown"
        case (49.28...49.295, -123.13...(-123.10)):
            return "Gastown"
        case (49.25...49.275, -123.17...(-123.14)):
            return "Kitsilano"
        case (49.255...49.275, -123.13...(-123.10)):
            return "Mount Pleasant"
        case (49.26...49.28, -123.10...(-123.07)):
            return "Commercial Drive"
        default:
            return nil
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        locationSubject.send(location)
        locationError = nil
        
        // Resume one-time location request if pending
        if let continuation = oneTimeLocationContinuation {
            oneTimeLocationContinuation = nil
            continuation.resume(returning: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        
        // Resume one-time location request with error if pending
        if let continuation = oneTimeLocationContinuation {
            oneTimeLocationContinuation = nil
            continuation.resume(throwing: error)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        updateLocationEnabled()
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            stopLocationUpdates()
            currentLocation = nil
            locationSubject.send(nil)
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Location Errors

enum LocationError: LocalizedError {
    case unauthorized
    case unavailable
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Location access not authorized"
        case .unavailable:
            return "Location services unavailable"
        case .timeout:
            return "Location request timed out"
        }
    }
}

// MARK: - Distance Utilities

extension LocationService {
    
    static func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    static func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
        return from.distance(from: to)
    }
    
    static func isWithinDistance(_ distance: Double, location1: CLLocation, location2: CLLocation) -> Bool {
        return location1.distance(from: location2) <= distance
    }
}