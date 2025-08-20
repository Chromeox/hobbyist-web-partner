import Foundation
import Combine
import CoreLocation
import UIKit

// MARK: - BookingService
class BookingService {
    static let shared = BookingService()
    
    @Published private(set) var bookings: [Booking] = []
    var bookingsPublisher: AnyPublisher<[Booking], Never> {
        $bookings.eraseToAnyPublisher()
    }
    
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    func createBooking(_ request: BookingRequest) async throws -> Booking {
        let jsonData = try JSONEncoder().encode(request)
        let booking: Booking = try await supabaseService.request("bookings", method: .post, body: jsonData)
        bookings.append(booking)
        return booking
    }
    
    func fetchUserBookings(userId: String) async throws -> [Booking] {
        let endpoint = "bookings?user_id=eq.\(userId)&order=created_at.desc"
        let fetchedBookings: [Booking] = try await supabaseService.request(endpoint)
        bookings = fetchedBookings
        return fetchedBookings
    }
    
    func cancelBooking(bookingId: String) async throws {
        let endpoint = "bookings?id=eq.\(bookingId)"
        let update = ["status": "cancelled"]
        let jsonData = try JSONSerialization.data(withJSONObject: update)
        try await supabaseService.requestVoid(endpoint, method: .patch, body: jsonData)
        
        if let index = bookings.firstIndex(where: { $0.id == bookingId }) {
            bookings[index] = Booking(
                id: bookings[index].id,
                classId: bookings[index].classId,
                className: bookings[index].className,
                userId: bookings[index].userId,
                participantCount: bookings[index].participantCount,
                specialRequests: bookings[index].specialRequests,
                paymentId: bookings[index].paymentId,
                totalAmount: bookings[index].totalAmount,
                status: .cancelled,
                createdAt: bookings[index].createdAt,
                classStartDate: bookings[index].classStartDate,
                classEndDate: bookings[index].classEndDate,
                venue: bookings[index].venue,
                instructor: bookings[index].instructor
            )
        }
    }
    
    func sendConfirmationEmail(for booking: Booking) async throws {
        // This would typically call an edge function or email service
        print("Sending confirmation email for booking: \(booking.id)")
    }
}

// MARK: - ClassService
class ClassService {
    static let shared = ClassService()
    
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    func fetchClasses() async throws -> [HobbyClass] {
        let endpoint = "classes?select=*,instructors(*),venues(*)&order=start_date.asc"
        return try await supabaseService.request(endpoint)
    }
    
    func fetchMoreClasses(offset: Int, limit: Int = 20) async throws -> [HobbyClass] {
        let endpoint = "classes?select=*,instructors(*),venues(*)&order=start_date.asc&offset=\(offset)&limit=\(limit)"
        return try await supabaseService.request(endpoint)
    }
    
    func fetchClass(id: String) async throws -> HobbyClass {
        let endpoint = "classes?id=eq.\(id)&select=*,instructors(*),venues(*)"
        let classes: [HobbyClass] = try await supabaseService.request(endpoint)
        guard let hobbyClass = classes.first else {
            throw ClassServiceError.classNotFound
        }
        return hobbyClass
    }
}

enum ClassServiceError: Error {
    case classNotFound
}

// MARK: - PaymentService
class PaymentService {
    static let shared = PaymentService()
    
    struct PaymentResult {
        let paymentId: String
        let status: String
    }
    
    private init() {}
    
    func processPayment(amount: Double, method: PaymentMethod, userId: String) async throws -> PaymentResult {
        // In production, this would integrate with Stripe or Apple Pay
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate processing
        
        return PaymentResult(
            paymentId: UUID().uuidString,
            status: "succeeded"
        )
    }
    
    func processRefund(paymentId: String, amount: Double) async throws {
        // In production, this would process actual refund
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func validateCoupon(code: String) async throws -> Coupon {
        // In production, validate against database
        throw PaymentServiceError.invalidCoupon
    }
}

enum PaymentServiceError: Error {
    case invalidCoupon
    case paymentFailed
}

// MARK: - FavoritesService
class FavoritesService {
    static let shared = FavoritesService()
    
    @Published private(set) var favoriteClassIds: Set<String> = []
    var favoritesPublisher: AnyPublisher<Set<String>, Never> {
        $favoriteClassIds.eraseToAnyPublisher()
    }
    
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    func toggleFavorite(classId: String) async throws {
        if favoriteClassIds.contains(classId) {
            favoriteClassIds.remove(classId)
            // Remove from database
            let endpoint = "favorites?class_id=eq.\(classId)"
            try await supabaseService.requestVoid(endpoint, method: .delete)
        } else {
            favoriteClassIds.insert(classId)
            // Add to database
            let favorite = ["class_id": classId, "user_id": AuthenticationService.shared.currentUser?.id ?? ""]
            let jsonData = try JSONSerialization.data(withJSONObject: favorite)
            try await supabaseService.requestVoid("favorites", method: .post, body: jsonData)
        }
    }
    
