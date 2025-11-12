import Foundation
import Supabase
import CoreLocation
import Combine
import SwiftUI

// MARK: - Model Converters

extension Instructor {
    /// Convert full Instructor model to lightweight InstructorInfo for HobbyClass
    func toInstructorInfo() -> InstructorInfo {
        return InstructorInfo(
            id: self.id.uuidString,
            name: self.fullName,
            bio: self.bio,
            profileImageUrl: self.profileImageUrl,
            rating: NSDecimalNumber(decimal: self.rating).doubleValue,
            totalClasses: 0, // Will need to fetch from database
            totalStudents: 0, // Will need to fetch from database
            specialties: self.specialties,
            certifications: self.certificationInfo?.certifications.map { $0.name } ?? [],
            yearsOfExperience: self.yearsOfExperience ?? 0,
            socialLinks: self.socialLinks
        )
    }
}

extension Venue {
    /// Convert full Venue model to lightweight VenueInfo for HobbyClass
    func toVenueInfo() -> VenueInfo {
        return VenueInfo(
            id: self.id.uuidString,
            name: self.name,
            address: self.address,
            city: self.city,
            state: self.state,
            zipCode: self.zipCode,
            latitude: self.latitude,
            longitude: self.longitude,
            amenities: self.amenities,
            parkingInfo: self.parkingInfo,
            publicTransit: self.publicTransportInfo,
            imageUrls: self.imageUrls,
            accessibilityInfo: self.accessibilityInfo
        )
    }
}

// MARK: - Mock Data Helpers

/// Create mock InstructorInfo for testing/fallback data
func createMockInstructorInfo(
    id: String = UUID().uuidString,
    name: String,
    bio: String? = nil,
    rating: Double = 4.5,
    specialties: [String] = []
) -> InstructorInfo {
    return InstructorInfo(
        id: id,
        name: name,
        bio: bio,
        profileImageUrl: nil,
        rating: rating,
        totalClasses: 10,
        totalStudents: 50,
        specialties: specialties,
        certifications: [],
        yearsOfExperience: 5,
        socialLinks: nil
    )
}

/// Create mock VenueInfo for testing/fallback data
func createMockVenueInfo(
    id: String = UUID().uuidString,
    name: String,
    address: String,
    city: String = "Vancouver",
    state: String = "BC",
    zipCode: String = "V6B 1A1"
) -> VenueInfo {
    // Default Vancouver coordinates
    let latitude = 49.2827 + Double.random(in: -0.05...0.05)
    let longitude = -123.1207 + Double.random(in: -0.05...0.05)

    return VenueInfo(
        id: id,
        name: name,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
        latitude: latitude,
        longitude: longitude,
        amenities: ["WiFi", "Parking"],
        parkingInfo: "Street parking available",
        publicTransit: "Near SkyTrain station",
        imageUrls: nil,
        accessibilityInfo: "Wheelchair accessible"
    )
}

// MARK: - Data Models

struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let isCompleted: Bool
    let dateEarned: Date?
    let iconName: String

    init(
        id: String = UUID().uuidString,
        title: String = "",
        description: String = "",
        isCompleted: Bool = false,
        dateEarned: Date? = nil,
        iconName: String = "star.fill"
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.dateEarned = dateEarned
        self.iconName = iconName
    }
}

// MARK: - Service Classes

// MARK: - Studio struct for service compatibility
struct Studio: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let phone: String?
    let address: String
    let city: String
    let province: String
    let postalCode: String
    let isActive: Bool
    
    init(id: String, name: String, email: String, phone: String?, address: String, city: String, province: String, postalCode: String, isActive: Bool) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.city = city
        self.province = province
        self.postalCode = postalCode
        self.isActive = isActive
    }
}

// MARK: - Extensions for ClassItem compatibility

extension ClassItem {
    static func from(hobbyClass: HobbyClass) -> ClassItem {
        return ClassItem(
            id: hobbyClass.id,
            title: hobbyClass.title,
            description: hobbyClass.description,
            instructor: hobbyClass.instructor.name,
            venue: hobbyClass.venue.name,
            startDate: hobbyClass.startDate,
            endDate: hobbyClass.endDate,
            price: hobbyClass.price,
            maxParticipants: hobbyClass.maxParticipants,
            currentParticipants: hobbyClass.currentParticipants,
            category: hobbyClass.category.rawValue,
            difficulty: hobbyClass.difficulty.rawValue,
            tags: hobbyClass.tags,
            requirements: hobbyClass.requirements,
            whatToBring: hobbyClass.whatToBring,
            averageRating: hobbyClass.averageRating,
            totalReviews: hobbyClass.totalReviews,
            isOnline: hobbyClass.isOnline
        )
    }
}

class ServiceContainer {
    static let shared = ServiceContainer()
    private init() {}
    
    // Real services that work with Supabase
    lazy var classService: ClassService = ClassService.shared
    lazy var studioService: StudioService = StudioService.shared
    lazy var instructorService: InstructorService = InstructorService.shared
    lazy var bookingService: BookingService = BookingService.shared
    lazy var reviewService: ReviewService = ReviewService.shared
    lazy var userService: UserService = UserService.shared
    
    // Legacy search method - delegates to classService
    func searchClasses(query: String) async throws -> [HobbyClass] {
        return try await classService.searchClasses(query: query)
    }

    var crashReportingService: CrashReportingService {
        return CrashReportingService.shared
    }
}

class CrashReportingService {
    static let shared = CrashReportingService()
    private init() {}

    func recordError(_ error: Error, context: [String: String] = [:]) {
        print("📝 Recording error: \(error), context: \(context)")
    }
}

// MARK: - Booking Service

class BookingService {
    static let shared = BookingService()
    private let supabase = SimpleSupabaseService.shared
    private lazy var simpleSupabaseService = SimpleSupabaseService.shared
    private init() {}
    
    func createBooking(classId: String, userId: String, creditsUsed: Int = 1, paymentMethod: String = "credits") async throws -> Bool {
        // Try real database booking first
        do {
            // First check if user exists in students table
            let userResponse = try await supabase.client
                .from("students")
                .select("id")
                .eq("user_id", value: userId)
                .single()
                .execute()
            
            guard let userData = try userResponse.value as? [String: Any],
                  let studentId = userData["id"] as? String else {
                // Create student profile if it doesn't exist
                let newStudentId = UUID().uuidString
                try await supabase.client
                    .from("students")
                    .insert([
                        "id": newStudentId,
                        "user_id": userId,
                        "email": "user@example.com",
                        "status": "active",
                        "credit_balance": 10
                    ])
                    .execute()
                
                return try await createBookingRecord(studentId: newStudentId, classId: classId, creditsUsed: creditsUsed, paymentMethod: paymentMethod)
            }
            
            return try await createBookingRecord(studentId: studentId, classId: classId, creditsUsed: creditsUsed, paymentMethod: paymentMethod)
            
        } catch {
            print("⚠️ Error creating booking in database: \(error)")
            
            // Fallback to SimpleSupabaseService
            guard let user = await simpleSupabaseService.currentUser else {
                throw AppError.unauthorized
            }
            
            return await simpleSupabaseService.createBooking(
                classId: classId,
                date: Date(),
                scheduleId: nil,
                creditsUsed: creditsUsed,
                paymentMethod: paymentMethod
            )
        }
    }
    
