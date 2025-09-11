import Foundation
import Supabase
import Combine

class DataService: DataServiceProtocol {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // MARK: - Classes
    
    func fetchClasses(filters: ClassFilters?) async throws -> [HobbyClass] {
        
        var query = supabase.database
            .from("classes")
            .select("""
                *,
                instructors!inner(name),
                venues!inner(name, address)
            """)
        
        // Apply filters if provided
        if let filters = filters {
            if let category = filters.category {
                query = query.eq("category", value: category)
            }
            
            if let minPrice = filters.minPrice {
                query = query.gte("price", value: minPrice)
            }
            
            if let maxPrice = filters.maxPrice {
                query = query.lte("price", value: maxPrice)
            }
            
            if let startDate = filters.startDate {
                query = query.gte("start_date", value: startDate.iso8601String)
            }
            
            // Apply sorting
            switch filters.sortBy {
            case .price:
                query = query.order("price", ascending: true)
            case .rating:
                query = query.order("rating", ascending: false)
            case .date:
                query = query.order("start_date", ascending: true)
            default:
                query = query.order("created_at", ascending: false)
            }
        }
        
        let response = try await query.execute()
        let classes = try response.decoded(to: [HobbyClass].self)
        return classes
    }
    
    func fetchClass(id: String) async throws -> HobbyClass {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        let response = try await supabase.database
            .from("classes")
            .select("""
                *,
                instructors!inner(name),
                venues!inner(name, address),
                reviews(rating, comment, user_name, created_at)
            """)
            .eq("id", value: id)
            .single()
            .execute()
        
        let hobbyClass = try response.decoded(to: HobbyClass.self)
        return hobbyClass
    }
    
    func searchClasses(query: String) async throws -> [HobbyClass] {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        let response = try await supabase.database
            .from("classes")
            .select("""
                *,
                instructors!inner(name),
                venues!inner(name, address)
            """)
            .textSearch("title", query: query)
            .execute()
        
        let classes = try response.decoded(to: [HobbyClass].self)
        return classes
    }
    
    func fetchFeaturedClasses() async throws -> [HobbyClass] {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        let response = try await supabase.database
            .from("classes")
            .select("""
                *,
                instructors!inner(name),
                venues!inner(name, address)
            """)
            .eq("is_featured", value: true)
            .order("rating", ascending: false)
            .limit(10)
            .execute()
        
        let classes = try response.decoded(to: [HobbyClass].self)
        return classes
    }
    
    func fetchRecommendedClasses() async throws -> [HobbyClass] {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        // For now, fetch popular classes
        // In the future, this would use a recommendation algorithm
        let response = try await supabase.database
            .from("classes")
            .select("""
                *,
                instructors!inner(name),
                venues!inner(name, address)
            """)
            .order("booking_count", ascending: false)
            .limit(10)
            .execute()
        
        let classes = try response.decoded(to: [HobbyClass].self)
        return classes
    }
    
    // MARK: - Bookings
    
    func fetchUserBookings(userId: String) async throws -> [Booking] {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        let response = try await supabase.database
            .from("bookings")
            .select("""
                *,
                classes!inner(title, start_date, end_date),
                instructors!inner(name),
                venues!inner(name, address)
            """)
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
        
        let bookings = try response.decoded(to: [Booking].self)
        return bookings
    }
    
    func createBooking(_ booking: BookingRequest) async throws -> Booking {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        // Start transaction
        let response = try await supabase.database
            .from("bookings")
            .insert(booking)
            .select()
            .single()
            .execute()
        
        let newBooking = try response.decoded(to: Booking.self)
        
        // If using credits, deduct them
        if booking.useCredits {
            _ = try await supabase.database
                .rpc("deduct_user_credits", params: [
                    "p_user_id": booking.userId,
                    "p_amount": newBooking.creditUsed ?? 0
                ])
                .execute()
        }
        
        return newBooking
    }
    
    func cancelBooking(id: String) async throws {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        _ = try await supabase.database
            .from("bookings")
            .update(["status": "cancelled"])
            .eq("id", value: id)
            .execute()
    }
    
    func fetchBookingDetails(id: String) async throws -> Booking {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        let response = try await supabase.database
            .from("bookings")
            .select("""
                *,
                classes!inner(title, start_date, end_date, description),
                instructors!inner(name, bio),
                venues!inner(name, address)
            """)
            .eq("id", value: id)
            .single()
            .execute()
        
        let booking = try response.decoded(to: Booking.self)
        return booking
    }
    
    // MARK: - Instructors
    
    func fetchInstructors() async throws -> [Instructor] {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        let response = try await supabase.database
            .from("instructors")
            .select("*")
            .order("rating", ascending: false)
            .execute()
        
        let instructors = try response.decoded(to: [Instructor].self)
        return instructors
    }
    
    func fetchInstructor(id: String) async throws -> Instructor {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        let response = try await supabase.database
            .from("instructors")
            .select("""
                *,
                classes(title, category, rating)
            """)
            .eq("id", value: id)
            .single()
            .execute()
        
        let instructor = try response.decoded(to: Instructor.self)
        return instructor
    }
    
    // MARK: - Reviews
    
    func fetchReviews(classId: String) async throws -> [Review] {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        let response = try await supabase.database
            .from("reviews")
            .select("""
                *,
                users!inner(full_name, avatar_url)
            """)
            .eq("class_id", value: classId)
            .order("created_at", ascending: false)
            .execute()
        
        let reviews = try response.decoded(to: [Review].self)
        return reviews
    }
    
    func createReview(_ review: ReviewRequest) async throws -> Review {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        let response = try await supabase.database
            .from("reviews")
            .insert(review)
            .select()
            .single()
            .execute()
        
        let newReview = try response.decoded(to: Review.self)
        
        // Update class rating
        _ = try await supabase.database
            .rpc("update_class_rating", params: ["p_class_id": review.classId])
            .execute()
        
        return newReview
    }
    
    // MARK: - User Profile
    
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        let response = try await supabase.database
            .from("user_profiles")
            .select("*")
            .eq("id", value: userId)
            .single()
            .execute()
        
        let profile = try response.decoded(to: UserProfile.self)
        return profile
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        let response = try await supabase.database
            .from("user_profiles")
            .update(profile)
            .eq("id", value: profile.id)
            .select()
            .single()
            .execute()
        
        let updatedProfile = try response.decoded(to: UserProfile.self)
        return updatedProfile
    }
    
    // MARK: - Credits
    
    func fetchUserCredits(userId: String) async throws -> UserCredits {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        let response = try await supabase.database
            .from("user_credits")
            .select("""
                *,
                credit_transactions(*)
            """)
            .eq("user_id", value: userId)
            .single()
            .execute()
        
        let credits = try response.decoded(to: UserCredits.self)
        return credits
    }
    
    func purchaseCreditPack(packId: String) async throws -> CreditTransaction {
        guard let supabase = supabase else { throw DataError.notInitialized }
        
        let response = try await supabase.database
            .rpc("purchase_credit_pack", params: ["p_pack_id": packId])
            .execute()
        
        let transaction = try response.decoded(to: CreditTransaction.self)
        return transaction
    }
}

// MARK: - Error Types

enum DataError: LocalizedError {
    case notInitialized
    case networkError
    case decodingError
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Supabase client not initialized"
        case .networkError:
            return "Network connection error"
        case .decodingError:
            return "Failed to decode server response"
        case .unknownError(let message):
            return message
        }
    }
}

// MARK: - Date Extension

extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}