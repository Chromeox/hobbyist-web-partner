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

struct HobbyClass: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: String
    let price: Double
    let duration: Int // in minutes
    let imageURL: String?
    let instructorId: String
    let instructorName: String
    let venueId: String
    let venueName: String
    let address: String
    let maxParticipants: Int
    let currentParticipants: Int
    let rating: Double
    let reviewCount: Int
    let startDate: Date
    let endDate: Date
    let tags: [String]
    let requirements: [String]?
    let isBookmarked: Bool
    let creditValue: Int?
}

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

struct Booking: Identifiable, Codable {
    let id: String
    let userId: String
    let classId: String
    let className: String
    let instructorName: String
    let venueName: String
    let address: String
    let startDate: Date
    let endDate: Date
    let status: BookingStatus
    let price: Double
    let creditUsed: Int?
    let createdAt: Date
    let qrCode: String?
    
    enum BookingStatus: String, Codable {
        case pending = "pending"
        case confirmed = "confirmed"
        case cancelled = "cancelled"
        case completed = "completed"
        case noShow = "no_show"
    }
}

struct BookingRequest: Codable {
    let classId: String
    let userId: String
    let useCredits: Bool
    let paymentMethodId: String?
}

struct Instructor: Identifiable, Codable {
    let id: String
    let name: String
    let bio: String
    let imageURL: String?
    let specialties: [String]
    let rating: Double
    let reviewCount: Int
    let yearsExperience: Int
    let certifications: [String]
    let socialLinks: [String: String]?
}

struct Review: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let userAvatar: String?
    let classId: String
    let rating: Int
    let comment: String
    let createdAt: Date
    let helpful: Int
    let images: [String]?
}

struct ReviewRequest: Codable {
    let classId: String
    let rating: Int
    let comment: String
    let images: [String]?
}

struct UserProfile: Codable {
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

struct CreditTransaction: Identifiable, Codable {
    let id: String
    let userId: String
    let type: TransactionType
    let amount: Int
    let description: String
    let createdAt: Date
    let expiresAt: Date?
    
    enum TransactionType: String, Codable {
        case purchase = "purchase"
        case usage = "usage"
        case refund = "refund"
        case expired = "expired"
    }
}