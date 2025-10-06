import Foundation

struct Instructor: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let firstName: String
    let lastName: String
    let email: String
    let phone: String?
    let bio: String?
    let specialties: [String]
    let certificationInfo: CertificationInfo?
    let rating: Decimal
    let totalReviews: Int
    let profileImageUrl: String?
    let yearsOfExperience: Int?
    let socialLinks: SocialLinks?
    let availability: [AvailabilitySlot]?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phone
        case bio
        case specialties
        case certificationInfo = "certification_info"
        case rating
        case totalReviews = "total_reviews"
        case profileImageUrl = "profile_image_url"
        case yearsOfExperience = "years_of_experience"
        case socialLinks = "social_links"
        case availability
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var formattedRating: String {
        String(format: "%.1f", NSDecimalNumber(decimal: rating).doubleValue)
    }
    
    var isHighlyRated: Bool {
        NSDecimalNumber(decimal: rating).doubleValue >= 4.5
    }

    static let sample = Instructor(
        id: UUID(),
        userId: UUID(),
        firstName: "Sample",
        lastName: "Instructor",
        email: "sample@example.com",
        phone: nil,
        bio: "Sample instructor bio",
        specialties: ["Sample Specialty"],
        certificationInfo: nil,
        rating: Decimal(4.5),
        totalReviews: 10,
        profileImageUrl: nil,
        yearsOfExperience: 5,
        socialLinks: nil,
        availability: nil,
        isActive: true,
        createdAt: Date(),
        updatedAt: nil
    )
}

struct CertificationInfo: Codable, Hashable {
    let certifications: [Certification]
    let verifiedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case certifications
        case verifiedAt = "verified_at"
    }
}

struct Certification: Codable, Hashable {
    let name: String
    let issuingOrganization: String
    let issueDate: Date
    let expiryDate: Date?
    let credentialId: String?
    let verificationUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case issuingOrganization = "issuing_organization"
        case issueDate = "issue_date"
        case expiryDate = "expiry_date"
        case credentialId = "credential_id"
        case verificationUrl = "verification_url"
    }
    
    var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return expiryDate < Date()
    }
}

struct SocialLinks: Codable, Hashable {
    let website: String?
    let instagram: String?
    let facebook: String?
    let twitter: String?
    let linkedin: String?
    let youtube: String?
}

struct AvailabilitySlot: Codable, Hashable {
    let dayOfWeek: Int
    let startTime: String
    let endTime: String
    let isRecurring: Bool
    
    enum CodingKeys: String, CodingKey {
        case dayOfWeek = "day_of_week"
        case startTime = "start_time"
        case endTime = "end_time"
        case isRecurring = "is_recurring"
    }
}