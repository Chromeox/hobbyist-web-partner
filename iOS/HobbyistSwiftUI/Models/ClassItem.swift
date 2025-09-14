import Foundation
import CoreLocation
import SwiftUI

struct ClassItem: Identifiable, Codable {
    let id: String
    let name: String
    let category: String
    let instructor: String
    let instructorInitials: String
    let description: String
    let duration: String
    let difficulty: String
    let price: String
    let creditsRequired: Int
    let startTime: Date
    let endTime: Date
    let location: String
    let venueName: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let spotsAvailable: Int
    let totalSpots: Int
    let rating: String
    let reviewCount: String
    let icon: String
    let categoryColor: Color
    let isFeatured: Bool
    let requirements: [String]
    let amenities: [Amenity]
    let equipment: [Equipment]
    
    var spotsLeft: String {
        "\(spotsAvailable) spots"
    }
    
    // Sample data for previews
    static var sample: ClassItem {
        ClassItem(
            id: "1",
            name: "Morning Vinyasa Flow",
            category: "Yoga",
            instructor: "Sarah Johnson",
            instructorInitials: "SJ",
            description: "Start your day with an energizing vinyasa flow practice. This class focuses on linking breath with movement through sun salutations and standing poses.",
            duration: "60 min",
            difficulty: "All Levels",
            price: "$25",
            creditsRequired: 8,
            startTime: Date().addingTimeInterval(86400),
            endTime: Date().addingTimeInterval(90000),
            location: "Downtown Studio",
            venueName: "Zen Wellness Center",
            address: "123 Main St, San Francisco, CA 94102",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            spotsAvailable: 8,
            totalSpots: 15,
            rating: "4.8",
            reviewCount: "127",
            icon: "figure.yoga",
            categoryColor: .purple,
            isFeatured: true,
            requirements: ["Yoga mat", "Water bottle", "Comfortable clothing"],
            amenities: [
                Amenity(name: "Parking", icon: "car.fill"),
                Amenity(name: "Showers", icon: "shower.fill"),
                Amenity(name: "Lockers", icon: "lock.fill")
            ],
            equipment: [
                Equipment(name: "Yoga Mat", price: "$5"),
                Equipment(name: "Yoga Block", price: "$3"),
                Equipment(name: "Strap", price: "$2")
            ]
        )
    }
}

// Make CLLocationCoordinate2D Codable
extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}

struct Amenity: Codable {
    let name: String
    let icon: String
}

struct Equipment: Codable, Identifiable {
    var id: String { name }
    let name: String
    let price: String
}

struct InstructorCard: Identifiable, Codable {
    let id: String
    let name: String
    let initials: String
    let rating: String
    let specialties: [String]
    let bio: String
}

struct Review: Identifiable, Codable {
    let id: String
    let userName: String
    let userInitials: String
    let rating: Int
    let comment: String
    let date: Date
}

// Category model for HomeView
extension ClassItem {
    struct Category: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
    }
}

// Extension for Color to make it Codable
extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, opacity
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let opacity = try container.decode(Double.self, forKey: .opacity)
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // For simplicity, encoding a default color
        try container.encode(1.0, forKey: .red)
        try container.encode(0.0, forKey: .green)
        try container.encode(0.0, forKey: .blue)
        try container.encode(1.0, forKey: .opacity)
    }
}