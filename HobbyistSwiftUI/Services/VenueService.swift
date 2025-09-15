import Foundation
import CoreLocation
import Supabase

class VenueService {
    static let shared = VenueService()
    private let supabaseClient = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Fetch Methods
    
    func fetchAllVenues() async throws -> [Venue] {
        let response = try await supabaseClient
            .from("venues")
            .select()
            .eq("is_active", value: true)
            .order("name", ascending: true)
            .execute()
        
        let data = response.data
        let venues = try JSONDecoder().decode([Venue].self, from: data)
        return venues
    }
    
    func fetchVenue(by id: UUID) async throws -> Venue {
        let response = try await supabaseClient
            .from("venues")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
        
        let data = response.data
        let venue = try JSONDecoder().decode(Venue.self, from: data)
        return venue
    }
    
    func fetchNearbyVenues(location: CLLocation, radius: Double) async throws -> [Venue] {
        // Fetch all venues first
        let allVenues = try await fetchAllVenues()
        
        // Filter by distance
        let nearbyVenues = allVenues.filter { venue in
            let venueLocation = CLLocation(latitude: venue.latitude, longitude: venue.longitude)
            let distance = location.distance(from: venueLocation) / 1609.344 // Convert to miles
            return distance <= radius
        }
        
        // Sort by distance
        return nearbyVenues.sorted { venue1, venue2 in
            let location1 = CLLocation(latitude: venue1.latitude, longitude: venue1.longitude)
            let location2 = CLLocation(latitude: venue2.latitude, longitude: venue2.longitude)
            return location.distance(from: location1) < location.distance(from: location2)
        }
    }
    
    func searchVenues(query: String) async throws -> [Venue] {
        let response = try await supabaseClient
            .from("venues")
            .select()
            .or("name.ilike.%\(query)%,city.ilike.%\(query)%")
            .eq("is_active", value: true)
            .execute()
        
        let data = response.data
        let venues = try JSONDecoder().decode([Venue].self, from: data)
        return venues
    }
    
    // MARK: - Classes at Venue
    
    func fetchClassesAtVenue(venueId: UUID, from startDate: Date = Date()) async throws -> [ClassItem] {
        let formatter = ISO8601DateFormatter()
        let startString = formatter.string(from: startDate)
        
        let response = try await supabaseClient
            .from("classes")
            .select()
            .eq("venue_id", value: venueId.uuidString)
            .gte("start_time", value: startString)
            .order("start_time", ascending: true)
            .execute()
        
        let data = response.data
        let classes = try JSONDecoder().decode([ClassItem].self, from: data)
        return classes
    }
    
    // MARK: - Reviews
    
    func fetchVenueReviews(venueId: UUID) async throws -> [Review] {
        let response = try await supabaseClient
            .from("reviews")
            .select()
            .eq("target_type", value: "venue")
            .eq("target_id", value: venueId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        
        let data = response.data
        let reviews = try JSONDecoder().decode([Review].self, from: data)
        return reviews
    }
    
    func submitReview(for venueId: UUID, review: Review) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let reviewData = try encoder.encode(review)
        
        _ = try await supabaseClient
            .from("reviews")
            .insert(reviewData)
            .execute()
    }
    
    // MARK: - Following
    
    func followVenue(userId: UUID, venueId: UUID) async throws {
        let following = Following(
            id: UUID(),
            followerId: userId,
            followingId: venueId,
            followingType: .venue,
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
    
    func unfollowVenue(userId: UUID, venueId: UUID) async throws {
        _ = try await supabaseClient
            .from("following")
            .delete()
            .eq("follower_id", value: userId.uuidString)
            .eq("following_id", value: venueId.uuidString)
            .eq("following_type", value: "venue")
            .execute()
    }
    
    func isFollowingVenue(userId: UUID, venueId: UUID) async throws -> Bool {
        let response = try await supabaseClient
            .from("following")
            .select("id")
            .eq("follower_id", value: userId.uuidString)
            .eq("following_id", value: venueId.uuidString)
            .eq("following_type", value: "venue")
            .single()
            .execute()
        
        return response.data.count > 0
    }
    
    // MARK: - Analytics
    
    func fetchVenueAnalytics(venueId: UUID) async throws -> VenueAnalytics {
        // This would fetch aggregated data from a view or function
        let response = try await supabaseClient
            .rpc("get_venue_analytics", params: ["venue_id": venueId.uuidString])
            .execute()
        
        let data = response.data
        let analytics = try JSONDecoder().decode(VenueAnalytics.self, from: data)
        return analytics
    }
}

// MARK: - Analytics Model
struct VenueAnalytics: Codable {
    let totalClasses: Int
    let totalBookings: Int
    let averageOccupancy: Double
    let popularTimes: [PopularTime]
    let topInstructors: [InstructorSummary]
    
    enum CodingKeys: String, CodingKey {
        case totalClasses = "total_classes"
        case totalBookings = "total_bookings"
        case averageOccupancy = "average_occupancy"
        case popularTimes = "popular_times"
        case topInstructors = "top_instructors"
    }
}

struct PopularTime: Codable {
    let dayOfWeek: Int
    let hour: Int
    let bookingCount: Int
    
    enum CodingKeys: String, CodingKey {
        case dayOfWeek = "day_of_week"
        case hour
        case bookingCount = "booking_count"
    }
}

struct InstructorSummary: Codable {
    let id: UUID
    let name: String
    let classCount: Int
    let averageRating: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case classCount = "class_count"
        case averageRating = "average_rating"
    }
}