    func fetchFavoriteClasses(userId: String) async throws -> [HobbyClass] {
        let endpoint = "favorites?user_id=eq.\(userId)&select=classes(*,instructors(*),venues(*))"
        return try await supabaseService.request(endpoint)
    }
}

// MARK: - SearchService
class SearchService {
    static let shared = SearchService()
    
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    func search(with parameters: SearchParameters) async throws -> [SearchResult] {
        // In production, this would perform actual search
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
    
    func fetchAutocompleteSuggestions(for query: String) async throws -> [String] {
        // In production, fetch from database
        return ["Yoga", "Yoga for beginners", "Yoga with meditation"]
    }
    
    func fetchRecentSearches() async throws -> [String] {
        // Load from UserDefaults or database
        return UserDefaults.standard.stringArray(forKey: "recent_searches") ?? []
    }
    
    func saveRecentSearches(_ searches: [String]) async throws {
        UserDefaults.standard.set(searches, forKey: "recent_searches")
    }
    
    func clearRecentSearches() async throws {
        UserDefaults.standard.removeObject(forKey: "recent_searches")
    }
    
    func fetchPopularSearches() async throws -> [String] {
        return ["Yoga", "Cooking", "Photography", "Painting", "Dance"]
    }
    
    func fetchSuggestedClasses() async throws -> [HobbyClass] {
        return try await ClassService.shared.fetchClasses()
    }
    
    func fetchNearbyClasses(location: CLLocation, radius: Double) async throws -> [HobbyClass] {
        // In production, filter by location
        return try await ClassService.shared.fetchClasses()
    }
    
    func fetchTrendingCategories() async throws -> [TrendingCategory] {
        return []
    }
}

// MARK: - ProfileService
class ProfileService {
    static let shared = ProfileService()
    
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    func fetchProfile(userId: String) async throws -> User {
        let endpoint = "profiles?id=eq.\(userId)"
        let profiles: [User] = try await supabaseService.request(endpoint)
        guard let profile = profiles.first else {
            throw ProfileServiceError.profileNotFound
        }
        return profile
    }
    
    func updateProfile(userId: String, updates: ProfileUpdate) async throws -> User {
        let jsonData = try JSONEncoder().encode(updates)
        let endpoint = "profiles?id=eq.\(userId)"
        try await supabaseService.requestVoid(endpoint, method: .patch, body: jsonData)
        return try await fetchProfile(userId: userId)
    }
    
    func fetchUserStatistics(userId: String) async throws -> UserStatistics {
        // In production, aggregate from database
        return UserStatistics(
            totalBookings: 0,
            totalSpent: 0,
            classesAttended: 0,
            favoriteCategory: nil,
            memberSince: Date(),
            lastActiveDate: Date(),
            upcomingClasses: 0,
            completedClasses: 0,
            cancelledClasses: 0,
            averageRating: nil,
            totalReviews: 0
        )
    }
    
    func fetchUserPreferences(userId: String) async throws -> UserPreferences {
        return UserPreferences()
    }
    
    func updatePreferences(userId: String, preferences: UserPreferences) async throws -> UserPreferences {
        return preferences
    }
    
    func fetchAchievements(userId: String) async throws -> [Achievement] {
        return []
    }
    
    func fetchNotificationSettings(userId: String) async throws -> NotificationSettings {
        return NotificationSettings()
    }
    
    func updateNotificationSettings(userId: String, settings: NotificationSettings) async throws -> NotificationSettings {
        return settings
    }
    
    func deleteAccount(userId: String) async throws {
        let endpoint = "profiles?id=eq.\(userId)"
        try await supabaseService.requestVoid(endpoint, method: .delete)
    }
    
    func exportUserData(userId: String) async throws -> URL {
        // In production, generate data export
        throw ProfileServiceError.exportFailed
    }
}

enum ProfileServiceError: Error {
    case profileNotFound
    case exportFailed
}

// MARK: - LocationService
class LocationService: NSObject {
    static let shared = LocationService()
    
    @Published private(set) var currentLocation: CLLocation?
    var locationPublisher: AnyPublisher<CLLocation?, Never> {
        $currentLocation.eraseToAnyPublisher()
    }
    
    private let locationManager = CLLocationManager()
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() async {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
}

// MARK: - StorageService
class StorageService {
    static let shared = StorageService()
    
    private init() {}
    
    func uploadProfileImage(image: UIImage, userId: String) async throws -> String {
        // In production, upload to Supabase Storage or S3
        return "https://example.com/profile/\(userId).jpg"
    }
}

// MARK: - AnalyticsService
class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    func trackSearch(query: String, scope: String, resultCount: Int, locationFilter: String) async {
        // Track analytics event
        print("Search tracked: \(query), scope: \(scope), results: \(resultCount)")
    }
    
    func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        // Track generic event
        print("Event tracked: \(event)")
    }
}