import Foundation

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
    
    enum CodingKeys: String, CodingKey {
        case classId = "class_id"
        case userId = "user_id"
        case participantCount = "participant_count"
        case specialRequests = "special_requests"
        case paymentId = "payment_id"
        case couponId = "coupon_id"
        case totalAmount = "total_amount"
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