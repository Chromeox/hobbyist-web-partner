import Foundation

struct Review: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let targetType: ReviewTargetType
    let targetId: UUID
    let rating: Int
    let title: String?
    let content: String
    let isVerifiedBooking: Bool
    let helpfulCount: Int
    let images: [String]?
    let instructorResponse: String?
    let instructorRespondedAt: Date?
    let createdAt: Date
    let updatedAt: Date?

    // User details (populated from join)
    let userName: String?
    let userImageUrl: String?

    // Custom initializer for ClassDetailViewModel compatibility
    let userInitials: String?
    let date: Date
    let comment: String

    // Custom initializer for sample data
    init(id: String, userName: String, userInitials: String, rating: Int, comment: String, date: Date) {
        self.id = UUID(uuidString: id) ?? UUID()
        self.userId = UUID()
        self.targetType = .class
        self.targetId = UUID()
        self.rating = rating
        self.title = nil
        self.content = comment
        self.isVerifiedBooking = false
        self.helpfulCount = 0
        self.images = nil
        self.instructorResponse = nil
        self.instructorRespondedAt = nil
        self.createdAt = date
        self.updatedAt = nil
        self.userName = userName
        self.userImageUrl = nil
        self.userInitials = userInitials
        self.date = date
        self.comment = comment
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case targetType = "target_type"
        case targetId = "target_id"
        case rating
        case title
        case content
        case isVerifiedBooking = "is_verified_booking"
        case helpfulCount = "helpful_count"
        case images
        case instructorResponse = "instructor_response"
        case instructorRespondedAt = "instructor_responded_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userName = "user_name"
        case userImageUrl = "user_image_url"
        case userInitials = "user_initials"
        case date
        case comment
    }
}

enum ReviewTargetType: String, Codable {
    case instructor = "instructor"
    case venue = "venue"
    case `class` = "class"
}

// Review Statistics for aggregated data
struct ReviewStatistics: Codable {
    let averageRating: Double
    let totalReviews: Int
    let ratingDistribution: RatingDistribution
    let verifiedPercentage: Double
    
    enum CodingKeys: String, CodingKey {
        case averageRating = "average_rating"
        case totalReviews = "total_reviews"
        case ratingDistribution = "rating_distribution"
        case verifiedPercentage = "verified_percentage"
    }
}

struct RatingDistribution: Codable {
    let oneStar: Int
    let twoStar: Int
    let threeStar: Int
    let fourStar: Int
    let fiveStar: Int
    
    enum CodingKeys: String, CodingKey {
        case oneStar = "one_star"
        case twoStar = "two_star"
        case threeStar = "three_star"
        case fourStar = "four_star"
        case fiveStar = "five_star"
    }
}