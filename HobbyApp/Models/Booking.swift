import Foundation

// Import PaymentMethodType from PaymentService
enum PaymentMethodType: String, Codable {
    case card = "card"
    case applePay = "apple_pay" 
    case credits = "credits"
    case bankTransfer = "bank_transfer"
}

// MARK: - Booking Model

struct Booking: Identifiable, Codable, Equatable {
    let id: String
    let classId: String
    let className: String
    let userId: String
    let participantCount: Int
    let specialRequests: String?
    let paymentId: String
    let totalAmount: Double
    let status: BookingStatus
    let createdAt: Date
    let updatedAt: Date
    let classStartDate: Date
    let classEndDate: Date
    let venue: Venue
    let instructor: Instructor
    let confirmationCode: String
    let qrCode: String?
    
    // Enhanced payment fields
    let paymentMethod: PaymentMethodType?
    let paymentIntentId: String?
    let paidWithCredits: Bool
    let creditsUsed: Int?
    let discountApplied: Double?
    let processingFee: Double?
    let refundableAmount: Double?
    
    // Availability and scheduling
    let availableSpotsAtBooking: Int?
    let waitlistPosition: Int?
    let isWaitlisted: Bool
    let remindersSent: [Date]?
    let cancellationDeadline: Date?
    
    var canBeCancelled: Bool {
        status == .confirmed && classStartDate.timeIntervalSinceNow > 24 * 60 * 60
    }
    
    var canBeModified: Bool {
        status == .confirmed && classStartDate.timeIntervalSinceNow > 48 * 60 * 60
    }
    
    var canBeRefunded: Bool {
        canBeCancelled
    }
    
    var refundAmount: Double {
        guard canBeRefunded else { return 0 }
        let hoursUntilClass = classStartDate.timeIntervalSinceNow / 3600
        
        if hoursUntilClass > 72 {
            return totalAmount // Full refund
        } else if hoursUntilClass > 48 {
            return totalAmount * 0.75 // 75% refund
        } else {
            return totalAmount * 0.5 // 50% refund
        }
    }
    
    var formattedConfirmationCode: String {
        // Format as XXXX-XXXX-XXXX
        let cleaned = confirmationCode.replacingOccurrences(of: "-", with: "")
        var formatted = ""
        for (index, char) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += "-"
            }
            formatted += String(char)
        }
        return formatted
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case classId = "class_id"
        case className = "class_name"
        case userId = "user_id"
        case participantCount = "participant_count"
        case specialRequests = "special_requests"
        case paymentId = "payment_id"
        case totalAmount = "total_amount"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case classStartDate = "class_start_date"
        case classEndDate = "class_end_date"
        case venue
        case instructor
        case confirmationCode = "confirmation_code"
        case qrCode = "qr_code"
        
        // Enhanced payment fields
        case paymentMethod = "payment_method"
        case paymentIntentId = "payment_intent_id"
        case paidWithCredits = "paid_with_credits"
        case creditsUsed = "credits_used"
        case discountApplied = "discount_applied"
        case processingFee = "processing_fee"
        case refundableAmount = "refundable_amount"
        
        // Availability and scheduling
        case availableSpotsAtBooking = "available_spots_at_booking"
        case waitlistPosition = "waitlist_position"
        case isWaitlisted = "is_waitlisted"
        case remindersSent = "reminders_sent"
        case cancellationDeadline = "cancellation_deadline"
    }
}

// MARK: - Booking Request

struct BookingRequest: Codable {
    let classId: String
    let userId: String
    let participantCount: Int
    let specialRequests: String?
    let paymentId: String
    let couponId: String?
    let totalAmount: Double
    
    // Enhanced payment information
    let paymentMethod: PaymentMethodType
    let paymentIntentId: String?
    let creditsUsed: Int?
    let discountApplied: Double?
    let processingFee: Double?
    
    // Participant details
    let participantNames: [String]?
    let emergencyContact: EmergencyContact?
    let equipmentRental: [String]?
    let experienceLevel: String?
    
    enum CodingKeys: String, CodingKey {
        case classId = "class_id"
        case userId = "user_id"
        case participantCount = "participant_count"
        case specialRequests = "special_requests"
        case paymentId = "payment_id"
        case couponId = "coupon_id"
        case totalAmount = "total_amount"
        
        // Enhanced payment information
        case paymentMethod = "payment_method"
        case paymentIntentId = "payment_intent_id"
        case creditsUsed = "credits_used"
        case discountApplied = "discount_applied"
        case processingFee = "processing_fee"
        
        // Participant details
        case participantNames = "participant_names"
        case emergencyContact = "emergency_contact"
        case equipmentRental = "equipment_rental"
        case experienceLevel = "experience_level"
    }
}

// MARK: - Emergency Contact

struct EmergencyContact: Codable {
    let name: String
    let phone: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case phone
    }
}

// MARK: - Booking Status

enum BookingStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case confirmed = "confirmed"
    case cancelled = "cancelled"
    case completed = "completed"
    case noShow = "no_show"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .cancelled: return "Cancelled"
        case .completed: return "Completed"
        case .noShow: return "No Show"
        case .refunded: return "Refunded"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "green"
        case .cancelled: return "red"
        case .completed: return "blue"
        case .noShow: return "gray"
        case .refunded: return "purple"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .confirmed: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        case .completed: return "star.fill"
        case .noShow: return "person.fill.xmark"
        case .refunded: return "arrow.uturn.backward.circle"
        }
    }
}

// MARK: - Booking Errors

enum BookingError: LocalizedError {
    case classFullyBooked
    case invalidPayment
    case userNotAuthenticated
    case bookingNotFound
    case cancellationNotAllowed
    case modificationNotAllowed
    case refundNotAllowed
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .classFullyBooked:
            return "This class is fully booked"
        case .invalidPayment:
            return "Payment processing failed. Please try again"
        case .userNotAuthenticated:
            return "Please sign in to complete your booking"
        case .bookingNotFound:
            return "Booking not found"
        case .cancellationNotAllowed:
            return "This booking cannot be cancelled at this time"
        case .modificationNotAllowed:
            return "This booking cannot be modified at this time"
        case .refundNotAllowed:
            return "This booking is not eligible for a refund"
        case .networkError:
            return "Network error. Please check your connection"
        case .unknown(let message):
            return message
        }
    }
}

// Achievement model defined in Services/GamificationServiceProtocol.swift
// NotificationSettings model defined in Services/NotificationServiceProtocol.swift