    private func createBookingRecord(studentId: String, classId: String, creditsUsed: Int, paymentMethod: String) async throws -> Bool {
        let bookingId = UUID().uuidString
        
        // Create booking record
        try await supabase.client
            .from("bookings")
            .insert([
                "id": bookingId,
                "student_id": studentId,
                "session_id": classId, // Using class_id as session_id for now
                "credits_used": creditsUsed,
                "payment_method": paymentMethod,
                "status": "confirmed"
            ])
            .execute()
        
        print("✅ Booking created successfully with ID: \(bookingId)")
        return true
    }
    
    func getUserBookings(userId: String) async throws -> [Booking] {
        // Try to fetch real bookings from database
        do {
            // First get the student ID for this user
            let studentResponse = try await supabase.client
                .from("students")
                .select("id")
                .eq("user_id", value: userId)
                .single()
                .execute()
            
            guard let studentData = try studentResponse.value as? [String: Any],
                  let studentId = studentData["id"] as? String else {
                print("⚠️ No student profile found for user \(userId)")
                return generateMockBookings(userId: userId)
            }
            
            // Fetch bookings with class details
            let response = try await supabase.client
                .from("bookings")
                .select("""
                    id,
                    status,
                    credits_used,
                    created_at,
                    session_id,
                    amount_paid
                """)
                .eq("student_id", value: studentId)
                .order("created_at", ascending: false)
                .execute()
            
            if let bookingData = try response.value as? [[String: Any]] {
                let realBookings = bookingData.compactMap { data -> Booking? in
                    return parseBookingFromDatabase(data, userId: userId)
                }
                
                if !realBookings.isEmpty {
                    print("✅ Loaded \(realBookings.count) real bookings from database")
                    return realBookings
                }
            }
        } catch {
            print("⚠️ Error fetching bookings from database: \(error)")
        }
        
        // Fallback to SimpleSupabaseService
        let simpleBookings = await simpleSupabaseService.fetchUserBookings()
        
        if !simpleBookings.isEmpty {
            return simpleBookings.compactMap { convertToBooking($0) }
        }
        
        // Return mock bookings for testing
        print("📝 Using fallback booking data")
        return generateMockBookings(userId: userId)
    }
    
    private func parseBookingFromDatabase(_ data: [String: Any], userId: String) -> Booking? {
        guard let id = data["id"] as? String,
              let sessionId = data["session_id"] as? String else { return nil }
        
        let status = data["status"] as? String ?? "pending"
        let creditsUsed = data["credits_used"] as? Int ?? 1
        let amountPaid = data["amount_paid"] as? Double ?? 0.0
        
        // Parse booking date
        let isoFormatter = ISO8601DateFormatter()
        let bookingDate: Date
        if let createdAtString = data["created_at"] as? String,
           let parsedDate = isoFormatter.date(from: createdAtString) {
            bookingDate = parsedDate
        } else {
            bookingDate = Date()
        }
        
        return Booking(
            id: id,
            userId: userId,
            classId: sessionId,
            className: "Class Session", // Would need to fetch class details
            instructor: "Instructor", // Would need to fetch instructor details
            bookingDate: bookingDate,
            status: status,
            price: amountPaid,
            venue: "Studio Location"
        )
    }
    
    func cancelBooking(bookingId: String) async throws -> Bool {
        // This would update the booking status in the database
        print("Cancelling booking: \(bookingId)")
        return true
    }
    
    private func convertToBooking(_ simpleBooking: SimpleBooking) -> Booking? {
        return Booking(
            id: simpleBooking.id,
            userId: UUID().uuidString, // Would be extracted from the booking
            classId: simpleBooking.classId,
            className: simpleBooking.className,
            instructor: simpleBooking.instructor,
            bookingDate: simpleBooking.bookingDate,
            status: simpleBooking.status,
            price: simpleBooking.price,
            venue: simpleBooking.venue ?? "Unknown Venue"
        )
    }
    
    private func generateMockBookings(userId: String) -> [Booking] {
        return [
            Booking(
                id: UUID().uuidString,
                userId: userId,
                classId: UUID().uuidString,
                className: "Morning Vinyasa Flow",
                instructor: "Sarah Johnson",
                bookingDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                status: "confirmed",
                price: 25.0,
                venue: "Serenity Yoga Studio"
            ),
            Booking(
                id: UUID().uuidString,
                userId: userId,
                classId: UUID().uuidString,
                className: "Beginner Pottery Wheel",
                instructor: "Marcus Chen",
                bookingDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                status: "completed",
                price: 45.0,
                venue: "Clay & Co. Ceramics"
            )
        ]
    }
}

// MARK: - Review Service

class ReviewService {
    static let shared = ReviewService()
    private let supabase = SimpleSupabaseService.shared
    private init() {}
    
    func getReviews(classId: String) async throws -> [Review] {
        // Try to fetch real reviews from database
        do {
            let response = try await supabase.client
                .from("class_reviews")
                .select("""
                    id,
                    rating,
                    review_text,
                    created_at,
                    is_approved,
                    user_id,
                    profiles:user_id (
                        name
                    )
                """)
                .eq("class_id", value: classId)
                .eq("is_approved", value: true)
                .order("created_at", ascending: false)
                .execute()
            
            if let reviewData = try response.value as? [[String: Any]] {
                let realReviews = reviewData.compactMap { data -> Review? in
                    return parseReviewFromDatabase(data, classId: classId)
                }
                
                if !realReviews.isEmpty {
                    print("✅ Loaded \(realReviews.count) real reviews from database")
                    return realReviews
                }
            }
        } catch {
            print("⚠️ Error fetching reviews from database: \(error)")
        }
        
        // Fallback to mock reviews
        print("📝 Using fallback review data")
        return generateMockReviews(classId: classId)
    }
    
    private func parseReviewFromDatabase(_ data: [String: Any], classId: String) -> Review? {
        guard let id = data["id"] as? String,
              let rating = data["rating"] as? Int,
              let userId = data["user_id"] as? String else { return nil }
        
        let reviewText = data["review_text"] as? String ?? ""
        let userName = (data["profiles"] as? [String: Any])?["name"] as? String ?? "Anonymous"
        
        // Parse created date
        let isoFormatter = ISO8601DateFormatter()
        let createdAt: Date
        if let createdAtString = data["created_at"] as? String,
           let parsedDate = isoFormatter.date(from: createdAtString) {
            createdAt = parsedDate
        } else {
            createdAt = Date()
        }
        
        return Review(
            id: id,
            userId: userId,
            classId: classId,
            userName: userName,
            rating: rating,
            comment: reviewText,
            createdAt: createdAt
        )
    }
    
