import Foundation
import CoreLocation

struct ClassModel: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let instructorId: UUID
    let venueId: UUID?
    let categoryId: UUID?
    let startTime: Date
    let endTime: Date
    let duration: Int
    let maxParticipants: Int
    let currentParticipants: Int
    let creditCost: Int
    let price: Decimal?
    let allowCreditPayment: Bool
    let difficultyLevel: DifficultyLevel
    let requirements: [String]?
    let imageUrl: String?
    let status: ClassStatus
    let isRecurring: Bool
    let recurringPattern: RecurringPattern?
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date?
    
    var instructor: Instructor?
    var venue: Venue?
    var category: Category?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case instructorId = "instructor_id"
        case venueId = "venue_id"
        case categoryId = "category_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case duration
        case maxParticipants = "max_participants"
        case currentParticipants = "current_participants"
        case creditCost = "credit_cost"
        case price
        case allowCreditPayment = "allow_credit_payment"
        case difficultyLevel = "difficulty_level"
        case requirements
        case imageUrl = "image_url"
        case status
        case isRecurring = "is_recurring"
        case recurringPattern = "recurring_pattern"
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case instructor
        case venue
        case category
    }
    
    var availableSpots: Int {
        max(0, maxParticipants - currentParticipants)
    }
    
    var isFull: Bool {
        availableSpots == 0
    }
    
    var formattedDuration: String {
        let hours = duration / 60
        let minutes = duration % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)min"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)min"
        }
    }
}

struct Category: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let iconName: String?
    let colorHex: String?
    let parentId: UUID?
    let displayOrder: Int
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case parentId = "parent_id"
        case displayOrder = "display_order"
        case isActive = "is_active"
    }
}

struct RecurringPattern: Codable, Hashable {
    let frequency: RecurrenceFrequency
    let interval: Int
    let daysOfWeek: [Int]?
    let endDate: Date?
    let occurrences: Int?
    
    enum CodingKeys: String, CodingKey {
        case frequency
        case interval
        case daysOfWeek = "days_of_week"
        case endDate = "end_date"
        case occurrences
    }
}

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case allLevels = "all_levels"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .allLevels: return "All Levels"
        }
    }
    
    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "orange"
        case .advanced: return "red"
        case .allLevels: return "blue"
        }
    }
}

enum ClassStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    case postponed = "postponed"
    
    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .postponed: return "Postponed"
        }
    }
}