import Foundation
import CoreLocation

// MARK: - Studio ↔ Venue Conversions

extension Studio {
    /// Convert Studio to Venue for UI compatibility
    /// Note: This creates a Venue with default/placeholder values for fields not in Studio
    func toVenue() -> Venue {
        return Venue(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            description: nil,
            address: address,
            city: city,
            state: province,
            zipCode: postalCode,
            latitude: 0.0, // Default - Studio doesn't have coordinates
            longitude: 0.0,
            phone: phone,
            email: email,
            website: nil,
            amenities: [],
            capacity: 0,
            hourlyRate: nil,
            isActive: isActive,
            imageUrls: [],
            operatingHours: [:],
            parkingInfo: nil,
            publicTransit: nil,
            accessibilityInfo: nil,
            averageRating: 0.0,
            totalReviews: 0,
            createdAt: Date(),
            updatedAt: nil
        )
    }
}

extension Venue {
    /// Convert Venue to Studio for service layer compatibility
    /// Note: This discards Venue-specific fields not present in Studio
    func toStudio() -> Studio {
        return Studio(
            id: id.uuidString,
            name: name,
            email: email ?? contactEmail ?? "",
            phone: phone ?? contactPhone,
            address: address,
            city: city,
            province: state,
            postalCode: zipCode,
            isActive: isActive
        )
    }
}

extension Array where Element == Studio {
    /// Convert array of Studios to Venues
    func toVenues() -> [Venue] {
        return self.map { $0.toVenue() }
    }
}

extension Array where Element == Venue {
    /// Convert array of Venues to Studios
    func toStudios() -> [Studio] {
        return self.map { $0.toStudio() }
    }
}
