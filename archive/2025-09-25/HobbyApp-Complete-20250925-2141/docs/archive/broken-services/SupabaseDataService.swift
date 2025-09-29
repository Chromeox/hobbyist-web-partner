import Foundation
import Supabase
import Combine
import SwiftUI
import CoreLocation

// MARK: - Supabase Data Service
@MainActor
class SupabaseDataService: ObservableObject {
    static let shared = SupabaseDataService()

    private var client: SupabaseClient? {
        return SupabaseManager.shared.client
    }

    // Published properties for UI binding
    @Published var classes: [ClassItem] = []
    @Published var bookings: [Booking] = []
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var error: Error?

    init() {
        setupRealtimeSubscriptions()
    }

    // MARK: - Realtime Subscriptions

    private func setupRealtimeSubscriptions() {
        // Simplified realtime setup - basic connection only
        print("Realtime subscriptions initialized")
    }

    private func setupClassesSubscription() {
        // Placeholder for realtime classes subscription
        print("Classes subscription setup")
    }

    private func setupBookingsSubscription() {
        // Placeholder for realtime bookings subscription
        print("Bookings subscription setup")
    }

    // MARK: - Classes

    func fetchClasses(
        category: String? = nil,
        searchQuery: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async {
        isLoading = true
        error = nil

        do {
            guard let client = client else {
                throw SupabaseDataError.networkError
            }

            // Use modern Supabase v2.32.0 API
            let response: [SupabaseClass] = try await client
                .from("classes")
                .select()
                .execute()
                .value

            // Convert to ClassItem for UI
            await MainActor.run {
                self.classes = response.map { $0.toClassItem() }
                self.isLoading = false
            }

        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
                // Fallback to mock data
                self.classes = ClassItem.hobbyClassSamples
            }
            print("Failed to fetch classes: \(error)")
        }
    }

    func searchClasses(query: String) async {
        await fetchClasses(searchQuery: query)
    }

    func fetchClassesByCategory(_ category: String) async {
        await fetchClasses(category: category)
    }

    func fetchFeaturedClasses() async {
        await fetchClasses()
    }

    // MARK: - Bookings

    func fetchUserBookings(userId: String) async {
        isLoading = true
        error = nil

        do {
            guard let client = client else {
                throw SupabaseDataError.networkError
            }

            // Use modern Supabase v2.32.0 API
            let response: [SupabaseBooking] = try await client
                .from("bookings")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            // Convert to Booking for UI
            await MainActor.run {
                self.bookings = response.compactMap { mapToBooking(from: $0) }
                self.isLoading = false
            }

        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
                self.bookings = []
            }
            print("Failed to fetch bookings: \(error)")
        }
    }

    func createBooking(_ booking: CreateBookingRequest) async throws {
        guard let client = client else {
            throw SupabaseDataError.networkError
        }

        try await client
            .from("bookings")
            .insert(booking)
            .execute()

        print("Booking created successfully")
    }

    func updateBooking(_ bookingId: String, data: UpdateBookingRequest) async throws {
        guard let client = client else {
            throw SupabaseDataError.networkError
        }

        try await client
            .from("bookings")
            .update(data)
            .eq("id", value: bookingId)
            .execute()

        print("Booking updated successfully: \(bookingId)")
    }

    // MARK: - Reviews

    func fetchReviews(for targetId: String, targetType: String) async {
        isLoading = true
        error = nil

        do {
            guard let client = client else {
                throw SupabaseDataError.networkError
            }

            // Use modern Supabase v2.32.0 API
            let response: [SupabaseDataReview] = try await client
                .from("reviews")
                .select()
                .eq("target_id", value: targetId)
                .eq("target_type", value: targetType)
                .execute()
                .value

            // Convert to Review for UI
            await MainActor.run {
                self.reviews = response.compactMap { mapToReview(from: $0) }
                self.isLoading = false
            }

        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
                self.reviews = []
            }
            print("Failed to fetch reviews: \(error)")
        }
    }

    func submitReview(_ review: CreateReviewRequest) async throws {
        guard let client = client else {
            throw SupabaseDataError.networkError
        }

        try await client
            .from("reviews")
            .insert(review)
            .execute()

        print("Review submitted successfully")
    }

    // MARK: - Analytics

    func trackEvent(_ eventName: String, parameters: [String: Any]) async {
        // Simplified analytics tracking
        print("Analytics: \(eventName) - \(parameters)")
    }

    func updateUserPreferences(_ userId: String, preferences: UserPreferencesRequest) async throws {
        guard let client = client else {
            throw SupabaseDataError.networkError
        }

        try await client
            .from("user_preferences")
            .upsert(preferences)
            .eq("user_id", value: userId)
            .execute()

        print("User preferences updated: \(userId)")
    }

    // MARK: - Data Mapping

    private func mapToBooking(from supabaseBooking: SupabaseBooking) -> Booking? {
        // Convert SupabaseBooking to UI Booking model
        // Implementation would depend on your Booking model structure
        return nil // Placeholder for now
    }

    private func mapToReview(from supabaseReview: SupabaseDataReview) -> Review? {
        // Convert SupabaseDataReview to UI Review model
        // Implementation would depend on your Review model structure
        return nil // Placeholder for now
    }
}

