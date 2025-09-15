import Foundation
import CoreLocation
import Supabase

class InstructorService {
    static let shared = InstructorService()
    private let supabaseClient = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Fetch Methods
    
    func fetchAllInstructors() async throws -> [Instructor] {
        let response = try await supabaseClient
            .from("instructors")
            .select()
            .eq("is_active", value: true)
            .order("rating", ascending: false)
            .execute()
        
        let data = response.data
        let instructors = try JSONDecoder().decode([Instructor].self, from: data)
        return instructors
    }
    
    func fetchInstructor(by id: UUID) async throws -> Instructor {
        let response = try await supabaseClient
            .from("instructors")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
        
        let data = response.data
        let instructor = try JSONDecoder().decode(Instructor.self, from: data)
        return instructor
    }
    
    func fetchNearbyInstructors(location: CLLocation, radius: Double) async throws -> [Instructor] {
        // For now, return all instructors
        // In production, would use PostGIS for geographic queries
        let allInstructors = try await fetchAllInstructors()
        
        // Mock filtering by distance (would be done server-side in production)
        return allInstructors.prefix(10).map { $0 }
    }
    
    func searchInstructors(query: String) async throws -> [Instructor] {
        let response = try await supabaseClient
            .from("instructors")
            .select()
            .ilike("first_name", value: "%\(query)%")
            .eq("is_active", value: true)
            .execute()
        
        let data = response.data
        let instructors = try JSONDecoder().decode([Instructor].self, from: data)
        return instructors
    }
    
    // MARK: - Reviews
    
    func fetchInstructorReviews(instructorId: UUID) async throws -> [Review] {
        let response = try await supabaseClient
            .from("reviews")
            .select()
            .eq("target_type", value: "instructor")
            .eq("target_id", value: instructorId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        
        let data = response.data
        let reviews = try JSONDecoder().decode([Review].self, from: data)
        return reviews
    }
    
    func submitReview(for instructorId: UUID, review: Review) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let reviewData = try encoder.encode(review)
        
        _ = try await supabaseClient
            .from("reviews")
            .insert(reviewData)
            .execute()
        
        // Update instructor's rating
        try await updateInstructorRating(instructorId: instructorId)
    }
    
    private func updateInstructorRating(instructorId: UUID) async throws {
        // Fetch all reviews for this instructor
        let reviews = try await fetchInstructorReviews(instructorId: instructorId)
        
        guard !reviews.isEmpty else { return }
        
        // Calculate average rating
        let totalRating = reviews.reduce(0) { $0 + $1.rating }
        let averageRating = Decimal(totalRating) / Decimal(reviews.count)
        
        // Update instructor record
        _ = try await supabaseClient
            .from("instructors")
            .update([
                "rating": averageRating,
                "total_reviews": reviews.count
            ])
            .eq("id", value: instructorId.uuidString)
            .execute()
    }
    
    // MARK: - Schedule
    
    func fetchInstructorSchedule(instructorId: UUID, from startDate: Date, to endDate: Date) async throws -> [ClassItem] {
        let formatter = ISO8601DateFormatter()
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)
        
        let response = try await supabaseClient
            .from("classes")
            .select()
            .eq("instructor_id", value: instructorId.uuidString)
            .gte("start_time", value: startString)
            .lte("start_time", value: endString)
            .order("start_time", ascending: true)
            .execute()
        
        let data = response.data
        let classes = try JSONDecoder().decode([ClassItem].self, from: data)
        return classes
    }
    
    // MARK: - Following
    
    func followInstructor(userId: UUID, instructorId: UUID) async throws {
        let following = Following(
            id: UUID(),
            followerId: userId,
            followingId: instructorId,
            followingType: .instructor,
            createdAt: Date()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(following)
        
        _ = try await supabaseClient
            .from("following")
            .insert(data)
            .execute()
    }
    
    func unfollowInstructor(userId: UUID, instructorId: UUID) async throws {
        _ = try await supabaseClient
            .from("following")
            .delete()
            .eq("follower_id", value: userId.uuidString)
            .eq("following_id", value: instructorId.uuidString)
            .eq("following_type", value: "instructor")
            .execute()
    }
    
    func isFollowingInstructor(userId: UUID, instructorId: UUID) async throws -> Bool {
        let response = try await supabaseClient
            .from("following")
            .select("id")
            .eq("follower_id", value: userId.uuidString)
            .eq("following_id", value: instructorId.uuidString)
            .eq("following_type", value: "instructor")
            .single()
            .execute()
        
        return response.data.count > 0
    }
}