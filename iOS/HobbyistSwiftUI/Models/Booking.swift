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

// MARK: - Achievement Model

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let unlockedAt: Date?
    let progress: Double // 0.0 to 1.0
    let requirement: Int
    let current: Int
    let category: AchievementCategory
    let points: Int
    
    var isUnlocked: Bool {
        unlockedAt != nil
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    enum AchievementCategory: String, Codable {
        case attendance = "attendance"
        case exploration = "exploration"
        case social = "social"
        case milestone = "milestone"
        case special = "special"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case iconName = "icon_name"
        case unlockedAt = "unlocked_at"
        case progress
        case requirement
        case current
        case category
        case points
    }
}

// MARK: - Notification Settings

struct NotificationSettings: Codable {
    var pushEnabled: Bool = true
    var emailEnabled: Bool = true
    var smsEnabled: Bool = false
    var bookingReminders: Bool = true
    var classUpdates: Bool = true
    var promotionalOffers: Bool = false
    var newClassAlerts: Bool = true
    var instructorUpdates: Bool = true
    var reminderTiming: ReminderTiming = .oneDay
    var quietHoursEnabled: Bool = false
    var quietHoursStart: String = "22:00"
    var quietHoursEnd: String = "08:00"
    
    enum ReminderTiming: String, CaseIterable, Codable {
        case fifteenMinutes = "15_minutes"
        case oneHour = "1_hour"
        case twoHours = "2_hours"
        case oneDay = "1_day"
        case twoDays = "2_days"
        
        var displayName: String {
            switch self {
            case .fifteenMinutes: return "15 minutes before"
            case .oneHour: return "1 hour before"
            case .twoHours: return "2 hours before"
            case .oneDay: return "1 day before"
            case .twoDays: return "2 days before"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case pushEnabled = "push_enabled"
        case emailEnabled = "email_enabled"
        case smsEnabled = "sms_enabled"
        case bookingReminders = "booking_reminders"
        case classUpdates = "class_updates"
        case promotionalOffers = "promotional_offers"
        case newClassAlerts = "new_class_alerts"
        case instructorUpdates = "instructor_updates"
        case reminderTiming = "reminder_timing"
        case quietHoursEnabled = "quiet_hours_enabled"
        case quietHoursStart = "quiet_hours_start"
        case quietHoursEnd = "quiet_hours_end"
    }
}