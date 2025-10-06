import Foundation

struct Following: Identifiable, Codable, Hashable {
    let id: UUID
    let followerId: UUID
    let followingId: UUID
    let followingType: FollowingType
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
        case followingType = "following_type"
        case createdAt = "created_at"
    }
}

enum FollowingType: String, Codable {
    case user = "user"
    case instructor = "instructor"
    case venue = "venue"
}

// Profile data for following lists
struct FollowingProfile: Identifiable, Codable {
    let id: UUID
    let name: String
    let username: String?
    let imageUrl: String?
    let bio: String?
    let followersCount: Int
    let followingCount: Int
    let isFollowing: Bool
    let type: FollowingType
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case username
        case imageUrl = "image_url"
        case bio
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case isFollowing = "is_following"
        case type
    }
}

// Activity feed item for following
struct ActivityFeedItem: Identifiable, Codable {
    let id: UUID
    let actorId: UUID
    let actorName: String
    let actorImageUrl: String?
    let actionType: ActivityActionType
    let targetType: String?
    let targetId: UUID?
    let targetName: String?
    let metadata: [String: String]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case actorId = "actor_id"
        case actorName = "actor_name"
        case actorImageUrl = "actor_image_url"
        case actionType = "action_type"
        case targetType = "target_type"
        case targetId = "target_id"
        case targetName = "target_name"
        case metadata
        case createdAt = "created_at"
    }
}

enum ActivityActionType: String, Codable {
    case booked = "booked"
    case reviewed = "reviewed"
    case followed = "followed"
    case joined = "joined"
    case created = "created"
    case achieved = "achieved"
}