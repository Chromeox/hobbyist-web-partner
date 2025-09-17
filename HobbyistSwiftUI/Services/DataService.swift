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
        
        var query = supabase
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
        let classes: [HobbyClass] = try response.value
        return classes
    }
    
    func fetchClass(id: String) async throws -> HobbyClass {
        let response = try await supabase
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
        
        let hobbyClass: HobbyClass = try response.value
        return hobbyClass
    }
    
    func searchClasses(query: String) async throws -> [HobbyClass] {
        let response = try await supabase
            .from("classes")
            .select("""
                *,
                instructors!inner(name),
                venues!inner(name, address)
            """)
            .textSearch("title", query: query)
            .execute()
        
        let classes: [HobbyClass] = try response.value
        return classes
    }
    
    func fetchFeaturedClasses() async throws -> [HobbyClass] {
        
        let response = try await supabase
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
        
        let classes: [HobbyClass] = try response.value
        return classes
    }
    
    func fetchRecommendedClasses() async throws -> [HobbyClass] {
        
        // For now, fetch popular classes
        // In the future, this would use a recommendation algorithm
        let response = try await supabase
            .from("classes")
            .select("""
                *,
                instructors!inner(name),
                venues!inner(name, address)
            """)
            .order("booking_count", ascending: false)
            .limit(10)
            .execute()
        
        let classes: [HobbyClass] = try response.value
        return classes
    }
    
    // MARK: - Bookings
    
    func fetchUserBookings(userId: String) async throws -> [Booking] {
        
        let response = try await supabase
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
        
        let bookings = try response.value as! [Booking]
        return bookings
    }
    
    func createBooking(_ booking: BookingRequest) async throws -> Booking {
        
        // Start transaction
        let response = try await supabase
            .from("bookings")
            .insert(booking)
            .select()
            .single()
            .execute()
        
        let newBooking = try response.value as!Booking        
        // If using credits, deduct them
        if booking.useCredits {
            _ = try await supabase
                .rpc("deduct_user_credits", params: [
                    "p_user_id": booking.userId,
                    "p_amount": newBooking.creditUsed ?? 0
                ])
                .execute()
        }
        
        return newBooking
    }
    
    func cancelBooking(id: String) async throws {
        
        _ = try await supabase
            .from("bookings")
            .update(["status": "cancelled"])
            .eq("id", value: id)
            .execute()
    }
    
    func fetchBookingDetails(id: String) async throws -> Booking {
        
        let response = try await supabase
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
        
        let booking = try response.value as! Booking
        return booking
    }
    
    // MARK: - Instructors
    
    func fetchInstructors() async throws -> [Instructor] {
        
        let response = try await supabase
            .from("instructors")
            .select("*")
            .order("rating", ascending: false)
            .execute()
        
        let instructors = try response.value as! [Instructor]
        return instructors
    }
    
    func fetchInstructor(id: String) async throws -> Instructor {
        
        let response = try await supabase
            .from("instructors")
            .select("""
                *,
                classes(title, category, rating)
            """)
            .eq("id", value: id)
            .single()
            .execute()
        
        let instructor = try response.value as! Instructor
        return instructor
    }
    
    // MARK: - Reviews
    
    func fetchReviews(classId: String) async throws -> [Review] {
        
        let response = try await supabase
            .from("reviews")
            .select("""
                *,
                users!inner(full_name, avatar_url)
            """)
            .eq("class_id", value: classId)
            .order("created_at", ascending: false)
            .execute()
        
        let reviews = try response.value as! [Review]
        return reviews
    }
    
    func createReview(_ review: ReviewRequest) async throws -> Review {
        
        let response = try await supabase
            .from("reviews")
            .insert(review)
            .select()
            .single()
            .execute()
        
        let newReview = try response.value as! Review

        // Update class rating
        _ = try await supabase
            .rpc("update_class_rating", params: ["p_class_id": review.classId])
            .execute()
        
        return newReview
    }
    
    // MARK: - User Profile
    
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        
        let response = try await supabase
            .from("user_profiles")
            .select("*")
            .eq("id", value: userId)
            .single()
            .execute()
        
        let profile = try response.value as! UserProfile
        return profile
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        
        let response = try await supabase
            .from("user_profiles")
            .update(profile)
            .eq("id", value: profile.id)
            .select()
            .single()
            .execute()
        
        let updatedProfile = try response.value as! UserProfile
        return updatedProfile
    }
    
    // MARK: - Credits
    
    func fetchUserCredits(userId: String) async throws -> UserCredits {
        
        let response = try await supabase
            .from("user_credits")
            .select("""
                *,
                credit_transactions(*)
            """)
            .eq("user_id", value: userId)
            .single()
            .execute()
        
        let credits = try response.value as! UserCredits
        return credits
    }
    
    func purchaseCreditPack(packId: String) async throws -> CreditTransaction {
        
        let response = try await supabase
            .rpc("purchase_credit_pack", params: ["p_pack_id": packId])
            .execute()
        
        let transaction = try response.value as! CreditTransaction
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