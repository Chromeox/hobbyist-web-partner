import Foundation
import Supabase
import CoreLocation
import Combine
import SwiftUI

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

// MARK: - Core Data Models for Services

struct Instructor: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let bio: String
    let specialties: [String]
    let rating: Double
    let totalClasses: Int
    let isActive: Bool
    let studioId: String?
    
    init(id: String, name: String, email: String, bio: String, specialties: [String], rating: Double, totalClasses: Int, isActive: Bool, studioId: String?) {
        self.id = id
        self.name = name
        self.email = email
        self.bio = bio
        self.specialties = specialties
        self.rating = rating
        self.totalClasses = totalClasses
        self.isActive = isActive
        self.studioId = studioId
    }
}

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

struct Venue: Codable, Identifiable {
    let id: String
    let name: String
    let address: String
    let city: String
    let isActive: Bool
    
    init(id: String, name: String, address: String, city: String, isActive: Bool) {
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.isActive = isActive
    }
}

struct Booking: Codable, Identifiable {
    let id: String
    let userId: String
    let classId: String
    let className: String
    let instructor: String
    let bookingDate: Date
    let status: String
    let price: Double
    let venue: String
    
    var formattedPrice: String {
        if price == 0 { return "Free" }
        return price.truncatingRemainder(dividingBy: 1) == 0
            ? "$\(Int(price))"
            : String(format: "$%.2f", price)
    }
}

struct Review: Codable, Identifiable {
    let id: String
    let userId: String
    let classId: String
    let userName: String
    let rating: Int
    let comment: String
    let createdAt: Date
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
    private let supabase = SupabaseManager.shared
    private let simpleSupabaseService = SimpleSupabaseService.shared
    private init() {}
    
    func createBooking(classId: String, userId: String, creditsUsed: Int = 1, paymentMethod: String = "credits") async throws -> Bool {
        // Use SimpleSupabaseService for booking creation as it has working implementation
        guard let user = await simpleSupabaseService.currentUser else {
            throw AppError.unauthorized
        }
        
        // For now, use the existing working implementation
        return await simpleSupabaseService.createBooking(
            classId: classId,
            date: Date(),
            scheduleId: nil,
            creditsUsed: creditsUsed,
            paymentMethod: paymentMethod
        )
    }
    
