import Foundation
import CoreLocation

struct Venue: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let country: String = "CA" // Default to Canada for Vancouver
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
    
    // Additional properties for search compatibility
    let phone: String?
    let email: String?
    let hourlyRate: Double?
    let publicTransit: String?
    let accessibilityInfo: String?
    let averageRating: Double
    let totalReviews: Int
    
    // Computed property to maintain compatibility
    var operatingHoursDict: [String: String] {
        guard let hours = operatingHours else { return [:] }
        var dict: [String: String] = [:]
        for hour in hours {
            dict[hour.dayName] = hour.formattedHours
        }
        return dict
    }
    
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
        case phone
        case email
        case hourlyRate = "hourly_rate"
        case publicTransit = "public_transit"
        case accessibilityInfo = "accessibility_info"
        case averageRating = "average_rating"
        case totalReviews = "total_reviews"
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

    // Custom initializer for search compatibility
    init(
        id: UUID,
        name: String,
        description: String?,
        address: String,
        city: String,
        state: String,
        zipCode: String,
        latitude: Double,
        longitude: Double,
        phone: String?,
        email: String?,
        website: String?,
        amenities: [String],
        capacity: Int,
        hourlyRate: Double?,
        isActive: Bool,
        imageUrls: [String],
        operatingHours: [String: String],
        parkingInfo: String?,
        publicTransit: String?,
        accessibilityInfo: String?,
        averageRating: Double,
        totalReviews: Int,
        createdAt: Date,
        updatedAt: Date?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.latitude = latitude
        self.longitude = longitude
        self.amenities = amenities
        self.capacity = capacity
        self.contactEmail = email
        self.contactPhone = phone
        self.website = website
        self.parkingInfo = parkingInfo
        self.publicTransportInfo = publicTransit
        self.imageUrls = imageUrls
        self.operatingHours = nil // Convert from dict if needed
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.phone = phone
        self.email = email
        self.hourlyRate = hourlyRate
        self.publicTransit = publicTransit
        self.accessibilityInfo = accessibilityInfo
        self.averageRating = averageRating
        self.totalReviews = totalReviews
    }
    
    static let sample = Venue(
        id: UUID(),
        name: "Creative Studios Vancouver",
        description: "Modern creative space for hobby classes",
        address: "123 Commercial Drive",
        city: "Vancouver",
        state: "BC",
        zipCode: "V5L 3X3",
        latitude: 49.2744,
        longitude: -123.0693,
        phone: "+1-604-555-0123",
        email: "info@creativestudios.ca",
        website: "https://creativestudios.ca",
        amenities: ["Parking", "WiFi", "Wheelchair Accessible", "Kitchen"],
        capacity: 25,
        hourlyRate: 45.0,
        isActive: true,
        imageUrls: [],
        operatingHours: [:],
        parkingInfo: "Free street parking available",
        publicTransit: "Bus routes 20, 4, 7",
        accessibilityInfo: "Fully wheelchair accessible",
        averageRating: 4.7,
        totalReviews: 89,
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