// MARK: - Simplified Supabase Models

struct SupabaseClass: Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let startTime: Date
    let endTime: Date
    let price: Double
    let maxCapacity: Int
    let currentEnrollment: Int
    let instructorId: String
    let venueId: String
    let imageUrl: String?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date?

    func toClassItem() -> ClassItem {
        return ClassItem(
            id: id,
            name: name,
            category: category,
            instructor: "Instructor",
            instructorInitials: "IN",
            description: description,
            duration: "90 min",
            difficulty: "All Levels",
            price: "$\(Int(price))",
            creditsRequired: Int(price / 3.5),
            startTime: startTime,
            endTime: endTime,
            location: "Studio",
            venueName: "Venue",
            address: "123 Main St",
            coordinate: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
            spotsAvailable: maxCapacity - currentEnrollment,
            totalSpots: maxCapacity,
            rating: "4.8",
            reviewCount: "25",
            icon: "star",
            categoryColor: .blue,
            isFeatured: false,
            requirements: [],
            amenities: [],
            equipment: []
        )
    }
}

struct SupabaseBooking: Codable {
    let id: String
    let userId: String
    let classId: String
    let status: String
    let createdAt: Date
    let updatedAt: Date?
}

struct SupabaseDataReview: Codable {
    let id: String
    let userId: String
    let targetId: String
    let targetType: String
    let rating: Int
    let content: String
    let createdAt: Date
}

struct SupabaseDataUser: Codable {
    let id: String
    let email: String
    let fullName: String?
    let createdAt: Date
}

enum SupabaseDataError: LocalizedError {
    case authRequired
    case networkError
    case invalidData

    var errorDescription: String? {
        switch self {
        case .authRequired:
            return "Authentication required"
        case .networkError:
            return "Network error occurred"
        case .invalidData:
            return "Invalid data received"
        }
    }
}

// MARK: - Mock Data Response

// MARK: - Request/Response Types for Supabase v2.32.0 API

struct CreateBookingRequest: Codable {
    let userId: String
    let classId: String
    let status: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case classId = "class_id"
        case status
        case createdAt = "created_at"
    }
}

struct UpdateBookingRequest: Codable {
    let status: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case status
        case updatedAt = "updated_at"
    }
}

struct CreateReviewRequest: Codable {
    let userId: String
    let targetId: String
    let targetType: String
    let rating: Int
    let content: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case targetId = "target_id"
        case targetType = "target_type"
        case rating
        case content
        case createdAt = "created_at"
    }
}

struct UserPreferencesRequest: Codable {
    let userId: String
    let notificationSettings: NotificationSettings?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case notificationSettings = "notification_settings"
        case updatedAt = "updated_at"
    }
}

struct UserPreferencesResponse: Codable {
    let userId: String
    let notificationSettings: NotificationSettings?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case notificationSettings = "notification_settings"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseResponse<T: Codable> {
    let data: T?
    let user: SupabaseDataUser?
}