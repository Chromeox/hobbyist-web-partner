import Foundation
import Supabase

class FollowingService {
    static let shared = FollowingService()
    private let supabaseClient = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Following Management
    
    func follow(userId: UUID, targetId: UUID, targetType: FollowingType) async throws {
        let following = Following(
            id: UUID(),
            followerId: userId,
            followingId: targetId,
            followingType: targetType,
            createdAt: Date()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(following)
        
        _ = try await supabaseClient
            .from("following")
            .insert(data)
            .execute()
        
        // Create activity feed item
        try await createFollowActivity(userId: userId, targetId: targetId, targetType: targetType)
    }
    
    func unfollow(userId: UUID, targetId: UUID, targetType: FollowingType) async throws {
        _ = try await supabaseClient
            .from("following")
            .delete()
            .eq("follower_id", value: userId.uuidString)
            .eq("following_id", value: targetId.uuidString)
            .eq("following_type", value: targetType.rawValue)
            .execute()
    }
    
    // MARK: - Fetch Following/Followers
    
    func getFollowing(for userId: UUID) async throws -> [FollowingProfile] {
        let response = try await supabaseClient
            .from("following")
            .select("""
                *,
                profiles!following_id(
                    id, name, username, image_url, bio
                )
            """)
            .eq("follower_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        
        // Parse and transform the response
        return try parseFollowingProfiles(from: response.data)
    }
    
    func getFollowers(for userId: UUID) async throws -> [FollowingProfile] {
        let response = try await supabaseClient
            .from("following")
            .select("""
                *,
                profiles!follower_id(
                    id, name, username, image_url, bio
                )
            """)
            .eq("following_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        
        // Parse and transform the response
        return try parseFollowerProfiles(from: response.data)
    }
    
    // MARK: - Suggestions
    
    func getSuggestions(for userId: UUID) async throws -> [FollowingProfile] {
        // Get user's interests based on their activity
        let userInterests = try await getUserInterests(userId: userId)
        
        // Fetch suggested profiles based on interests
        let response = try await supabaseClient
            .rpc("get_follow_suggestions", params: [
                "user_id": userId.uuidString,
                "interests": userInterests
            ])
            .execute()
        
        return try parseFollowingProfiles(from: response.data)
    }
    
    private func getUserInterests(userId: UUID) async throws -> [String] {
        // Analyze user's bookings and follows to determine interests
        // For now, return mock interests
        return ["yoga", "fitness", "meditation"]
    }
    
    // MARK: - Activity Feed
    
    private func createFollowActivity(userId: UUID, targetId: UUID, targetType: FollowingType) async throws {
        let targetName = try await getTargetName(targetId: targetId, targetType: targetType)
        
        let activity = ActivityFeedItem(
            id: UUID(),
            actorId: userId,
            actorName: try await getUserName(userId: userId),
            actorImageUrl: nil,
            actionType: .followed,
            targetType: targetType.rawValue,
            targetId: targetId,
            targetName: targetName,
            metadata: nil,
            createdAt: Date()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(activity)
        
        _ = try await supabaseClient
            .from("activity_feed")
            .insert(data)
            .execute()
    }
    
    private func getUserName(userId: UUID) async throws -> String {
        let response = try await supabaseClient
            .from("profiles")
            .select("first_name, last_name")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
        
        if let json = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any],
           let firstName = json["first_name"] as? String,
           let lastName = json["last_name"] as? String {
            return "\(firstName) \(lastName)"
        }
        
        return "Unknown User"
    }
    
    private func getTargetName(targetId: UUID, targetType: FollowingType) async throws -> String {
        switch targetType {
        case .user:
            return try await getUserName(userId: targetId)
        case .instructor:
            let instructor = try await InstructorService.shared.fetchInstructor(by: targetId)
            return instructor.fullName
        case .venue:
            let venue = try await VenueService.shared.fetchVenue(by: targetId)
            return venue.name
        }
    }
    
    // MARK: - Parsing Helpers
    
    private func parseFollowingProfiles(from data: Data) throws -> [FollowingProfile] {
        // This would parse the complex joined data from Supabase
        // For now, return mock data
        return FollowingProfile.mockData()
    }
    
    private func parseFollowerProfiles(from data: Data) throws -> [FollowingProfile] {
        // This would parse the complex joined data from Supabase
        // For now, return mock data
        return FollowingProfile.mockData()
    }
    
    // MARK: - Check Following Status
    
    func isFollowing(userId: UUID, targetId: UUID, targetType: FollowingType) async throws -> Bool {
        let response = try await supabaseClient
            .from("following")
            .select("id")
            .eq("follower_id", value: userId.uuidString)
            .eq("following_id", value: targetId.uuidString)
            .eq("following_type", value: targetType.rawValue)
            .single()
            .execute()
        
        return response.data.count > 0
    }
    
    // MARK: - Statistics
    
    func getFollowingCount(for userId: UUID) async throws -> (followers: Int, following: Int) {
        async let followersResponse = supabaseClient
            .from("following")
            .select("id", head: true, count: .exact)
            .eq("following_id", value: userId.uuidString)
            .execute()
        
        async let followingResponse = supabaseClient
            .from("following")
            .select("id", head: true, count: .exact)
            .eq("follower_id", value: userId.uuidString)
            .execute()
        
        let (followers, following) = try await (followersResponse, followingResponse)
        
        // Extract count from headers
        let followersCount = extractCount(from: followers) ?? 0
        let followingCount = extractCount(from: following) ?? 0
        
        return (followers: followersCount, following: followingCount)
    }
    
    private func extractCount(from response: PostgrestResponse) -> Int? {
        // Parse the count from response headers
        // This would read the content-range header
        return nil // Placeholder
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