import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    @Published var isUpdatingLocation = false
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Update every 100 meters
        
        // Check initial authorization status
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Show alert to guide user to settings
            locationError = LocationError.permissionDenied
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            requestLocationPermission()
            return
        }
        
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }
    
    func requestSingleLocation() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            requestLocationPermission()
            return
        }
        
        locationManager.requestLocation()
    }
    
    // MARK: - Distance Calculations
    
    func distance(to location: CLLocation) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        return currentLocation.distance(from: location)
    }
    
    func distanceInMiles(to location: CLLocation) -> Double? {
        guard let meters = distance(to: location) else { return nil }
        return meters / 1609.344
    }
    
    func formattedDistance(to location: CLLocation) -> String? {
        guard let miles = distanceInMiles(to: location) else { return nil }
        
        if miles < 0.1 {
            return "Nearby"
        } else if miles < 1 {
            return String(format: "%.1f mi", miles)
        } else {
            return String(format: "%.0f mi", miles)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out cached or inaccurate locations
        let howRecent = location.timestamp.timeIntervalSinceNow
        guard abs(howRecent) < 10 else { return } // Ignore if older than 10 seconds
        
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy < 100 else { return } // Ignore if too inaccurate
        
        currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = LocationError.permissionDenied
                stopUpdatingLocation()
            case .locationUnknown:
                locationError = LocationError.locationUnknown
            default:
                locationError = LocationError.other(error)
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if isUpdatingLocation {
                startUpdatingLocation()
            }
        case .denied, .restricted:
            stopUpdatingLocation()
            locationError = LocationError.permissionDenied
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Location Errors
enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnknown
    case other(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable location services in Settings."
        case .locationUnknown:
            return "Unable to determine your location. Please try again."
        case .other(let error):
            return error.localizedDescription
        }
    }
}