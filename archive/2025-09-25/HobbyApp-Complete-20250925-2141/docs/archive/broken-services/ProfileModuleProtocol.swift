import Foundation
import SwiftUI

// MARK: - Profile Module Protocol and Models

/// Protocol defining all profile operations for the modular architecture
protocol ProfileModuleProtocol: ModularServiceProtocol {
    /// Current user profile state
    var currentProfile: UserProfile? { get }

    /// Profile completion status
    var profileCompletionPercentage: Double { get }

    /// Create or update user profile
    func saveProfile(_ profile: UserProfile) async throws

    /// Load user profile
    func loadProfile() async throws -> UserProfile?

    /// Update specific profile fields
    func updateProfileField(_ field: ProfileField, value: Any) async throws

    /// Upload and set profile image
    func updateProfileImage(_ imageData: Data) async throws -> String

    /// Get profile completion requirements
    func getProfileRequirements() -> [ProfileRequirement]

    /// Check if profile meets minimum requirements
    func validateProfile() -> ProfileValidationResult

    /// Delete user profile
    func deleteProfile() async throws
}

// MARK: - User Profile Model

struct UserProfile: Codable, Equatable {
    let id: String
    let userId: String
    let fullName: String
    let email: String
    let profileImageUrl: String?
    let bio: String?
    let experienceLevel: ExperienceLevel
    let interests: [String]
    let preferredTimes: [String]
    let budgetRange: BudgetRange
    let location: ProfileLocation?
    let socialLinks: [SocialLink]
    let preferences: ProfilePreferences
    let createdAt: Date
    let updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        fullName: String,
        email: String,
        profileImageUrl: String? = nil,
        bio: String? = nil,
        experienceLevel: ExperienceLevel = .beginner,
        interests: [String] = [],
        preferredTimes: [String] = [],
        budgetRange: BudgetRange = .budget50to100,
        location: ProfileLocation? = nil,
        socialLinks: [SocialLink] = [],
        preferences: ProfilePreferences = ProfilePreferences(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.fullName = fullName
        self.email = email
        self.profileImageUrl = profileImageUrl
        self.bio = bio
        self.experienceLevel = experienceLevel
        self.interests = interests
        self.preferredTimes = preferredTimes
        self.budgetRange = budgetRange
        self.location = location
        self.socialLinks = socialLinks
        self.preferences = preferences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Calculate profile completion percentage
    var completionPercentage: Double {
        let totalFields = 10.0
        var completedFields = 0.0

        if !fullName.isEmpty { completedFields += 1 }
        if !email.isEmpty { completedFields += 1 }
        if profileImageUrl != nil { completedFields += 1 }
        if bio != nil && !bio!.isEmpty { completedFields += 1 }
        if !interests.isEmpty { completedFields += 1 }
        if !preferredTimes.isEmpty { completedFields += 1 }
        if location != nil { completedFields += 1 }
        if !socialLinks.isEmpty { completedFields += 1 }
        if experienceLevel != .beginner { completedFields += 1 }
        if budgetRange != .budget50to100 { completedFields += 1 }

        return completedFields / totalFields
    }

    /// Check if profile meets minimum requirements for booking
    var meetsMinimumRequirements: Bool {
        return !fullName.isEmpty && !email.isEmpty && !interests.isEmpty
    }
}

// MARK: - Supporting Models

enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"

    var displayName: String {
        switch self {
        case .beginner:
            return "Beginner"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        case .expert:
            return "Expert"
        }
    }

    var description: String {
        switch self {
        case .beginner:
            return "New to most activities"
        case .intermediate:
            return "Some experience in various activities"
        case .advanced:
            return "Skilled in multiple areas"
        case .expert:
            return "Highly experienced across activities"
        }
    }
}

enum BudgetRange: String, Codable, CaseIterable {
    case under25 = "under_25"
    case budget25to50 = "25_to_50"
    case budget50to100 = "50_to_100"
    case budget100to200 = "100_to_200"
    case over200 = "over_200"

    var displayName: String {
        switch self {
        case .under25:
            return "Under $25"
        case .budget25to50:
            return "$25 - $50"
        case .budget50to100:
            return "$50 - $100"
        case .budget100to200:
            return "$100 - $200"
        case .over200:
            return "Over $200"
        }
    }

    var range: ClosedRange<Int> {
        switch self {
        case .under25:
            return 0...25
        case .budget25to50:
            return 25...50
        case .budget50to100:
            return 50...100
        case .budget100to200:
            return 100...200
        case .over200:
            return 200...1000
        }
    }
}

struct ProfileLocation: Codable, Equatable {
    let address: String
    let city: String
    let province: String
    let postalCode: String
    let latitude: Double?
    let longitude: Double?