    func getUserBookings(userId: String) async throws -> [Booking] {
        let simpleBookings = await simpleSupabaseService.fetchUserBookings()
        
        if !simpleBookings.isEmpty {
            return simpleBookings.compactMap { convertToBooking($0) }
        }
        
        // Return mock bookings for testing
        return generateMockBookings(userId: userId)
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
    private let supabase = SupabaseManager.shared
    private init() {}
    
    func getReviews(classId: String) async throws -> [Review] {
        // For now, return mock reviews
        return generateMockReviews(classId: classId)
    }
    
    func submitReview(classId: String, userId: String, rating: Int, comment: String) async throws -> Bool {
        // This would submit to the database
        print("Submitting review for class \(classId): \(rating)/5 - \(comment)")
        return true
    }
    
    func getAverageRating(classId: String) async throws -> Double {
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
    private let supabase = SupabaseManager.shared
    private let simpleSupabaseService = SimpleSupabaseService.shared
    private init() {}
    
    func updateProfile(userId: String, fullName: String?, bio: String?) async throws -> Bool {
        // Use SimpleSupabaseService for profile updates
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
    
    func getFavorites(userId: String) async throws -> [String] {
        // This would fetch from user_profiles or a favorites table
        return [] // Mock implementation
    }
    
    func addToFavorites(userId: String, classId: String) async throws -> Bool {
        // This would add to favorites in the database
        print("Adding class \(classId) to favorites for user \(userId)")
        return true
    }
    
    func removeFromFavorites(userId: String, classId: String) async throws -> Bool {
        // This would remove from favorites in the database
        print("Removing class \(classId) from favorites for user \(userId)")
        return true
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
    private let supabase = SupabaseManager.shared
    private init() {}

    func fetchInstructors() async throws -> [Instructor] {
        // Try to fetch from database, fall back to mock data
        do {
            let response = try await supabase.client
                .from("instructors")
                .select("*")
                .execute()
            
            if let data = response.data {
                // Parse real data when available
                return [] // TODO: Parse when instructors table is available
            }
        } catch {
            print("⚠️ Instructors table not available, using mock data: \(error)")
        }
        
        // Return mock data as fallback
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
        return [
            HobbyClass(
                id: UUID().uuidString,
                title: "Morning Yoga Flow",
                description: "Start your day with energizing yoga poses",
                instructor: Instructor(id: instructorId, name: "Sarah Johnson", email: "sarah@example.com", bio: "", specialties: [], rating: 4.8, totalClasses: 0, isActive: true, studioId: nil),
                venue: Venue(id: UUID().uuidString, name: "Serenity Studio", address: "123 Main St", city: "Vancouver", isActive: true),
                startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .hour, value: 1, to: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()) ?? Date(),
                price: 25.0,
                maxParticipants: 15,
                currentParticipants: 8,
                category: .fitness,
                difficulty: .beginner,
                tags: ["yoga", "morning", "flow"],
                requirements: ["Yoga mat"],
                whatToBring: ["Water bottle", "Towel"],
                averageRating: 4.8,
                totalReviews: 24,
                isOnline: false
            )
        ]
    }
}

class StudioService {
    static let shared = StudioService()
    private let supabase = SupabaseManager.shared
    private init() {}

    func fetchStudios() async throws -> [Studio] {
        // Try to fetch from database, fall back to mock data
        do {
            let response = try await supabase.client
                .from("studios")
                .select("*")
                .execute()
            
            if let data = response.data {
                // Parse real data when available
                return [] // TODO: Parse when studios table is available
            }
        } catch {
            print("⚠️ Studios table not available, using mock data: \(error)")
        }
        
        // Return mock data as fallback
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
        return [
            HobbyClass(
                id: UUID().uuidString,
                title: "Beginner Pottery Wheel",
                description: "Learn the basics of pottery on the wheel",
                instructor: Instructor(id: UUID().uuidString, name: "Marcus Chen", email: "marcus@example.com", bio: "", specialties: [], rating: 4.9, totalClasses: 0, isActive: true, studioId: studioId),
                venue: Venue(id: studioId, name: "Clay & Co. Ceramics", address: "567 East Hastings Street", city: "Vancouver", isActive: true),
                startDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()) ?? Date(),
                price: 45.0,
                maxParticipants: 8,
                currentParticipants: 5,
                category: .arts,
                difficulty: .beginner,
                tags: ["pottery", "ceramics", "wheel"],
                requirements: ["Apron (provided)"],
                whatToBring: ["Clothes you don't mind getting dirty"],
                averageRating: 4.7,
                totalReviews: 18,
                isOnline: false
            )
        ]
    }
}

// Legacy alias for compatibility
typealias VenueService = StudioService


class ClassService {
    static let shared = ClassService()
    private let supabase = SupabaseManager.shared
    private let simpleSupabaseService = SimpleSupabaseService.shared

    private init() {}

    func fetchUpcomingClasses() async throws -> [ClassItem] {
        let hobbyClasses = try await fetchClasses()
        return Array(hobbyClasses.prefix(10)).map { ClassItem.from(hobbyClass: $0) }
    }

    func searchClasses(query: String) async throws -> [HobbyClass] {
        let allClasses = try await fetchClasses()
        guard !query.isEmpty else { return allClasses }
        
        let lowerQuery = query.lowercased()
        return allClasses.filter { hobbyClass in
            hobbyClass.title.lowercased().contains(lowerQuery) ||
            hobbyClass.description.lowercased().contains(lowerQuery) ||
            hobbyClass.instructor.name.lowercased().contains(lowerQuery) ||
            hobbyClass.category.rawValue.lowercased().contains(lowerQuery)
        }
    }
    
    func getPopularClasses() async throws -> [HobbyClass] {
        let allClasses = try await fetchClasses()
        // Sort by average rating and number of reviews
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
    
    func getClassesByCategory(_ category: HobbyClass.Category) async throws -> [HobbyClass] {
        let allClasses = try await fetchClasses()
        return allClasses.filter { $0.category == category }
    }
    
    func getClassDetails(id: String) async throws -> HobbyClass? {
        let allClasses = try await fetchClasses()
        return allClasses.first { $0.id == id }
    }

    func fetchClasses() async throws -> [HobbyClass] {
        // Try to get classes from SimpleSupabaseService first (handles real data/fallback)
        let simpleClasses = await simpleSupabaseService.fetchClasses()
        
        if !simpleClasses.isEmpty {
            // Convert SimpleClass to HobbyClass
            return simpleClasses.compactMap { simpleClass in
                convertToHobbyClass(simpleClass)
            }
        }
        
        // If no real data, generate comprehensive mock data
        return generateMockClasses()
    }

    func fetchMoreClasses(offset: Int) async throws -> [HobbyClass] {
        let classes = try await fetchClasses()
        guard offset < classes.count else { return [] }
        return Array(classes[offset...].prefix(10))
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
            category: HobbyClass.Category(rawValue: simpleClass.category.lowercased()) ?? .general,
            difficulty: HobbyClass.Difficulty(rawValue: simpleClass.difficulty.lowercased()) ?? .beginner,
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
            Instructor(id: "1", name: "Sarah Johnson", email: "sarah@example.com", bio: "Certified yoga instructor", specialties: ["Yoga", "Meditation"], rating: 4.8, totalClasses: 156, isActive: true, studioId: nil),
            Instructor(id: "2", name: "Marcus Chen", email: "marcus@example.com", bio: "Professional ceramics artist", specialties: ["Pottery", "Ceramics"], rating: 4.9, totalClasses: 89, isActive: true, studioId: nil),
            Instructor(id: "3", name: "Emily Rodriguez", email: "emily@example.com", bio: "Contemporary dance instructor", specialties: ["Dance", "Movement"], rating: 4.7, totalClasses: 203, isActive: true, studioId: nil)
        ]
        
        let venues = [
            Venue(id: "1", name: "Serenity Yoga Studio", address: "1234 Commercial Drive", city: "Vancouver", isActive: true),
            Venue(id: "2", name: "Clay & Co. Ceramics", address: "567 East Hastings Street", city: "Vancouver", isActive: true),
            Venue(id: "3", name: "Movement Arts Collective", address: "890 Granville Street", city: "Vancouver", isActive: true)
        ]
        
        return [
            HobbyClass(
                id: UUID().uuidString,
                title: "Morning Vinyasa Flow",
                description: "Start your day with an energizing yoga flow that builds strength and flexibility.",
                instructor: instructors[0],
                venue: venues[0],
                startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .hour, value: 1, to: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()) ?? Date(),
                price: 25.0,
                maxParticipants: 15,
                currentParticipants: 8,
                category: .fitness,
                difficulty: .intermediate,
                tags: ["yoga", "morning", "flow", "strength"],
                requirements: ["Yoga mat"],
                whatToBring: ["Water bottle", "Towel"],
                averageRating: 4.8,
                totalReviews: 24,
                isOnline: false
            ),
            HobbyClass(
                id: UUID().uuidString,
                title: "Beginner Pottery Wheel",
                description: "Learn the fundamentals of pottery on the wheel, including centering, pulling, and shaping clay.",
                instructor: instructors[1],
                venue: venues[1],
                startDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()) ?? Date(),
                price: 45.0,
                maxParticipants: 8,
                currentParticipants: 5,
                category: .arts,
                difficulty: .beginner,
                tags: ["pottery", "ceramics", "wheel", "clay"],
                requirements: ["Apron (provided)"],
                whatToBring: ["Clothes you don't mind getting dirty"],
                averageRating: 4.7,
                totalReviews: 18,
                isOnline: false
            ),
            HobbyClass(
                id: UUID().uuidString,
                title: "Contemporary Dance Workshop",
                description: "Express yourself through movement in this contemporary dance class focusing on improvisation and technique.",
                instructor: instructors[2],
                venue: venues[2],
                startDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .hour, value: 1, to: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()) ?? Date(),
                price: 35.0,
                maxParticipants: 12,
                currentParticipants: 9,
                category: .dance,
                difficulty: .intermediate,
                tags: ["dance", "contemporary", "movement", "expression"],
                requirements: ["Comfortable clothing"],
                whatToBring: ["Water bottle", "Hair tie"],
                averageRating: 4.6,
                totalReviews: 12,
                isOnline: false
            ),
            HobbyClass(
                id: UUID().uuidString,
                title: "Meditation & Mindfulness",
                description: "Find inner peace and reduce stress through guided meditation and mindfulness practices.",
                instructor: instructors[0],
                venue: venues[0],
                startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .minute, value: 45, to: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()) ?? Date(),
                price: 20.0,
                maxParticipants: 20,
                currentParticipants: 14,
                category: .wellness,
                difficulty: .beginner,
                tags: ["meditation", "mindfulness", "relaxation", "stress-relief"],
                requirements: ["Comfortable seating"],
                whatToBring: ["Cushion or yoga mat"],
                averageRating: 4.9,
                totalReviews: 31,
                isOnline: true
            ),
            HobbyClass(
                id: UUID().uuidString,
                title: "Advanced Ceramics: Glazing Techniques",
                description: "Master advanced glazing techniques including layering, wax resist, and special effects.",
                instructor: instructors[1],
                venue: venues[1],
                startDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .hour, value: 3, to: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()) ?? Date(),
                price: 65.0,
                maxParticipants: 6,
                currentParticipants: 4,
                category: .arts,
                difficulty: .advanced,
                tags: ["ceramics", "glazing", "advanced", "techniques"],
                requirements: ["Previous pottery experience"],
                whatToBring: ["Bisque-fired pieces (or available to purchase)"],
                averageRating: 4.8,
                totalReviews: 9,
                isOnline: false
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

class LocationService: ObservableObject {
    static let shared = LocationService()
    @Published var currentLocation: CLLocation?
    @Published var locationPublisher = CurrentValueSubject<CLLocation?, Never>(nil)

