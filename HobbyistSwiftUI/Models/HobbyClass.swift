import Foundation

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
        return ClassItem.sampleClasses
    }
    
    // Convert HobbyClass to ClassItem
    var toClassItem: ClassItem {
        ClassItem(
            id: UUID(uuidString: id) ?? UUID(),
            name: title,
            description: description,
            instructorId: UUID(uuidString: instructor.id) ?? UUID(),
            instructorName: instructor.name,
            venueId: UUID(uuidString: venue.id) ?? UUID(),
            venueName: venue.name,
            startTime: startDate,
            endTime: endDate,
            price: Decimal(price),
            maxCapacity: maxParticipants,
            currentEnrollment: enrolledCount,
            imageUrl: imageUrl,
            category: category.rawValue,
            level: difficulty.rawValue,
            isOnline: isOnline,
            meetingUrl: meetingUrl,
            status: "active",
            createdAt: Date(),
            updatedAt: nil
        )
    }
    
    // Create from ClassItem
    static func from(_ item: ClassItem) -> HobbyClass {
        HobbyClass(
            id: item.id.uuidString,
            title: item.name,
            description: item.description,
            category: ClassCategory(rawValue: item.category ?? "") ?? .other,
            difficulty: DifficultyLevel(rawValue: item.level ?? "") ?? .allLevels,
            price: NSDecimalNumber(decimal: item.price).doubleValue,
            startDate: item.startTime,
            endDate: item.endTime,
            duration: Calendar.current.dateComponents([.minute], from: item.startTime, to: item.endTime).minute ?? 60,
            maxParticipants: item.maxCapacity,
            enrolledCount: item.currentEnrollment,
            instructor: InstructorInfo(
                id: item.instructorId.uuidString,
                name: item.instructorName ?? "Unknown Instructor",
                bio: nil,
                profileImageUrl: nil,
                rating: 0.0,
                totalClasses: 0,
                totalStudents: 0,
                specialties: [],
                certifications: [],
                yearsOfExperience: 0,
                socialLinks: nil
            ),
            venue: VenueInfo(
                id: item.venueId.uuidString,
                name: item.venueName ?? "Unknown Venue",
                address: "",
                city: "",
                state: "",
                zipCode: "",
                latitude: 0.0,
                longitude: 0.0,
                amenities: [],
                parkingInfo: nil,
                publicTransit: nil,
                imageUrls: nil,
                accessibilityInfo: nil
            ),
            imageUrl: item.imageUrl,
            thumbnailUrl: nil,
            averageRating: 0.0,
            totalReviews: 0,
            tags: [],
            requirements: [],
            whatToBring: [],
            cancellationPolicy: "Standard cancellation policy applies",
            isOnline: item.isOnline,
            meetingUrl: item.meetingUrl
        )
    }
}