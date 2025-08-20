import Foundation

struct Booking: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let classId: UUID
    let status: BookingStatus
    let paymentMethod: PaymentMethod
    let creditsUsed: Int
    let amountPaid: Decimal?
    let bookingDate: Date
    let confirmationCode: String?
    let cancellationReason: String?
    let cancelledAt: Date?
    let notes: String?
    let checkInTime: Date?
    let rating: Int?
    let review: String?
    let createdAt: Date
    let updatedAt: Date?
    
    var classDetails: ClassModel?
    var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case classId = "class_id"
        case status
        case paymentMethod = "payment_method"
        case creditsUsed = "credits_used"
        case amountPaid = "amount_paid"
        case bookingDate = "booking_date"
        case confirmationCode = "confirmation_code"
        case cancellationReason = "cancellation_reason"
        case cancelledAt = "cancelled_at"
        case notes
        case checkInTime = "check_in_time"
        case rating
        case review
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case classDetails = "class"
        case user
    }
    
    var isUpcoming: Bool {
        guard let classDetails = classDetails else { return false }
        return classDetails.startTime > Date() && status == .confirmed
    }
    
    var isPast: Bool {
        guard let classDetails = classDetails else { return false }
        return classDetails.endTime < Date()
    }
    
    var canCancel: Bool {
        guard let classDetails = classDetails else { return false }
        let hoursUntilClass = classDetails.startTime.timeIntervalSince(Date()) / 3600
        return status == .confirmed && hoursUntilClass > 24
    }
    
    var canReview: Bool {
        return isPast && status == .completed && rating == nil
    }
}

enum BookingStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case confirmed = "confirmed"
    case cancelled = "cancelled"
    case completed = "completed"
    case noShow = "no_show"
    case waitlisted = "waitlisted"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .cancelled: return "Cancelled"
        case .completed: return "Completed"
        case .noShow: return "No Show"
        case .waitlisted: return "Waitlisted"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "green"
        case .cancelled: return "gray"
        case .completed: return "blue"
        case .noShow: return "red"
        case .waitlisted: return "yellow"
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable {
    case card = "card"
    case credits = "credits"
    case applePay = "apple_pay"
    case googlePay = "google_pay"
    
    var displayName: String {
        switch self {
        case .card: return "Credit Card"
        case .credits: return "Credits"
        case .applePay: return "Apple Pay"
        case .googlePay: return "Google Pay"
        }
    }
    
    var iconName: String {
        switch self {
        case .card: return "creditcard"
        case .credits: return "star.circle"
        case .applePay: return "applelogo"
        case .googlePay: return "g.circle"
        }
    }
}