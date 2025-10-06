import Foundation
import CoreLocation

struct Venue: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let latitude: Double
    let longitude: Double
    let description: String?
    let amenities: [String]
    let capacity: Int
    let contactEmail: String?
    let contactPhone: String?
    let website: String?
    let parkingInfo: String?
    let publicTransportInfo: String?
    let imageUrls: [String]?
    let operatingHours: [OperatingHours]?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case city
        case state
        case zipCode = "zip_code"
        case country
        case latitude
        case longitude
        case description
        case amenities
        case capacity
        case contactEmail = "contact_email"
        case contactPhone = "contact_phone"
        case website
        case parkingInfo = "parking_info"
        case publicTransportInfo = "public_transport_info"
        case imageUrls = "image_urls"
        case operatingHours = "operating_hours"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var fullAddress: String {
        "\(address), \(city), \(state) \(zipCode)"
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func distance(from userLocation: CLLocation) -> Double {
        location.distance(from: userLocation)
    }
    
    func formattedDistance(from userLocation: CLLocation) -> String {
        let distanceInMeters = distance(from: userLocation)
        let distanceInMiles = distanceInMeters / 1609.344

        if distanceInMiles < 0.1 {
            return "Nearby"
        } else if distanceInMiles < 1 {
            return String(format: "%.1f mi", distanceInMiles)
        } else {
            return String(format: "%.0f mi", distanceInMiles)
        }
    }

    static let sample = Venue(
        id: UUID(),
        name: "Sample Venue",
        address: "123 Sample St",
        city: "Sample City",
        state: "SC",
        zipCode: "12345",
        country: "US",
        latitude: 37.7749,
        longitude: -122.4194,
        description: "Sample venue description",
        amenities: ["Parking", "WiFi"],
        capacity: 50,
        contactEmail: "sample@venue.com",
        contactPhone: nil,
        website: nil,
        parkingInfo: nil,
        publicTransportInfo: nil,
        imageUrls: nil,
        operatingHours: nil,
        isActive: true,
        createdAt: Date(),
        updatedAt: nil
    )
}

struct OperatingHours: Codable, Hashable {
    let dayOfWeek: Int
    let openTime: String
    let closeTime: String
    let isClosed: Bool
    
    enum CodingKeys: String, CodingKey {
        case dayOfWeek = "day_of_week"
        case openTime = "open_time"
        case closeTime = "close_time"
        case isClosed = "is_closed"
    }
    
    var dayName: String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard dayOfWeek >= 0 && dayOfWeek < days.count else { return "" }
        return days[dayOfWeek]
    }
    
    var formattedHours: String {
        if isClosed {
            return "Closed"
        }
        return "\(openTime) - \(closeTime)"
    }
}