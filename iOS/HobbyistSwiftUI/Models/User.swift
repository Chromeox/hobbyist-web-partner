import Foundation

// MARK: - User Model

struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    let fullName: String
    let createdAt: Date
    var profileImageUrl: String?
    var phoneNumber: String?
    var bio: String?
    var isEmailVerified: Bool = false
    var lastActiveAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case createdAt = "created_at"
        case profileImageUrl = "profile_image_url"
        case phoneNumber = "phone_number"
        case bio
        case isEmailVerified = "is_email_verified"
        case lastActiveAt = "last_active_at"
    }
}

// MARK: - User Statistics

struct UserStatistics: Codable {
    let totalBookings: Int
    let totalSpent: Double
    let classesAttended: Int
    let favoriteCategory: ClassCategory?
    let memberSince: Date
    let lastActiveDate: Date
    let upcomingClasses: Int
    let completedClasses: Int
    let cancelledClasses: Int
    let averageRating: Double?
    let totalReviews: Int
    
    enum CodingKeys: String, CodingKey {
        case totalBookings = "total_bookings"
        case totalSpent = "total_spent"
        case classesAttended = "classes_attended"
        case favoriteCategory = "favorite_category"
        case memberSince = "member_since"
        case lastActiveDate = "last_active_date"
        case upcomingClasses = "upcoming_classes"
        case completedClasses = "completed_classes"
        case cancelledClasses = "cancelled_classes"
        case averageRating = "average_rating"
        case totalReviews = "total_reviews"
    }
}

// MARK: - User Preferences

struct UserPreferences: Codable {
    var preferredCategories: [ClassCategory] = []
    var preferredDifficulty: DifficultyLevel?
    var maxPrice: Double = 500
    var preferredDays: [WeekDay] = []
    var preferredTimeSlots: [TimeSlot] = []
    var notificationRadius: Double = 10 // miles
    var language: String = "en"
    var currency: String = "USD"
    var timezone: String = TimeZone.current.identifier
    
    enum WeekDay: String, CaseIterable, Codable {
        case monday, tuesday, wednesday, thursday, friday, saturday, sunday
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    enum TimeSlot: String, CaseIterable, Codable {
        case earlyMorning = "early_morning" // 6am-9am
        case morning = "morning" // 9am-12pm
        case afternoon = "afternoon" // 12pm-3pm
        case lateAfternoon = "late_afternoon" // 3pm-6pm
        case evening = "evening" // 6pm-9pm
        case night = "night" // 9pm-12am
        
        var displayName: String {
            switch self {
            case .earlyMorning: return "Early Morning (6am-9am)"
            case .morning: return "Morning (9am-12pm)"
            case .afternoon: return "Afternoon (12pm-3pm)"
            case .lateAfternoon: return "Late Afternoon (3pm-6pm)"
            case .evening: return "Evening (6pm-9pm)"
            case .night: return "Night (9pm-12am)"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case preferredCategories = "preferred_categories"
        case preferredDifficulty = "preferred_difficulty"
        case maxPrice = "max_price"
        case preferredDays = "preferred_days"
        case preferredTimeSlots = "preferred_time_slots"
        case notificationRadius = "notification_radius"
        case language
        case currency
        case timezone
    }
}

// MARK: - Profile Update

struct ProfileUpdate: Codable {
    let fullName: String
    let bio: String?
    let phoneNumber: String?
    let profileImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case bio
        case phoneNumber = "phone_number"
        case profileImageUrl = "profile_image_url"
    }
}