import Foundation
import SwiftUI

// MARK: - User Models

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var fullName: String
    var profileImageURL: URL?
    var phoneNumber: String?
    var dateOfBirth: Date?
    var createdAt: Date
    var updatedAt: Date
    var isVerified: Bool
    var preferences: UserPreferences?
    var membershipType: MembershipType
    
    enum MembershipType: String, Codable {
        case free = "free"
        case basic = "basic"
        case premium = "premium"
        case unlimited = "unlimited"
    }
}

struct UserProfile: Codable {
    var id: String
    var fullName: String
    var email: String
    var phoneNumber: String?
    var dateOfBirth: Date?
    var bio: String?
    var profileImageURL: URL?
    var emergencyContact: EmergencyContact?
    var fitnessGoals: [String]
    var medicalConditions: [String]
    var preferredCategories: [ClassCategory]
}

struct UserPreferences: Codable {
    var notificationsEnabled: Bool
    var classReminders: Bool
    var marketingEmails: Bool
    var darkModeEnabled: Bool
    var preferredLanguage: String
    var measurementUnit: MeasurementUnit
    var defaultPaymentMethodId: String?
    
    enum MeasurementUnit: String, Codable {
        case imperial, metric
    }
}

struct EmergencyContact: Codable {
    var name: String
    var relationship: String
    var phoneNumber: String
}

// MARK: - Class Models

struct ClassModel: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var category: ClassCategory
    var subcategory: String?
    var instructor: Instructor
    var duration: Int // in minutes
    var startTime: Date
    var endTime: Date
    var capacity: Int
    var spotsAvailable: Int
    var price: Double
    var originalPrice: Double?
    var location: ClassLocation
    var difficulty: DifficultyLevel
    var images: [URL]
    var tags: [String]
    var equipment: [String]
    var isOnline: Bool
    var zoomLink: URL?
    var rating: Double
    var reviewCount: Int
    var isFeatured: Bool
    var cancellationDeadline: Date
}

struct Instructor: Identifiable, Codable {
    let id: String
    var name: String
    var bio: String
    var profileImageURL: URL?
    var certifications: [String]
    var specialties: [String]
    var rating: Double
    var totalClasses: Int
    var yearsExperience: Int
}

struct ClassLocation: Codable {
    var id: String
    var name: String
    var address: String
    var city: String
    var state: String
    var zipCode: String
    var latitude: Double
    var longitude: Double
    var amenities: [String]
    var parkingAvailable: Bool
    var publicTransportNearby: Bool
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case allLevels = "All Levels"
    
    var displayName: String { rawValue }
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        case .allLevels: return .blue
        }
    }
}

struct ClassFilter {
    var categories: [ClassCategory]?
    var difficulty: DifficultyLevel?
    var priceRange: ClosedRange<Double>?
    var dateRange: DateInterval?
    var location: ClassLocation?
    var maxDistance: Double? // in miles
    var instructor: String?
    var isOnline: Bool?
    var minRating: Double?
}

// MARK: - Booking Models

struct BookingModel: Identifiable, Codable {
    let id: String
    var userId: String
    var classId: String
    var classDetails: ClassModel
    var bookingDate: Date
    var spots: Int
    var totalAmount: Double
    var status: BookingStatus
    var paymentMethod: PaymentMethod?
    var confirmationCode: String
    var qrCode: String?
    var notes: String?
    var checkedIn: Bool
    var checkInTime: Date?
    var cancellationReason: String?
    var refundAmount: Double?
    
    enum BookingStatus: String, Codable {
        case pending = "pending"
        case confirmed = "confirmed"
        case cancelled = "cancelled"
        case completed = "completed"
        case noShow = "no_show"
        case refunded = "refunded"
    }
}

// MARK: - Payment Models

struct PaymentMethod: Identifiable, Codable {
    let id: String
    var type: PaymentType
    var last4: String
    var brand: String?
    var expiryMonth: Int?
    var expiryYear: Int?
    var isDefault: Bool
    var billingAddress: BillingAddress?
    
    enum PaymentType: String, Codable {
        case card = "card"
        case applePay = "apple_pay"
        case googlePay = "google_pay"
        case bankAccount = "bank_account"
    }
}

struct BillingAddress: Codable {
    var line1: String
    var line2: String?
    var city: String
    var state: String
    var postalCode: String
    var country: String
}

struct PaymentResult: Codable {
    let transactionId: String
    let status: PaymentStatus
    let amount: Double
    let currency: String
    let timestamp: Date
    let receiptURL: URL?
    let errorMessage: String?
    
    enum PaymentStatus: String, Codable {
        case succeeded = "succeeded"
        case processing = "processing"
        case failed = "failed"
        case cancelled = "cancelled"
    }
}

struct PaymentTransaction: Identifiable, Codable {
    let id: String
    var amount: Double
    var currency: String
    var status: PaymentResult.PaymentStatus
    var paymentMethod: PaymentMethod
    var description: String
    var timestamp: Date
    var refundedAmount: Double?
    var metadata: [String: String]?
}

// MARK: - Feedback Models

struct FeedbackModel: Identifiable, Codable {
    let id: String
    var userId: String
    var type: FeedbackType
    var title: String
    var description: String
    var rating: Int?
    var category: String?
    var attachments: [URL]
    var status: FeedbackStatus
    var createdAt: Date
    var updatedAt: Date
    var response: String?
    var respondedAt: Date?
    
    enum FeedbackStatus: String, Codable {
        case pending = "pending"
        case inReview = "in_review"
        case responded = "responded"
        case closed = "closed"
    }
}

struct BugReport: Codable {
    var title: String
    var description: String
    var severity: BugSeverity
    var reproducible: Bool
    var steps: [String]
    var expectedBehavior: String
    var actualBehavior: String
    var deviceInfo: DeviceInfo
    var appVersion: String
    var screenshots: [Data]
    
    enum BugSeverity: String, Codable, CaseIterable {
        case critical = "Critical"
        case major = "Major"
        case minor = "Minor"
        case cosmetic = "Cosmetic"
    }
}

struct FeatureRequest: Codable {
    var title: String
    var description: String
    var category: String
    var priority: Priority
    var useCase: String
    var currentWorkaround: String?
    
    enum Priority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"
    }
}

struct ExperienceRating: Codable {
    var overallRating: Int // 1-5
    var categoryRatings: [String: Int]
    var likes: [String]
    var improvements: [String]
    var wouldRecommend: Bool
    var additionalComments: String?
}

struct DeviceInfo: Codable {
    var model: String
    var osVersion: String
    var appVersion: String
    var buildNumber: String
    var screenSize: String
    var networkType: String
    var batteryLevel: Float
    var availableStorage: Int64
}

// MARK: - Error Models

enum AppError: LocalizedError {
    case networkError(String)
    case authenticationError(String)
    case validationError(String)
    case serverError(String)
    case paymentError(String)
    case bookingError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .serverError(let message):
            return "Server Error: \(message)"
        case .paymentError(let message):
            return "Payment Error: \(message)"
        case .bookingError(let message):
            return "Booking Error: \(message)"
        case .unknown(let message):
            return "Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .authenticationError:
            return "Please sign in again to continue."
        case .validationError:
            return "Please check your input and try again."
        case .serverError:
            return "Something went wrong on our end. Please try again later."
        case .paymentError:
            return "Please check your payment details and try again."
        case .bookingError:
            return "Please try booking again or contact support."
        case .unknown:
            return "Please try again or contact support if the issue persists."
        }
    }
}

// MARK: - Network Models

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let body: Data?
    let queryItems: [URLQueryItem]?
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }
}