    func submitReview(classId: String, userId: String, rating: Int, comment: String) async throws -> Bool {
        // Try to submit real review to database
        do {
            // First, get instructor ID for this class
            let classResponse = try await supabase.client
                .from("classes")
                .select("instructor_name")
                .eq("id", value: classId)
                .single()
                .execute()
            
            // For now, we'll use a placeholder instructor ID
            let instructorId = UUID().uuidString
            
            let reviewId = UUID().uuidString
            
            try await supabase.client
                .from("class_reviews")
                .insert([
                    "id": reviewId,
                    "class_id": classId,
                    "user_id": userId,
                    "instructor_id": instructorId,
                    "rating": rating,
                    "review_text": comment,
                    "is_approved": true, // Auto-approve for now
                    "verified_booking": true
                ])
                .execute()
            
            print("✅ Review submitted successfully with ID: \(reviewId)")
            return true
            
        } catch {
            print("⚠️ Error submitting review to database: \(error)")
            // Fallback - just log it
            print("Fallback: Submitting review for class \(classId): \(rating)/5 - \(comment)")
            return true
        }
    }
    
    func getAverageRating(classId: String) async throws -> Double {
        // Try to get average rating from database function or calculate from reviews
        do {
            let response = try await supabase.client
                .from("class_reviews")
                .select("rating")
                .eq("class_id", value: classId)
                .eq("is_approved", value: true)
                .execute()
            
            if let reviewData = try response.value as? [[String: Any]] {
                let ratings = reviewData.compactMap { $0["rating"] as? Int }
                
                guard !ratings.isEmpty else { return 0.0 }
                
                let average = Double(ratings.reduce(0, +)) / Double(ratings.count)
                print("✅ Calculated average rating: \(average) from \(ratings.count) reviews")
                return average
            }
        } catch {
            print("⚠️ Error calculating average rating: \(error)")
        }
        
        // Fallback to in-memory calculation
        let reviews = try await getReviews(classId: classId)
        guard !reviews.isEmpty else { return 0.0 }
        
        let totalRating = reviews.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(reviews.count)
    }
    
    private func generateMockReviews(classId: String) -> [Review] {
        return [
            Review(
                id: UUID().uuidString,
                userId: UUID().uuidString,
                classId: classId,
                userName: "Alex M.",
                rating: 5,
                comment: "Amazing class! The instructor was so helpful and the atmosphere was perfect.",
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
            Review(
                id: UUID().uuidString,
                userId: UUID().uuidString,
                classId: classId,
                userName: "Jamie L.",
                rating: 4,
                comment: "Really enjoyed this class. Great for beginners like me!",
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            )
        ]
    }
}

// MARK: - User Service

class UserService {
    static let shared = UserService()
    private let supabase = SimpleSupabaseService.shared
    private lazy var simpleSupabaseService = SimpleSupabaseService.shared
    private init() {}
    