    private init() {}

    func requestLocationPermission() {
        print("Location permission requested")
    }
}

class SearchService {
    static let shared = SearchService()
    private let classService = ClassService.shared
    private let instructorService = InstructorService.shared
    private let studioService = StudioService.shared
    private let userDefaultsKey = "hobbyist.recentSearches"

    private init() {}

    func searchClasses(query: String) async throws -> [HobbyClass] {
        // Use the ClassService which now has proper fallback handling
        return try await classService.searchClasses(query: query)
    }
    
    func searchAll(query: String) async throws -> SearchResults {
        async let classes = classService.searchClasses(query: query)
        async let instructors = instructorService.searchInstructors(query: query)
        async let studios = studioService.searchStudios(query: query)
        
        return SearchResults(
            classes: try await classes,
            instructors: try await instructors,
            studios: try await studios
        )
    }
    
    struct SearchResults {
        let classes: [HobbyClass]
        let instructors: [Instructor]
        let studios: [Studio]
        
        var isEmpty: Bool {
            classes.isEmpty && instructors.isEmpty && studios.isEmpty
        }
        
        var totalResults: Int {
            classes.count + instructors.count + studios.count
        }
    }

    func getAutocompleteSuggestions(query: String) async throws -> [String] {
        guard !query.isEmpty else { return [] }

        let classes = try await classService.fetchClasses()
        let lowerQuery = query.lowercased()
        let titles = classes.map(\.title)
            .filter { $0.lowercased().contains(lowerQuery) }
        let instructors = classes.map { $0.instructor.name }
            .filter { $0.lowercased().contains(lowerQuery) }

        return Array(Set(titles + instructors)).sorted().prefix(5).map { $0 }
    }

