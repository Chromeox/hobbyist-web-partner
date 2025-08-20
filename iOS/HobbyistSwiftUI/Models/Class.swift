import Foundation

// MARK: - HobbyClass Model

struct HobbyClass: Identifiable, Codable, Equatable {
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
    let instructor: Instructor
    let venue: Venue
    let imageUrl: String?
    let thumbnailUrl: String?
    let averageRating: Double
    let totalReviews: Int
    let tags: [String]
    let requirements: [String]
    let whatToBring: [String]
    let cancellationPolicy: String?
    let isOnline: Bool
    let meetingUrl: String?
    
    var availableSpots: Int {
        maxParticipants - enrolledCount
    }
    
    var isAvailable: Bool {
        availableSpots > 0 && startDate > Date()
    }
    
    var isFull: Bool {
        availableSpots <= 0
    }
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }
    
    var formattedDuration: String {
        let hours = duration / 60
        let minutes = duration % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case difficulty
        case price
        case startDate = "start_date"
        case endDate = "end_date"
        case duration
        case maxParticipants = "max_participants"
        case enrolledCount = "enrolled_count"
        case instructor
        case venue
        case imageUrl = "image_url"
        case thumbnailUrl = "thumbnail_url"
        case averageRating = "average_rating"
        case totalReviews = "total_reviews"
        case tags
        case requirements
        case whatToBring = "what_to_bring"
        case cancellationPolicy = "cancellation_policy"
        case isOnline = "is_online"
        case meetingUrl = "meeting_url"
    }
}

// MARK: - Instructor Model

struct Instructor: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let bio: String
    let profileImageUrl: String?
    let rating: Double
    let totalClasses: Int
    let totalStudents: Int
    let specialties: [String]
    let certifications: [String]
    let yearsOfExperience: Int
    let socialLinks: SocialLinks?
    
    struct SocialLinks: Codable, Equatable {
        let website: String?
        let instagram: String?
        let facebook: String?
        let linkedin: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case bio
        case profileImageUrl = "profile_image_url"
        case rating
        case totalClasses = "total_classes"
        case totalStudents = "total_students"
        case specialties
        case certifications
        case yearsOfExperience = "years_of_experience"
        case socialLinks = "social_links"
    }
}

// MARK: - Venue Model

struct Venue: Identifiable, Codable, Equatable {
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
    let imageUrls: [String]
    let accessibilityInfo: String?
    
    var fullAddress: String {
        "\(address), \(city), \(state) \(zipCode)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case city
        case state
        case zipCode = "zip_code"
        case latitude
        case longitude
        case amenities
        case parkingInfo = "parking_info"
        case publicTransit = "public_transit"
        case imageUrls = "image_urls"
        case accessibilityInfo = "accessibility_info"
    }
}

// MARK: - Enums

enum ClassCategory: String, CaseIterable, Codable {
    case arts = "Arts & Crafts"
    case cooking = "Cooking"
    case fitness = "Fitness"
    case music = "Music"
    case technology = "Technology"
    case languages = "Languages"
    case outdoors = "Outdoors"
    case wellness = "Wellness"
    case business = "Business"
    case photography = "Photography"
    case dance = "Dance"
    case writing = "Writing"
    
    var icon: String {
        switch self {
        case .arts: return "paintbrush"
        case .cooking: return "fork.knife"
        case .fitness: return "figure.run"
        case .music: return "music.note"
        case .technology: return "laptopcomputer"
        case .languages: return "globe"
        case .outdoors: return "leaf"
        case .wellness: return "heart"
        case .business: return "briefcase"
        case .photography: return "camera"
        case .dance: return "figure.dance"
        case .writing: return "pencil"
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