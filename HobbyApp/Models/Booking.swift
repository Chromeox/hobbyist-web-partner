import Foundation

// Import PaymentMethodType from PaymentService
enum PaymentMethodType: String, Codable {
    case card = "card"
    case applePay = "apple_pay" 
    case credits = "credits"
    case bankTransfer = "bank_transfer"
}

// MARK: - Booking Model
// Note: Venue and Instructor models are defined in Venue.swift and Instructor.swift

struct Booking: Identifiable, Codable, Equatable {
    let id: UUID
    let classId: UUID
    let className: String
    let userId: UUID
    let participantCount: Int
    let specialRequests: String?
    let paymentId: UUID?
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
    
    // Custom Equatable implementation
    static func == (lhs: Booking, rhs: Booking) -> Bool {
        return lhs.id == rhs.id &&
               lhs.classId == rhs.classId &&
               lhs.userId == rhs.userId &&
               lhs.status == rhs.status &&
               lhs.totalAmount == rhs.totalAmount
    }
}

// MARK: - Booking Status
// Note: BookingRequest and EmergencyContact models are defined in BookingService.swift

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

// Achievement model defined in Services/GamificationServiceProtocol.swift
// NotificationSettings model defined in Services/NotificationServiceProtocol.swift