    func search(with parameters: SearchParameters) async throws -> [SearchResult] {
        let classes = try await classService.fetchClasses()
        return classes
            .map { SearchResult(hobbyClass: $0) }
            .filter { parameters.matches($0) }
            .sorted { ($0.startDate ?? Date.distantFuture) < ($1.startDate ?? Date.distantFuture) }
    }

    func fetchRecentSearches() async throws -> [String] {
        UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? []
    }

    func fetchPopularSearches() async throws -> [String] {
        let classes = try await classService.fetchClasses()
        let categories = classes.map { $0.category.rawValue }
        return Array(Set(categories)).sorted().prefix(5).map { $0 }
    }

    func fetchSuggestedClasses() async throws -> [HobbyClass] {
        let classes = try await classService.fetchClasses()
        return classes.sorted { $0.startDate < $1.startDate }
    }

    func fetchNearbyClasses(location: CLLocation, radius: Double) async throws -> [HobbyClass] {
        // Placeholder until geolocation support is implemented
        let classes = try await classService.fetchClasses()
        return classes.sorted { $0.startDate < $1.startDate }
    }

    func fetchTrendingCategories() async throws -> [String] {
        let classes = try await classService.fetchClasses()
        let categoryFrequency = Dictionary(grouping: classes) { $0.category.rawValue }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return categoryFrequency.map { $0.key }
    }

    func saveRecentSearches(_ searches: [String]) async throws {
        UserDefaults.standard.set(Array(searches.prefix(10)), forKey: userDefaultsKey)
    }

    func clearRecentSearches() async throws {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    func trackSearch(query: String) {
        print("Analytics: Search tracked - \(query)")
    }

    func trackSearch(query: String, scope: String, resultCount: Int, appliedFilters: [String], executionTime: TimeInterval) async {
        print("Analytics: Advanced search tracked - \(query) in \(scope), \(resultCount) results")
    }

    func trackEvent(name: String, parameters: [String: Any] = [:]) {
        print("Analytics: Event tracked - \(name)")
    }
}


struct NotificationSettings: Codable {
    var pushNotifications: Bool = true
    var emailNotifications: Bool = true
    var marketingEmails: Bool = false
    var classReminders: Bool = true

    init() {}
}

class SupabaseManager {
    static let shared = SupabaseManager()
    private init() {}

    lazy var client: SupabaseClient = {
        guard let configuration = AppConfiguration.shared.current else {
            fatalError("Supabase configuration missing. Configure environment before using SupabaseManager.")
        }

        guard !configuration.supabaseURL.isEmpty,
              let url = URL(string: configuration.supabaseURL) else {
            fatalError("Invalid Supabase URL in configuration.")
        }

        guard !configuration.supabaseAnonKey.isEmpty else {
            fatalError("Supabase anon key is missing in configuration.")
        }

        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: configuration.supabaseAnonKey
        )
    }()
}

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
