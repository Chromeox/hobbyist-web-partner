import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: UUID
    let email: String
    let createdAt: Date
    let updatedAt: Date?
    
    var profile: UserProfile?
    var credits: UserCredits?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case profile
        case credits = "user_credits"
    }
}

struct UserProfile: Codable, Hashable {
    let userId: UUID
    let firstName: String?
    let lastName: String?
    let phoneNumber: String?
    let dateOfBirth: Date?
    let avatarUrl: String?
    let bio: String?
    let role: UserRole
    let preferences: UserPreferences?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneNumber = "phone_number"
        case dateOfBirth = "date_of_birth"
        case avatarUrl = "avatar_url"
        case bio
        case role
        case preferences
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
}

struct UserCredits: Codable, Hashable {
    let id: UUID
    let userId: UUID
    let creditBalance: Int
    let totalEarned: Int
    let totalSpent: Int
    let lastActivityAt: Date
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case creditBalance = "credit_balance"
        case totalEarned = "total_earned"
        case totalSpent = "total_spent"
        case lastActivityAt = "last_activity_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserPreferences: Codable, Hashable {
    let notificationsEnabled: Bool
    let emailUpdates: Bool
    let smsReminders: Bool
    let preferredCategories: [String]
    let searchRadius: Double
    
    enum CodingKeys: String, CodingKey {
        case notificationsEnabled = "notifications_enabled"
        case emailUpdates = "email_updates"
        case smsReminders = "sms_reminders"
        case preferredCategories = "preferred_categories"
        case searchRadius = "search_radius"
    }
}

enum UserRole: String, Codable, CaseIterable {
    case student = "student"
    case instructor = "instructor"
    case admin = "admin"
    case studioOwner = "studio_owner"
    
    var displayName: String {
        switch self {
        case .student: return "Student"
        case .instructor: return "Instructor"
        case .admin: return "Admin"
        case .studioOwner: return "Studio Owner"
        }
    }
}