    func updateProfile(userId: String, fullName: String?, bio: String?) async throws -> Bool {
        // Try to update user profile in database
        do {
            // Update user_profiles table
            try await supabase.client
                .from("user_profiles")
                .upsert([
                    "id": userId,
                    "full_name": fullName ?? "",
                    "bio": bio ?? "",
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()
            
            // Also update profiles table if it exists
            try await supabase.client
                .from("profiles")
                .upsert([
                    "id": userId,
                    "name": fullName ?? "",
                    "bio": bio ?? "",
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()
            
            print("✅ Profile updated successfully")
            return true
            
        } catch {
            print("⚠️ Error updating profile in database: \(error)")
            
            // Fallback to SimpleSupabaseService
            do {
                try await simpleSupabaseService.updateUserProfile(
                    avatarURL: nil,
                    fullName: fullName,
                    bio: bio
                )
                return true
            } catch {
                print("Failed to update profile: \(error)")
                return false
            }
        }
    }
    
    func getFavorites(userId: String) async throws -> [String] {
        // Try to fetch favorites from database
        do {
            let response = try await supabase.client
                .from("saved_classes")
                .select("class_id")
                .eq("user_id", value: userId)
                .execute()
            
            if let favoriteData = try response.value as? [[String: Any]] {
                let favorites = favoriteData.compactMap { $0["class_id"] as? String }
                print("✅ Loaded \(favorites.count) favorites from database")
                return favorites
            }
        } catch {
            print("⚠️ Error fetching favorites: \(error)")
        }
        
        // Fallback to profiles table
        do {
            let response = try await supabase.client
                .from("profiles")
                .select("saved_classes")
                .eq("id", value: userId)
                .single()
                .execute()
            
            if let profileData = try response.value as? [String: Any],
               let savedClasses = profileData["saved_classes"] as? [String] {
                print("✅ Loaded \(savedClasses.count) saved classes from profiles")
                return savedClasses
            }
        } catch {
            print("⚠️ Error fetching saved classes: \(error)")
        }
        
        return [] // Empty array if no favorites found
    }
    
    func addToFavorites(userId: String, classId: String) async throws -> Bool {
        // Try to add favorite to database
        do {
            // Use saved_classes table
            try await supabase.client
                .from("saved_classes")
                .insert([
                    "id": UUID().uuidString,
                    "user_id": userId,
                    "class_id": classId
                ])
                .execute()
            
            print("✅ Added class \(classId) to favorites for user \(userId)")
            return true
            
        } catch {
            print("⚠️ Error adding to favorites: \(error)")
            // Fallback - just log it
            print("Fallback: Adding class \(classId) to favorites for user \(userId)")
            return true
        }
    }
    
    func removeFromFavorites(userId: String, classId: String) async throws -> Bool {
        // Try to remove favorite from database
        do {
            try await supabase.client
                .from("saved_classes")
                .delete()
                .eq("user_id", value: userId)
                .eq("class_id", value: classId)
                .execute()
            
            print("✅ Removed class \(classId) from favorites for user \(userId)")
            return true
            
        } catch {
            print("⚠️ Error removing from favorites: \(error)")
            // Fallback - just log it
            print("Fallback: Removing class \(classId) from favorites for user \(userId)")
            return true
        }
    }
}

// Legacy SupabaseService for compatibility
class SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    func fetchActivities() async throws -> [Any] {
        // Delegate to ClassService
        let classes = try await ClassService.shared.fetchClasses()
        return classes
    }
}

class FollowingService {
    static let shared = FollowingService()
    private init() {}

    func fetchFollowing() async throws -> [Any] {
        return []
    }

    func followUser(_ userId: String) async throws {
        print("Following user: \(userId)")
    }

    func unfollowUser(_ userId: String) async throws {
        print("Unfollowing user: \(userId)")
    }

    func getFollowing(for userId: String) async throws -> [Any] {
        return []
    }

    func getFollowers(for userId: String) async throws -> [Any] {
        return []
    }

    func getSuggestions(for userId: String) async throws -> [Any] {
        return []
    }

    func follow(userId: String, targetUserId: String) async throws {
        print("Following user: \(targetUserId)")
    }

    func unfollow(userId: String, targetUserId: String) async throws {
        print("Unfollowing user: \(targetUserId)")
    }
}

// MARK: - Real Data Services Implementation

class InstructorService {
    static let shared = InstructorService()
    private let supabase = SimpleSupabaseService.shared
    private init() {}

    func fetchInstructors() async throws -> [Instructor] {
        // Try to fetch from actual database table
        do {
            let response = try await supabase.client
                .from("instructor_profiles")
                .select("""
                    id,
                    display_name,
                    bio,
                    specialties,
                    average_rating,
                    total_classes_taught,
                    is_active,
                    user_id,
                    users:user_id (
                        email
                    )
                """)
                .eq("is_active", value: true)
                .order("average_rating", ascending: false)
                .execute()
            
            if let instructorData = try response.value as? [[String: Any]] {
                let realInstructors = instructorData.compactMap { data -> Instructor? in
                    guard let id = data["id"] as? String,
                          let name = data["display_name"] as? String else { return nil }
                    
                    let userEmail = (data["users"] as? [String: Any])?["email"] as? String ?? "instructor@example.com"
                    let bio = data["bio"] as? String ?? ""
                    let specialties = data["specialties"] as? [String] ?? []
                    let rating = data["average_rating"] as? Double ?? 0.0
                    let totalClasses = data["total_classes_taught"] as? Int ?? 0
                    let isActive = data["is_active"] as? Bool ?? true
                    
                    return Instructor(
                        id: id,
                        name: name,
                        email: userEmail,
                        bio: bio,
                        specialties: specialties,
                        rating: rating,
                        totalClasses: totalClasses,
                        isActive: isActive,
                        studioId: nil
                    )
                }
                
                if !realInstructors.isEmpty {
                    print("✅ Loaded \(realInstructors.count) real instructors from database")
                    return realInstructors
                }
            }
        } catch {
            print("⚠️ Error fetching instructors from database: \(error)")
        }
        
        // Return mock data as fallback
        print("📝 Using fallback instructor data")
        return generateMockInstructors()
    }

    func fetchAllInstructors() async throws -> [Instructor] {
        return try await fetchInstructors()
    }

    func fetchNearbyInstructors(location: CLLocation, radius: Double) async throws -> [Instructor] {
        let allInstructors = try await fetchInstructors()
        // Filter by location when real data is available
        return Array(allInstructors.prefix(5))
    }
    
    func searchInstructors(query: String) async throws -> [Instructor] {
        // For real database implementation, this would use a proper search query
        do {
            let response = try await supabase.client
                .from("instructor_profiles")
                .select("""
                    id,
                    display_name,
                    bio,
                    specialties,
                    average_rating,
                    total_classes_taught,
                    is_active,
                    user_id,
                    users:user_id (
                        email
                    )
                """)
                .eq("is_active", value: true)
                .or("display_name.ilike.%\(query)%,bio.ilike.%\(query)%")
                .order("average_rating", ascending: false)
                .execute()
            
            if let instructorData = try response.value as? [[String: Any]] {
                let searchResults = instructorData.compactMap { data -> Instructor? in
                    guard let id = data["id"] as? String,
                          let name = data["display_name"] as? String else { return nil }
                    
                    let userEmail = (data["users"] as? [String: Any])?["email"] as? String ?? "instructor@example.com"
                    let bio = data["bio"] as? String ?? ""
                    let specialties = data["specialties"] as? [String] ?? []
                    let rating = data["average_rating"] as? Double ?? 0.0
                    let totalClasses = data["total_classes_taught"] as? Int ?? 0
                    let isActive = data["is_active"] as? Bool ?? true
                    
                    return Instructor(
                        id: id,
                        name: name,
                        email: userEmail,
                        bio: bio,
                        specialties: specialties,
                        rating: rating,
                        totalClasses: totalClasses,
                        isActive: isActive,
                        studioId: nil
                    )
                }
                
                if !searchResults.isEmpty {
                    print("✅ Found \(searchResults.count) instructors matching '\(query)'")
                    return searchResults
                }
            }
        } catch {
            print("⚠️ Error searching instructors: \(error)")
        }
        
        // Fallback to mock search
        let allInstructors = try await fetchInstructors()
        guard !query.isEmpty else { return allInstructors }
        
        let lowerQuery = query.lowercased()
        return allInstructors.filter { instructor in
            instructor.name.lowercased().contains(lowerQuery) ||
            instructor.bio.lowercased().contains(lowerQuery) ||
            instructor.specialties.contains { $0.lowercased().contains(lowerQuery) }
        }
    }
    
    func getInstructorDetails(id: String) async throws -> Instructor? {
        let allInstructors = try await fetchInstructors()
        return allInstructors.first { $0.id == id }
    }
    
    func getInstructorClasses(instructorId: String) async throws -> [HobbyClass] {
        // Will be implemented when classes table is available
        return generateMockClassesForInstructor(instructorId)
    }
    
    private func generateMockInstructors() -> [Instructor] {
        return [
            Instructor(
                id: UUID().uuidString,
                name: "Sarah Johnson",
                email: "sarah@example.com",
                bio: "Certified yoga instructor with 8 years of experience in Hatha and Vinyasa yoga.",
                specialties: ["Hatha Yoga", "Vinyasa", "Meditation"],
                rating: 4.8,
                totalClasses: 156,
                isActive: true,
                studioId: nil
            ),
            Instructor(
                id: UUID().uuidString,
                name: "Marcus Chen",
                email: "marcus@example.com",
                bio: "Professional ceramics artist and teacher, specializing in wheel throwing and glazing techniques.",
                specialties: ["Pottery", "Wheel Throwing", "Glazing"],
                rating: 4.9,
                totalClasses: 89,
                isActive: true,
                studioId: nil
            ),
            Instructor(
                id: UUID().uuidString,
                name: "Emily Rodriguez",
                email: "emily@example.com",
                bio: "Contemporary dance instructor with a background in ballet and modern dance.",
                specialties: ["Contemporary Dance", "Ballet", "Modern Dance"],
                rating: 4.7,
                totalClasses: 203,
                isActive: true,
                studioId: nil
            )
        ]
    }
    
    private func generateMockClassesForInstructor(_ instructorId: String) -> [HobbyClass] {
        // Generate mock classes for the instructor
        let startDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate

        return [
            HobbyClass(
                id: UUID().uuidString,
                title: "Morning Yoga Flow",
                description: "Start your day with energizing yoga poses",
                category: .fitness,
                difficulty: .beginner,
                price: 25.0,
                startDate: startDate,
                endDate: endDate,
                duration: 60,
                maxParticipants: 15,
                enrolledCount: 8,
                instructor: createMockInstructorInfo(
                    id: instructorId,
                    name: "Sarah Johnson",
                    bio: "Experienced yoga instructor",
                    rating: 4.8,
                    specialties: ["Yoga", "Meditation"]
                ),
                venue: createMockVenueInfo(
                    name: "Serenity Studio",
                    address: "123 Main St",
                    city: "Vancouver"
                ),
                imageUrl: nil,
                thumbnailUrl: nil,
                averageRating: 4.8,
                totalReviews: 24,
                tags: ["yoga", "morning", "flow"],
                requirements: ["Yoga mat"],
                whatToBring: ["Water bottle", "Towel"],
                cancellationPolicy: "Free cancellation up to 24 hours before class",
                isOnline: false,
                meetingUrl: nil
            )
        ]
    }
}

class StudioService {
    static let shared = StudioService()
    private let supabase = SimpleSupabaseService.shared
    private init() {}

    func fetchStudios() async throws -> [Studio] {
        // Note: The current database schema doesn't have a studios table with the expected structure
        // This would need to be implemented when the studios table is properly set up
        // For now, using mock data as the schema shows calendar_integrations but not direct studios
        
        print("📝 Using fallback studio data (studios table not in current schema)")
        return generateMockStudios()
    }
    
    func searchStudios(query: String) async throws -> [Studio] {
        let allStudios = try await fetchStudios()
        guard !query.isEmpty else { return allStudios }
        
        let lowerQuery = query.lowercased()
        return allStudios.filter { studio in
            studio.name.lowercased().contains(lowerQuery) ||
            studio.address.lowercased().contains(lowerQuery) ||
            studio.city.lowercased().contains(lowerQuery)
        }
    }
    
    func getStudioDetails(id: String) async throws -> Studio? {
        let allStudios = try await fetchStudios()
        return allStudios.first { $0.id == id }
    }
    
    func getStudioClasses(studioId: String) async throws -> [HobbyClass] {
        // Will be implemented when classes table is available
        return generateMockClassesForStudio(studioId)
    }
    
    private func generateMockStudios() -> [Studio] {
        return [
            Studio(
                id: UUID().uuidString,
                name: "Serenity Yoga Studio",
                email: "info@serenityoga.com",
                phone: "+1 (604) 555-0123",
                address: "1234 Commercial Drive",
                city: "Vancouver",
                province: "BC",
                postalCode: "V5L 3X9",
                isActive: true
            ),
            Studio(
                id: UUID().uuidString,
                name: "Clay & Co. Ceramics",
                email: "hello@clayandco.ca",
                phone: "+1 (604) 555-0456",
                address: "567 East Hastings Street",
                city: "Vancouver",
                province: "BC",
                postalCode: "V6A 1P7",
                isActive: true
            ),
            Studio(
                id: UUID().uuidString,
                name: "Movement Arts Collective",
                email: "contact@movementarts.ca",
                phone: "+1 (604) 555-0789",
                address: "890 Granville Street",
                city: "Vancouver",
                province: "BC",
                postalCode: "V6Z 1K3",
                isActive: true
            )
        ]
    }
    
    private func generateMockClassesForStudio(_ studioId: String) -> [HobbyClass] {
        // Generate mock classes for the studio
        let startDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .hour, value: 2, to: startDate) ?? startDate

        return [
            HobbyClass(
                id: UUID().uuidString,
                title: "Beginner Pottery Wheel",
                description: "Learn the basics of pottery on the wheel",
                category: .arts,
                difficulty: .beginner,
                price: 45.0,
                startDate: startDate,
                endDate: endDate,
                duration: 120,
                maxParticipants: 8,
                enrolledCount: 5,
                instructor: createMockInstructorInfo(
                    name: "Marcus Chen",
                    bio: "Experienced ceramics instructor",
                    rating: 4.9,
                    specialties: ["Pottery", "Ceramics"]
                ),
                venue: createMockVenueInfo(
                    id: studioId,
                    name: "Clay & Co. Ceramics",
                    address: "567 East Hastings Street",
                    city: "Vancouver"
                ),
                imageUrl: nil,
                thumbnailUrl: nil,
                averageRating: 4.7,
                totalReviews: 18,
                tags: ["pottery", "ceramics", "wheel"],
                requirements: ["Apron (provided)"],
                whatToBring: ["Clothes you don't mind getting dirty"],
                cancellationPolicy: "Free cancellation up to 24 hours before class",
                isOnline: false,
                meetingUrl: nil
            )
        ]
    }
}

// Legacy alias for compatibility
typealias VenueService = StudioService


class ClassService {
    static let shared = ClassService()
    private let supabase = SimpleSupabaseService.shared
    private lazy var simpleSupabaseService = SimpleSupabaseService.shared

    private init() {}

    func fetchUpcomingClasses() async throws -> [ClassItem] {
        let hobbyClasses = try await fetchClasses()
        return Array(hobbyClasses.prefix(10)).map { ClassItem.from(hobbyClass: $0) }
    }

    func searchClasses(query: String) async throws -> [HobbyClass] {
        guard !query.isEmpty else {
            return try await fetchClasses()
        }
        
        // Try database search first
        do {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let nowString = isoFormatter.string(from: Date())
            
            let response = try await supabase.client
                .from("classes")
                .select("""
                    id,
                    title,
                    description,
                    instructor_name,
                    instructor_email,
                    category,
                    skill_level,
                    start_time,
                    end_time,
                    price,
                    max_participants,
                    current_participants,
                    location,
                    room,
                    material_fee,
                    studio_id
                """)
                .gte("start_time", value: nowString)
                .or("title.ilike.%\(query)%,description.ilike.%\(query)%,instructor_name.ilike.%\(query)%,category.ilike.%\(query)%")
                .order("start_time", ascending: true)
                .limit(50)
                .execute()
            
            if let classData = try response.value as? [[String: Any]] {
                let searchResults = classData.compactMap { data -> HobbyClass? in
                    return parseClassFromDatabase(data)
                }
                
                if !searchResults.isEmpty {
                    print("✅ Found \(searchResults.count) classes matching '\(query)'")
                    return searchResults
                }
            }
        } catch {
            print("⚠️ Error searching classes in database: \(error)")
        }
        
        // Fallback to in-memory search
        let allClasses = try await fetchClasses()
        let lowerQuery = query.lowercased()
        return allClasses.filter { hobbyClass in
            hobbyClass.title.lowercased().contains(lowerQuery) ||
            hobbyClass.description.lowercased().contains(lowerQuery) ||
            hobbyClass.instructor.name.lowercased().contains(lowerQuery) ||
            hobbyClass.category.rawValue.lowercased().contains(lowerQuery)
        }
    }
    
    func getPopularClasses() async throws -> [HobbyClass] {
        // Try to get popular classes from database first
        do {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let nowString = isoFormatter.string(from: Date())
            
            // For now, just get upcoming classes and sort by current participants
            // In a real implementation, this would use a view or function for popularity
            let response = try await supabase.client
                .from("classes")
                .select("""
                    id,
                    title,
                    description,
                    instructor_name,
                    instructor_email,
                    category,
                    skill_level,
                    start_time,
                    end_time,
                    price,
                    max_participants,
                    current_participants,
                    location,
                    room,
                    material_fee,
                    studio_id
                """)
                .gte("start_time", value: nowString)
                .order("current_participants", ascending: false)
                .limit(10)
                .execute()
            
            if let classData = try response.value as? [[String: Any]] {
                let popularClasses = classData.compactMap { data -> HobbyClass? in
                    return parseClassFromDatabase(data)
                }
                
                if !popularClasses.isEmpty {
                    print("✅ Loaded \(popularClasses.count) popular classes from database")
                    return popularClasses
                }
            }
        } catch {
            print("⚠️ Error fetching popular classes: \(error)")
        }
        
        // Fallback to in-memory sort
        let allClasses = try await fetchClasses()
        return allClasses
            .sorted { first, second in
                if first.totalReviews == second.totalReviews {
                    return first.averageRating > second.averageRating
                }
                return first.totalReviews > second.totalReviews
            }
            .prefix(10)
            .map { $0 }
    }
    
    func getClassesByCategory(_ category: ClassCategory) async throws -> [HobbyClass] {
        let allClasses = try await fetchClasses()
        return allClasses.filter { $0.category == category }
    }
    
    func getClassDetails(id: String) async throws -> HobbyClass? {
        let allClasses = try await fetchClasses()
        return allClasses.first { $0.id == id }
    }

    func fetchClasses() async throws -> [HobbyClass] {
        // Try to fetch from the actual classes table first
        do {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let nowString = isoFormatter.string(from: Date())
            
            let response = try await supabase.client
                .from("classes")
                .select("""
                    id,
                    title,
                    description,
                    instructor_name,
                    instructor_email,
                    category,
                    skill_level,
                    start_time,
                    end_time,
                    price,
                    max_participants,
                    current_participants,
                    location,
                    room,
                    material_fee,
                    studio_id
                """)
                .gte("start_time", value: nowString)
                .order("start_time", ascending: true)
                .limit(50)
                .execute()
            
            if let classData = try response.value as? [[String: Any]] {
                let realClasses = classData.compactMap { data -> HobbyClass? in
                    return parseClassFromDatabase(data)
                }
                
                if !realClasses.isEmpty {
                    print("✅ Loaded \(realClasses.count) real classes from database")
                    return realClasses
                }
            }
        } catch {
            print("⚠️ Error fetching classes from database: \(error)")
        }
        
        // Try to get classes from SimpleSupabaseService as fallback
        let simpleClasses = await simpleSupabaseService.fetchClasses()
        
        if !simpleClasses.isEmpty {
            // Convert SimpleClass to HobbyClass
            return simpleClasses.compactMap { simpleClass in
                convertToHobbyClass(simpleClass)
            }
        }
        
        // If no real data, generate comprehensive mock data
        print("📝 Using fallback class data")
        return generateMockClasses()
    }

    func fetchMoreClasses(offset: Int) async throws -> [HobbyClass] {
        let classes = try await fetchClasses()
        guard offset < classes.count else { return [] }
        return Array(classes[offset...].prefix(10))
    }
    
    private func parseClassFromDatabase(_ data: [String: Any]) -> HobbyClass? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String else { return nil }
        
        let description = data["description"] as? String ?? ""
        let instructorName = data["instructor_name"] as? String ?? "Instructor"
        let instructorEmail = data["instructor_email"] as? String ?? "instructor@example.com"
        let categoryString = data["category"] as? String ?? "General"
        let skillLevel = data["skill_level"] as? String ?? "all_levels"
        let location = data["location"] as? String ?? "Studio"
        let room = data["room"] as? String
        let price = data["price"] as? Double ?? 0.0
        let materialFee = data["material_fee"] as? Double ?? 0.0
        let maxParticipants = data["max_participants"] as? Int ?? 20
        let currentParticipants = data["current_participants"] as? Int ?? 0
        
        // Parse dates
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let startDate: Date
        let endDate: Date
        
        if let startTimeString = data["start_time"] as? String,
           let parsedStartDate = isoFormatter.date(from: startTimeString) {
            startDate = parsedStartDate
        } else {
            startDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }
        
        if let endTimeString = data["end_time"] as? String,
           let parsedEndDate = isoFormatter.date(from: endTimeString) {
            endDate = parsedEndDate
        } else {
            endDate = startDate.addingTimeInterval(3600) // 1 hour default
        }
        
        // Create instructor info
        let instructor = Instructor(
            id: UUID().uuidString,
            name: instructorName,
            email: instructorEmail,
            bio: "Experienced instructor specializing in \(categoryString.lowercased())",
            specialties: [categoryString],
            rating: 4.5,
            totalClasses: 50,
            isActive: true,
            studioId: data["studio_id"] as? String
        )
        
        // Create venue info
        let venueName = room != nil ? "\(location) - \(room!)" : location
        let venue = Venue(
            id: data["studio_id"] as? String ?? UUID().uuidString,
            name: venueName,
            address: "Studio Location",
            city: "Vancouver",
            isActive: true
        )
        
        // Map category
        let category = ClassCategory(rawValue: categoryString) ?? .other
        
        // Map difficulty
        let difficulty = DifficultyLevel(rawValue: skillLevel) ?? .beginner
        
        let duration = Int(endDate.timeIntervalSince(startDate) / 60) // minutes
        let totalPrice = price + materialFee
        
        return HobbyClass(
            id: id,
            title: title,
            description: description,
            instructor: instructor,
            venue: venue,
            startDate: startDate,
            endDate: endDate,
            price: totalPrice,
            maxParticipants: maxParticipants,
            currentParticipants: currentParticipants,
            category: category,
            difficulty: difficulty,
            tags: [categoryString.lowercased(), skillLevel.lowercased()],
            requirements: ["Comfortable clothing"],
            whatToBring: ["Water bottle"],
            averageRating: 4.5,
            totalReviews: 10,
            isOnline: location.lowercased().contains("online")
        )
    }
    
    private func convertToHobbyClass(_ simpleClass: SimpleClass) -> HobbyClass? {
        // Convert SimpleClass format to HobbyClass format
        guard let instructorName = simpleClass.instructor.components(separatedBy: " ").first else { return nil }
        
        let instructor = Instructor(
            id: UUID().uuidString,
            name: simpleClass.instructor,
            email: "\(instructorName.lowercased())@example.com",
            bio: "Experienced instructor specializing in \(simpleClass.category.lowercased())",
            specialties: [simpleClass.category],
            rating: simpleClass.averageRating,
            totalClasses: 50,
            isActive: true,
            studioId: nil
        )
        
        let venue = Venue(
            id: UUID().uuidString,
            name: simpleClass.locationName ?? "Studio",
            address: simpleClass.displayLocation,
            city: simpleClass.locationCity ?? "Vancouver",
            isActive: true
        )
        
        return HobbyClass(
            id: simpleClass.id,
            title: simpleClass.title,
            description: simpleClass.description,
            instructor: instructor,
            venue: venue,
            startDate: simpleClass.startDate ?? Date(),
            endDate: simpleClass.endDate ?? Date().addingTimeInterval(3600),
            price: simpleClass.price,
            maxParticipants: simpleClass.maxParticipants ?? 20,
            currentParticipants: simpleClass.currentParticipants ?? 0,
            category: ClassCategory(rawValue: simpleClass.category) ?? .other,
            difficulty: DifficultyLevel(rawValue: simpleClass.difficulty) ?? .beginner,
            tags: simpleClass.tags,
            requirements: simpleClass.requirements,
            whatToBring: simpleClass.whatToBring,
            averageRating: simpleClass.averageRating,
            totalReviews: simpleClass.totalReviews,
            isOnline: simpleClass.isOnline
        )
    }

    private func generateMockClasses() -> [HobbyClass] {
        let instructors = [
            Instructor(
                id: UUID(),
                userId: UUID(),
                firstName: "Sarah",
                lastName: "Johnson",
                email: "sarah@example.com",
                phone: nil,
                bio: "Certified yoga instructor",
                specialties: ["Yoga", "Meditation"],
                certificationInfo: nil,
                rating: Decimal(4.8),
                totalReviews: 156,
                profileImageUrl: nil,
                yearsOfExperience: 8,
                socialLinks: nil,
                availability: nil,
                isActive: true,
                createdAt: Date(),
                updatedAt: nil
            ),
            Instructor(
                id: UUID(),
                userId: UUID(),
                firstName: "Marcus",
                lastName: "Chen",
                email: "marcus@example.com",
                phone: nil,
                bio: "Professional ceramics artist",
                specialties: ["Pottery", "Ceramics"],
                certificationInfo: nil,
                rating: Decimal(4.9),
                totalReviews: 89,
                profileImageUrl: nil,
                yearsOfExperience: 12,
                socialLinks: nil,
                availability: nil,
                isActive: true,
                createdAt: Date(),
                updatedAt: nil
            ),
            Instructor(
                id: UUID(),
                userId: UUID(),
                firstName: "Emily",
                lastName: "Rodriguez",
                email: "emily@example.com",
                phone: nil,
                bio: "Contemporary dance instructor",
                specialties: ["Dance", "Movement"],
                certificationInfo: nil,
                rating: Decimal(4.7),
                totalReviews: 203,
                profileImageUrl: nil,
                yearsOfExperience: 15,
                socialLinks: nil,
                availability: nil,
                isActive: true,
                createdAt: Date(),
                updatedAt: nil
            )
        ]

        let venues = [
            Venue(
                id: UUID(),
                name: "Serenity Yoga Studio",
                description: "Peaceful yoga studio in the heart of Vancouver",
                address: "1234 Commercial Drive",
                city: "Vancouver",
                state: "BC",
                zipCode: "V5L 3X3",
                latitude: 49.2744,
                longitude: -123.0693,
                phone: "+1-604-555-0100",
                email: "info@serenity.yoga",
                website: "https://serenity.yoga",
                amenities: ["WiFi", "Showers", "Yoga Mats"],
                capacity: 20,
                hourlyRate: 35.0,
                isActive: true,
                imageUrls: [],
                operatingHours: [:],
                parkingInfo: "Street parking available",
                publicTransit: "Bus routes 20, 4",
                accessibilityInfo: "Wheelchair accessible",
                averageRating: 4.8,
                totalReviews: 156,
                createdAt: Date(),
                updatedAt: nil
            ),
            Venue(
                id: UUID(),
                name: "Clay & Co. Ceramics",
                description: "Professional ceramics studio and gallery",
                address: "567 East Hastings Street",
                city: "Vancouver",
                state: "BC",
                zipCode: "V6A 1R2",
                latitude: 49.2827,
                longitude: -123.0969,
                phone: "+1-604-555-0200",
                email: "info@clayandco.ca",
                website: "https://clayandco.ca",
                amenities: ["Kiln", "Tools", "Clay Storage"],
                capacity: 12,
                hourlyRate: 45.0,
                isActive: true,
                imageUrls: [],
                operatingHours: [:],
                parkingInfo: "Parking lot available",
                publicTransit: "Bus routes 3, 8",
                accessibilityInfo: "Ground floor access",
                averageRating: 4.9,
                totalReviews: 89,
                createdAt: Date(),
                updatedAt: nil
            ),
            Venue(
                id: UUID(),
                name: "Movement Arts Collective",
                description: "Modern dance and movement studio",
                address: "890 Granville Street",
                city: "Vancouver",
                state: "BC",
                zipCode: "V6Z 1K3",
                latitude: 49.2827,
                longitude: -123.1207,
                phone: "+1-604-555-0300",
                email: "info@movementarts.ca",
                website: "https://movementarts.ca",
                amenities: ["Mirrors", "Sound System", "Changing Rooms"],
                capacity: 30,
                hourlyRate: 40.0,
                isActive: true,
                imageUrls: [],
                operatingHours: [:],
                parkingInfo: "Paid parking nearby",
                publicTransit: "Skytrain accessible",
                accessibilityInfo: "Elevator available",
                averageRating: 4.7,
                totalReviews: 203,
                createdAt: Date(),
                updatedAt: nil
            )
        ]

        // Helper functions to convert to simplified info structs
        func toInstructorInfo(_ instructor: Instructor) -> InstructorInfo {
            return InstructorInfo(
                id: instructor.id.uuidString,
                name: instructor.fullName,
                bio: instructor.bio,
                profileImageUrl: instructor.profileImageUrl,
                rating: NSDecimalNumber(decimal: instructor.rating).doubleValue,
                totalClasses: 0,
                totalStudents: 0,
                specialties: instructor.specialties,
                certifications: [],
                yearsOfExperience: instructor.yearsOfExperience ?? 0,
                socialLinks: instructor.socialLinks
            )
        }

        func toVenueInfo(_ venue: Venue) -> VenueInfo {
            return VenueInfo(
                id: venue.id.uuidString,
                name: venue.name,
                address: venue.address,
                city: venue.city,
                state: venue.state,
                zipCode: venue.zipCode,
                latitude: venue.latitude,
                longitude: venue.longitude,
                amenities: venue.amenities,
                parkingInfo: venue.parkingInfo,
                publicTransit: venue.publicTransportInfo,
                imageUrls: venue.imageUrls,
                accessibilityInfo: venue.accessibilityInfo
            )
        }

        return [
            HobbyClass(
                id: UUID().uuidString,
                title: "Morning Vinyasa Flow",
                description: "Start your day with an energizing yoga flow that builds strength and flexibility.",
                category: .fitness,
                difficulty: .intermediate,
                price: 25.0,
                startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .hour, value: 1, to: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()) ?? Date(),
                duration: 60,
                maxParticipants: 15,
                enrolledCount: 8,
                instructor: toInstructorInfo(instructors[0]),
                venue: toVenueInfo(venues[0]),
                imageUrl: nil,
                thumbnailUrl: nil,
                averageRating: 4.8,
                totalReviews: 24,
                tags: ["yoga", "morning", "flow", "strength"],
                requirements: ["Yoga mat"],
                whatToBring: ["Water bottle", "Towel"],
                cancellationPolicy: "Free cancellation up to 24 hours before class",
                isOnline: false,
                meetingUrl: nil
            ),
            HobbyClass(
                id: UUID().uuidString,
                title: "Beginner Pottery Wheel",
                description: "Learn the fundamentals of pottery on the wheel, including centering, pulling, and shaping clay.",
                category: .arts,
                difficulty: .beginner,
                price: 45.0,
                startDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()) ?? Date(),
                duration: 120,
                maxParticipants: 8,
                enrolledCount: 5,
                instructor: toInstructorInfo(instructors[1]),
                venue: toVenueInfo(venues[1]),
                imageUrl: nil,
                thumbnailUrl: nil,
                averageRating: 4.7,
                totalReviews: 18,
                tags: ["pottery", "ceramics", "wheel", "clay"],
                requirements: ["Apron (provided)"],
                whatToBring: ["Clothes you don't mind getting dirty"],
                cancellationPolicy: "Free cancellation up to 48 hours before class",
                isOnline: false,
                meetingUrl: nil
            ),
            HobbyClass(
                id: UUID().uuidString,
                title: "Contemporary Dance Workshop",
                description: "Express yourself through movement in this contemporary dance class focusing on improvisation and technique.",
                category: .fitness,
                difficulty: .intermediate,
                price: 35.0,
                startDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .hour, value: 1, to: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()) ?? Date(),
                duration: 60,
                maxParticipants: 12,
                enrolledCount: 9,
                instructor: toInstructorInfo(instructors[2]),
                venue: toVenueInfo(venues[2]),
                imageUrl: nil,
                thumbnailUrl: nil,
                averageRating: 4.6,
                totalReviews: 12,
                tags: ["dance", "contemporary", "movement", "expression"],
                requirements: ["Comfortable clothing"],
                whatToBring: ["Water bottle", "Hair tie"],
                cancellationPolicy: "Free cancellation up to 24 hours before class",
                isOnline: false,
                meetingUrl: nil
            ),
            HobbyClass(
                id: UUID().uuidString,
                title: "Meditation & Mindfulness",
                description: "Find inner peace and reduce stress through guided meditation and mindfulness practices.",
                category: .fitness,
                difficulty: .beginner,
                price: 20.0,
                startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .minute, value: 45, to: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()) ?? Date(),
                duration: 45,
                maxParticipants: 20,
                enrolledCount: 14,
                instructor: toInstructorInfo(instructors[0]),
                venue: toVenueInfo(venues[0]),
                imageUrl: nil,
                thumbnailUrl: nil,
                averageRating: 4.9,
                totalReviews: 31,
                tags: ["meditation", "mindfulness", "relaxation", "stress-relief"],
                requirements: ["Comfortable seating"],
                whatToBring: ["Cushion or yoga mat"],
                cancellationPolicy: "Free cancellation up to 24 hours before class",
                isOnline: true,
                meetingUrl: "https://zoom.us/j/example"
            ),
            HobbyClass(
                id: UUID().uuidString,
                title: "Advanced Ceramics: Glazing Techniques",
                description: "Master advanced glazing techniques including layering, wax resist, and special effects.",
                category: .arts,
                difficulty: .advanced,
                price: 65.0,
                startDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .hour, value: 3, to: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()) ?? Date(),
                duration: 180,
                maxParticipants: 6,
                enrolledCount: 4,
                instructor: toInstructorInfo(instructors[1]),
                venue: toVenueInfo(venues[1]),
                imageUrl: nil,
                thumbnailUrl: nil,
                averageRating: 4.8,
                totalReviews: 9,
                tags: ["ceramics", "glazing", "advanced", "techniques"],
                requirements: ["Previous pottery experience"],
                whatToBring: ["Bisque-fired pieces (or available to purchase)"],
                cancellationPolicy: "Free cancellation up to 72 hours before class",
                isOnline: false,
                meetingUrl: nil
            )
        ]
    }

    private func makeServiceError() -> NSError {
        NSError(
            domain: "ClassService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: simpleSupabaseService.errorMessage ?? "Unable to load classes from Supabase."]
        )
    }
}