    var displayName: String {
        return "\(city), \(province)"
    }
}

struct SocialLink: Codable, Equatable {
    let platform: SocialPlatform
    let username: String
    let url: String

    enum SocialPlatform: String, Codable, CaseIterable {
        case instagram = "instagram"
        case facebook = "facebook"
        case twitter = "twitter"
        case linkedin = "linkedin"
        case website = "website"

        var displayName: String {
            switch self {
            case .instagram:
                return "Instagram"
            case .facebook:
                return "Facebook"
            case .twitter:
                return "Twitter"
            case .linkedin:
                return "LinkedIn"
            case .website:
                return "Website"
            }
        }

        var iconName: String {
            switch self {
            case .instagram:
                return "camera.circle"
            case .facebook:
                return "person.2.circle"
            case .twitter:
                return "bubble.left.circle"
            case .linkedin:
                return "briefcase.circle"
            case .website:
                return "globe.circle"
            }
        }
    }
}

struct ProfilePreferences: Codable, Equatable {
    let classReminders: Bool
    let newClassAlerts: Bool
    let weeklyDigest: Bool
    let marketingEmails: Bool
    let locationEnabled: Bool
    let profileVisibility: ProfileVisibility

    init(
        classReminders: Bool = true,
        newClassAlerts: Bool = true,
        weeklyDigest: Bool = false,
        marketingEmails: Bool = false,
        locationEnabled: Bool = false,
        profileVisibility: ProfileVisibility = .public
    ) {
        self.classReminders = classReminders
        self.newClassAlerts = newClassAlerts
        self.weeklyDigest = weeklyDigest
        self.marketingEmails = marketingEmails
        self.locationEnabled = locationEnabled
        self.profileVisibility = profileVisibility
    }

    enum ProfileVisibility: String, Codable, CaseIterable {
        case publicProfile = "public"
        case friendsOnly = "friends"
        case privateProfile = "private"

        var displayName: String {
            switch self {
            case .publicProfile:
                return "Public"
            case .friendsOnly:
                return "Friends Only"
            case .privateProfile:
                return "Private"
            }
        }
    }
}

// MARK: - Profile Field Management

enum ProfileField: String, CaseIterable {
    case fullName = "full_name"
    case bio = "bio"
    case experienceLevel = "experience_level"
    case interests = "interests"
    case preferredTimes = "preferred_times"
    case budgetRange = "budget_range"
    case location = "location"
    case socialLinks = "social_links"
    case preferences = "preferences"
    case profileImage = "profile_image"

    var displayName: String {
        switch self {
        case .fullName:
            return "Full Name"
        case .bio:
            return "Bio"
        case .experienceLevel:
            return "Experience Level"
        case .interests:
            return "Interests"
        case .preferredTimes:
            return "Preferred Times"
        case .budgetRange:
            return "Budget Range"
        case .location:
            return "Location"
        case .socialLinks:
            return "Social Links"
        case .preferences:
            return "Preferences"
        case .profileImage:
            return "Profile Image"
        }
    }

    var isRequired: Bool {
        switch self {
        case .fullName, .interests:
            return true
        default:
            return false
        }
    }
}

// MARK: - Profile Requirements and Validation

struct ProfileRequirement {
    let field: ProfileField
    let description: String
    let isRequired: Bool
    let validationRule: (UserProfile) -> Bool

    init(field: ProfileField, description: String, isRequired: Bool = false, validationRule: @escaping (UserProfile) -> Bool) {
        self.field = field
        self.description = description
        self.isRequired = isRequired
        self.validationRule = validationRule
    }
}

enum ProfileValidationResult {
    case valid
    case incomplete(missingFields: [ProfileField])
    case invalid(errors: [String])

    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .incomplete, .invalid:
            return false
        }
    }

    var message: String {
        switch self {
        case .valid:
            return "Profile is complete and valid"
        case .incomplete(let fields):
            return "Missing required fields: \(fields.map { $0.displayName }.joined(separator: ", "))"
        case .invalid(let errors):
            return "Profile has errors: \(errors.joined(separator: ", "))"
        }
    }
}

// MARK: - Profile Data Service Protocol

protocol ProfileDataServiceProtocol {
    /// Save user profile to storage
    func saveProfile(_ profile: UserProfile) async throws

    /// Load user profile from storage
    func loadProfile(for userId: String) async throws -> UserProfile?

    /// Update specific profile field
    func updateProfileField(_ field: ProfileField, value: Any, for userId: String) async throws

    /// Upload profile image
    func uploadProfileImage(_ imageData: Data, for userId: String) async throws -> String

    /// Delete user profile
    func deleteProfile(for userId: String) async throws

    /// Check if profile exists
    func profileExists(for userId: String) async throws -> Bool
}