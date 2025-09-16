import Foundation

class FollowingService {
    static let shared = FollowingService()
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    // MARK: - Following Management
    
    func follow(userId: UUID, targetId: UUID, targetType: FollowingType) async throws {
        // Mock implementation for build compatibility
        print("Following \(targetType): \(targetId)")
    }
    
    func unfollow(userId: UUID, targetId: UUID, targetType: FollowingType) async throws {
        // Mock implementation
        print("Unfollowing \(targetType): \(targetId)")
    }
    
    // MARK: - Fetch Following/Followers
    
    func getFollowing(for userId: UUID) async throws -> [FollowingProfile] {
        return FollowingProfile.mockData()
    }
    
    func getFollowers(for userId: UUID) async throws -> [FollowingProfile] {
        return FollowingProfile.mockData()
    }
    
    // MARK: - Suggestions
    
    func getSuggestions(for userId: UUID) async throws -> [FollowingProfile] {
        return FollowingProfile.mockData()
    }
    
    // MARK: - Check Following Status
    
    func isFollowing(userId: UUID, targetId: UUID, targetType: FollowingType) async throws -> Bool {
        return false // Mock implementation
    }
    
    // MARK: - Statistics
    
    func getFollowingCount(for userId: UUID) async throws -> (followers: Int, following: Int) {
        return (followers: 42, following: 38) // Mock data
    }
}

// MARK: - Mock Data Extension
extension FollowingProfile {
    static func mockData() -> [FollowingProfile] {
        return [
            FollowingProfile(
                id: UUID(),
                name: "Sarah Chen",
                username: "sarahchen",
                imageUrl: nil,
                bio: "Yoga instructor | Mindfulness advocate",
                followersCount: 342,
                followingCount: 128,
                isFollowing: false,
                type: .instructor
            ),
            FollowingProfile(
                id: UUID(),
                name: "Downtown Fitness Studio",
                username: "downtownfit",
                imageUrl: nil,
                bio: "Your neighborhood fitness destination",
                followersCount: 1250,
                followingCount: 85,
                isFollowing: true,
                type: .venue
            ),
            FollowingProfile(
                id: UUID(),
                name: "Mike Johnson",
                username: "mikej",
                imageUrl: nil,
                bio: "Fitness enthusiast | Runner",
                followersCount: 156,
                followingCount: 203,
                isFollowing: false,
                type: .user
            )
        ]
    }
}