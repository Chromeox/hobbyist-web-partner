import Foundation
import Combine

protocol DataServiceProtocol {
    // Classes
    func fetchClasses(filters: ClassFilters?) async throws -> [HobbyClass]
    func fetchClass(id: String) async throws -> HobbyClass
    func searchClasses(query: String) async throws -> [HobbyClass]
    func fetchFeaturedClasses() async throws -> [HobbyClass]
    func fetchRecommendedClasses() async throws -> [HobbyClass]
    
    // Bookings
    func fetchUserBookings(userId: String) async throws -> [Booking]
    func createBooking(_ booking: BookingRequest) async throws -> Booking
    func cancelBooking(id: String) async throws
    func fetchBookingDetails(id: String) async throws -> Booking
    
    // Instructors
    func fetchInstructors() async throws -> [Instructor]
    func fetchInstructor(id: String) async throws -> Instructor
    
    // Reviews
    func fetchReviews(classId: String) async throws -> [Review]
    func createReview(_ review: ReviewRequest) async throws -> Review
    
    // User Profile
    func fetchUserProfile(userId: String) async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile
    
    // Credits
    func fetchUserCredits(userId: String) async throws -> UserCredits
    func purchaseCreditPack(packId: String) async throws -> CreditTransaction
}

// MARK: - Data Models
// Note: HobbyClass, Instructor, and Venue are defined in Models/Class.swift

struct ClassFilters {
    var category: String?
    var minPrice: Double?
    var maxPrice: Double?
    var startDate: Date?
    var endDate: Date?
    var location: String?
    var radius: Double? // in kilometers
    var sortBy: SortOption = .relevance
    
    enum SortOption: String {
        case relevance = "relevance"
        case price = "price"
        case rating = "rating"
        case date = "date"
        case distance = "distance"
    }
}

// Booking model defined in Models/Booking.swift

// BookingRequest model defined in Models/Booking.swift


// Review model defined in Models/Review.swift

struct ReviewRequest: Codable {
    let classId: String
    let rating: Int
    let comment: String
    let images: [String]?
}

struct UserProfileData: Codable {
    let id: String
    var fullName: String
    var email: String
    var phoneNumber: String?
    var bio: String?
    var avatarURL: String?
    var interests: [String]
    var fitnessLevel: String?
    var dateOfBirth: Date?
    var emergencyContact: EmergencyContact?
    var preferences: UserPreferences
    
    struct EmergencyContact: Codable {
        var name: String
        var phoneNumber: String
        var relationship: String
    }
    
    struct UserPreferences: Codable {
        var notifications: NotificationPreferences
        var privacy: PrivacySettings
        
        struct NotificationPreferences: Codable {
            var classReminders: Bool = true
            var newClasses: Bool = true
            var promotions: Bool = false
            var reviews: Bool = true
        }
        
        struct PrivacySettings: Codable {
            var profileVisibility: String = "public"
            var showBookingHistory: Bool = false
        }
    }
}

struct UserCredits: Codable {
    let userId: String
    let balance: Int
    let totalPurchased: Int
    let totalUsed: Int
    let expiringCredits: [ExpiringCredit]
    let transactions: [CreditTransaction]
    
    struct ExpiringCredit: Codable {
        let amount: Int
        let expiryDate: Date
    }
}

// CreditTransaction model defined in Models/Payment.swift