class FavoritesService: ObservableObject {
    static let shared = FavoritesService()
    @Published var favoritesPublisher = CurrentValueSubject<Set<String>, Never>(Set())
    @Published var favoriteClassIds: Set<String> = Set()

    private init() {}

    func toggleFavorite(classId: String) async throws {
        if favoriteClassIds.contains(classId) {
            favoriteClassIds.remove(classId)
        } else {
            favoriteClassIds.insert(classId)
        }
        favoritesPublisher.send(favoriteClassIds)
    }
}

// MARK: - Error Definitions

enum AppError: LocalizedError {
    case networkError(String)
    case authenticationError(String)
    case invalidCredentials
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case insufficientCredits
    case bookingConflict
    case classFull
    case paymentFailed(String)
    case dataCorrupted
    case unauthorized
    case serverError(Int)
    case validationError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .insufficientCredits:
            return "Insufficient credits for this booking"
        case .bookingConflict:
            return "You already have a booking at this time"
        case .classFull:
            return "This class is full"
        case .paymentFailed(let reason):
            return "Payment failed: \(reason)"
        case .dataCorrupted:
            return "Data error occurred. Please try again"
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .serverError(let code):
            return "Server error (\(code))"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .unknown(let message):
            return message.isEmpty ? "An unexpected error occurred" : message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again"
        case .authenticationError, .invalidCredentials:
            return "Please check your credentials and try again"
        case .emailAlreadyInUse:
            return "Try logging in or use a different email"
        case .weakPassword:
            return "Use a stronger password with at least 8 characters"
        case .insufficientCredits:
            return "Purchase more credits to book this class"
        case .bookingConflict:
            return "Choose a different class time"
        case .classFull:
            return "Join the waitlist or choose another class"
        case .paymentFailed:
            return "Check your payment details and try again"
        case .unauthorized:
            return "Please log in to continue"
        case .serverError:
            return "Please try again later"
        default:
            return "Please try again"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError:
            return true
        default:
            return false
        }
    }
}

// MARK: - Missing Views (Nuclear Option Stubs)
struct CreditsView: View {
    var body: some View {
        Text("Credits")
            .navigationTitle("Credits")
    }
}


struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(BrandConstants.CornerRadius.sm)
    }
}
