import Foundation
import CoreLocation

// MARK: - HobbyClass
struct HobbyClass: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let category: ClassCategory
    let difficulty: DifficultyLevel
    let price: Double
    let startDate: Date
    let endDate: Date
    let duration: Int // in minutes
    let maxParticipants: Int
    let enrolledCount: Int
    let instructor: InstructorInfo
    let venue: VenueInfo
    let imageUrl: String?
    let thumbnailUrl: String?
    let averageRating: Double
    let totalReviews: Int
    let tags: [String]
    let requirements: [String]
    let whatToBring: [String]
    let cancellationPolicy: String
    let isOnline: Bool
    let meetingUrl: String?
}

// MARK: - Supporting Types
enum ClassCategory: String, CaseIterable, Codable {
    case arts = "Arts & Crafts"
    case cooking = "Cooking & Baking"
    case fitness = "Fitness & Wellness"
    case music = "Music & Performance"
    case photography = "Photography"
    case technology = "Technology"
    case language = "Language"
    case business = "Business & Professional"
    case outdoor = "Outdoor & Adventure"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .arts: return "paintbrush"
        case .cooking: return "fork.knife"
        case .fitness: return "figure.walk"
        case .music: return "music.note"
        case .photography: return "camera"
        case .technology: return "laptopcomputer"
        case .language: return "globe"
        case .business: return "briefcase"
        case .outdoor: return "leaf"
        case .other: return "star"
        }
    }
}

enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case allLevels = "All Levels"
    
    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "yellow"
        case .advanced: return "red"
        case .allLevels: return "blue"
        }
    }
}

// MARK: - Simplified Instructor Info for HobbyClass
struct InstructorInfo: Codable, Hashable {
    let id: String
    let name: String
    let bio: String?
    let profileImageUrl: String?
    let rating: Double
    let totalClasses: Int
    let totalStudents: Int
    let specialties: [String]
    let certifications: [String]
    let yearsOfExperience: Int
    let socialLinks: SocialLinks?
}

// MARK: - Simplified Venue Info for HobbyClass
struct VenueInfo: Codable, Hashable {
    let id: String
    let name: String
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let latitude: Double
    let longitude: Double
    let amenities: [String]
    let parkingInfo: String?
    let publicTransit: String?
    let imageUrls: [String]?
    let accessibilityInfo: String?
}

// MARK: - Extension for ClassItem compatibility
extension HobbyClass {
    static var hobbyClassSamples: [ClassItem] {
        // Convert sample HobbyClass to ClassItem for compatibility
        return ClassItem.hobbyClassSamples
    }
    
    // Convert HobbyClass to ClassItem
    var toClassItem: ClassItem {
        ClassItem(
            id: id,
            name: title,
            category: category.rawValue,
            instructor: instructor.name,
            instructorInitials: String(instructor.name.prefix(2)),
            description: description,
            duration: "\(duration) min",
            difficulty: difficulty.rawValue,
            price: "$\(Int(price))",
            creditsRequired: Int(price / 3.5), // Approximate conversion
            startTime: startDate,
            endTime: endDate,
            location: "Studio",
            venueName: venue.name,
            address: venue.address,
            coordinate: CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude),
            spotsAvailable: maxParticipants - enrolledCount,
            totalSpots: maxParticipants,
            rating: String(format: "%.1f", averageRating),
            reviewCount: "\(totalReviews)",
            icon: category.iconName,
            categoryColor: .blue,
            isFeatured: false,
            requirements: requirements,
            amenities: [],
            equipment: []
        )
    }
    
    // Create from ClassItem
    static func from(_ item: ClassItem) -> HobbyClass {
        HobbyClass(
            id: item.id,
            title: item.name,
            description: item.description,
            category: ClassCategory(rawValue: item.category) ?? .other,
            difficulty: DifficultyLevel(rawValue: item.difficulty) ?? .allLevels,
            price: Double(item.price.replacingOccurrences(of: "$", with: "")) ?? 0.0,
            startDate: item.startTime,
            endDate: item.endTime,
            duration: Calendar.current.dateComponents([.minute], from: item.startTime, to: item.endTime).minute ?? 60,
            maxParticipants: item.totalSpots,
            enrolledCount: item.totalSpots - item.spotsAvailable,
            instructor: InstructorInfo(
                id: UUID().uuidString,
                name: item.instructor,
                bio: nil,
                profileImageUrl: nil,
                rating: Double(item.rating) ?? 0.0,
                totalClasses: 0,
                totalStudents: 0,
                specialties: [],
                certifications: [],
                yearsOfExperience: 0,
                socialLinks: nil
            ),
            venue: VenueInfo(
                id: UUID().uuidString,
                name: item.venueName,
                address: item.address,
                city: "",
                state: "",
                zipCode: "",
                latitude: item.coordinate.latitude,
                longitude: item.coordinate.longitude,
                amenities: item.amenities.map { $0.name },
                parkingInfo: nil,
                publicTransit: nil,
                imageUrls: nil,
                accessibilityInfo: nil
            ),
            imageUrl: nil,
            thumbnailUrl: nil,
            averageRating: Double(item.rating) ?? 0.0,
            totalReviews: Int(item.reviewCount) ?? 0,
            tags: [],
            requirements: item.requirements,
            whatToBring: [],
            cancellationPolicy: "Standard cancellation policy applies",
            isOnline: false,
            meetingUrl: nil
        )
    }
}