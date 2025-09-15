import Foundation
import Supabase
import Combine

// MARK: - Supabase Data Service
@MainActor
class SupabaseDataService: ObservableObject {
    static let shared = SupabaseDataService()
    
    private let client: SupabaseClient
    private var cancellables = Set<AnyCancellable>()
    
    // Real-time subscriptions
    private var classesSubscription: RealtimeChannel?
    private var bookingsSubscription: RealtimeChannel?
    
    // Published data
    @Published var classes: [ClassItem] = []
    @Published var userBookings: [Booking] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    init() {
        // Initialize Supabase client
        self.client = SupabaseManager.shared.client
        setupRealTimeSubscriptions()
    }
    
    // MARK: - Real-time Subscriptions
    
    private func setupRealTimeSubscriptions() {
        Task {
            await subscribeToClasses()
            await subscribeToBookings()
        }
    }
    
    private func subscribeToClasses() async {
        classesSubscription = client.channel("public:classes")
            .on(.all) { [weak self] message in
                Task { @MainActor in
                    await self?.handleClassUpdate(message)
                }
            }
            .subscribe()
    }
    
    private func subscribeToBookings() async {
        guard let userId = try? await client.auth.session.user.id else { return }
        
        bookingsSubscription = client.channel("public:bookings")
            .on(.all, filter: "user_id=eq.\(userId)") { [weak self] message in
                Task { @MainActor in
                    await self?.handleBookingUpdate(message)
                }
            }
            .subscribe()
    }
    
    private func handleClassUpdate(_ message: RealtimeMessage) async {
        // Refresh classes when changes occur
        await fetchClasses()
    }
    
    private func handleBookingUpdate(_ message: RealtimeMessage) async {
        // Refresh bookings when changes occur
        await fetchUserBookings()
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
            var query = client.database
                .from("classes")
                .select("""
                    *,
                    instructor:instructors(*),
                    venue:venues(*)
                """)
                .gte("start_time", Date().ISO8601Format())
                .order("start_time", ascending: true)
                .limit(limit)
                .offset(offset)
            
            // Apply filters
            if let category = category {
                query = query.eq("category", value: category)
            }
            
            if let searchQuery = searchQuery {
                query = query.ilike("name", pattern: "%\(searchQuery)%")
            }
            
            let response = try await query.execute()
            let classData = try response.decoded(to: [SupabaseClass].self)
            
            // Convert to ClassItem
            self.classes = classData.map { $0.toClassItem() }
            
        } catch {
            self.error = error
            print("Failed to fetch classes: \(error)")
        }
        
        isLoading = false
    }
    
    func fetchClassById(_ id: String) async -> ClassItem? {
        do {
            let response = try await client.database
                .from("classes")
                .select("""
                    *,
                    instructor:instructors(*),
                    venue:venues(*),
                    reviews(*)
                """)
                .eq("id", value: id)
                .single()
                .execute()
            
            let classData = try response.decoded(to: SupabaseClass.self)
            return classData.toClassItem()
            
        } catch {
            print("Failed to fetch class: \(error)")
            return nil
        }
    }
    
    func fetchFeaturedClasses() async -> [ClassItem] {
        do {
            let response = try await client.database
                .from("classes")
                .select("""
                    *,
                    instructor:instructors(*),
                    venue:venues(*)
                """)
                .eq("is_featured", value: true)
                .gte("start_time", Date().ISO8601Format())
                .limit(5)
                .execute()
            
            let classData = try response.decoded(to: [SupabaseClass].self)
            return classData.map { $0.toClassItem() }
            
        } catch {
            print("Failed to fetch featured classes: \(error)")
            return []
        }
    }
    
    func fetchNearbyClasses(latitude: Double, longitude: Double, radiusMiles: Int = 5) async -> [ClassItem] {
        do {
            // Use PostGIS for location-based queries
            let response = try await client.database
                .rpc("get_nearby_classes", params: [
                    "lat": latitude,
                    "lng": longitude,
                    "radius_miles": radiusMiles
                ])
                .execute()
            
            let classData = try response.decoded(to: [SupabaseClass].self)
            return classData.map { $0.toClassItem() }
            
        } catch {
            print("Failed to fetch nearby classes: \(error)")
            return []
        }
    }
    
    // MARK: - Bookings
    
    func fetchUserBookings() async {
        guard let userId = try? await client.auth.session.user.id else { return }
        
        do {
            let response = try await client.database
                .from("bookings")
                .select("""
                    *,
                    class:classes(*,
                        instructor:instructors(*),
                        venue:venues(*)
                    )
                """)
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
            
            let bookingData = try response.decoded(to: [SupabaseBooking].self)
            self.userBookings = bookingData.map { $0.toBooking() }
            
        } catch {
            print("Failed to fetch bookings: \(error)")
        }
    }
    
    func createBooking(
        classId: String,
        participantCount: Int,
        totalAmount: Double,
        paymentIntentId: String,
        specialRequests: String? = nil
    ) async throws -> String {
        guard let userId = try? await client.auth.session.user.id else {
            throw SupabaseError.authRequired
        }
        
        let booking = [
            "id": UUID().uuidString,
            "user_id": userId.uuidString,
            "class_id": classId,
            "participant_count": participantCount,
            "total_amount": totalAmount,
            "payment_intent_id": paymentIntentId,
            "special_requests": specialRequests ?? "",
            "status": "confirmed",
            "created_at": Date().ISO8601Format()
        ] as [String : Any]
        
        let response = try await client.database
            .from("bookings")
            .insert(booking)
            .select()
            .single()
            .execute()
        
        let createdBooking = try response.decoded(to: SupabaseBooking.self)
        
        // Send booking confirmation notification
        await sendBookingConfirmationNotification(bookingId: createdBooking.id)
        
        return createdBooking.id
    }
    
    func cancelBooking(_ bookingId: String) async throws {
        _ = try await client.database
            .from("bookings")
            .update(["status": "cancelled", "cancelled_at": Date().ISO8601Format()])
            .eq("id", value: bookingId)
            .execute()
    }
    
    // MARK: - Reviews
    
    func fetchReviews(for classId: String) async -> [Review] {
        do {
            let response = try await client.database
                .from("reviews")
                .select("""
                    *,
                    user:users(name, avatar_url)
                """)
                .eq("class_id", value: classId)
                .order("created_at", ascending: false)
                .execute()
            
            let reviewData = try response.decoded(to: [SupabaseReview].self)
            return reviewData.map { $0.toReview() }
            
        } catch {
            print("Failed to fetch reviews: \(error)")
            return []
        }
    }
    
    func createReview(
        classId: String,
        rating: Int,
        comment: String
    ) async throws {
        guard let userId = try? await client.auth.session.user.id else {
            throw SupabaseError.authRequired
        }
        
        let review = [
            "id": UUID().uuidString,
            "user_id": userId.uuidString,
            "class_id": classId,
            "rating": rating,
            "comment": comment,
            "created_at": Date().ISO8601Format()
        ] as [String : Any]
        
        _ = try await client.database
            .from("reviews")
            .insert(review)
            .execute()
    }
    
    // MARK: - Favorites
    
    func toggleFavorite(classId: String) async throws {
        guard let userId = try? await client.auth.session.user.id else {
            throw SupabaseError.authRequired
        }
        
        // Check if favorite exists
        let existingResponse = try await client.database
            .from("favorites")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("class_id", value: classId)
            .execute()
        
        if let data = existingResponse.data, !data.isEmpty {
            // Remove favorite
            _ = try await client.database
                .from("favorites")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("class_id", value: classId)
                .execute()
        } else {
            // Add favorite
            let favorite = [
                "id": UUID().uuidString,
                "user_id": userId.uuidString,
                "class_id": classId,
                "created_at": Date().ISO8601Format()
            ]
            
            _ = try await client.database
                .from("favorites")
                .insert(favorite)
                .execute()
        }
    }
    
    // MARK: - User Profile
    
    func updateUserProfile(
        name: String? = nil,
        bio: String? = nil,
        preferences: [String]? = nil
    ) async throws {
        guard let userId = try? await client.auth.session.user.id else {
            throw SupabaseError.authRequired
        }
        
        var updates: [String: Any] = [:]
        
        if let name = name {
            updates["full_name"] = name
        }
        if let bio = bio {
            updates["bio"] = bio
        }
        if let preferences = preferences {
            updates["preferences"] = preferences
        }
        
        updates["updated_at"] = Date().ISO8601Format()
        
        _ = try await client.database
            .from("profiles")
            .update(updates)
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    // MARK: - Push Notifications
    
    private func sendBookingConfirmationNotification(bookingId: String) async {
        // This would typically call your Edge Function
        do {
            _ = try await client.functions.invoke(
                "send-notification",
                options: FunctionInvokeOptions(
                    body: [
                        "type": "booking_confirmation",
                        "booking_id": bookingId
                    ]
                )
            )
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
    
    func scheduleClassReminder(classId: String, reminderTime: Date) async throws {
        guard let userId = try? await client.auth.session.user.id else {
            throw SupabaseError.authRequired
        }
        
        let reminder = [
            "id": UUID().uuidString,
            "user_id": userId.uuidString,
            "class_id": classId,
            "reminder_time": reminderTime.ISO8601Format(),
            "status": "scheduled"
        ]
        
        _ = try await client.database
            .from("reminders")
            .insert(reminder)
            .execute()
    }
}

// MARK: - Supabase Models

struct SupabaseClass: Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let instructor_id: String
    let venue_id: String
    let start_time: String
    let end_time: String
    let duration_minutes: Int
    let price: Double
    let max_participants: Int
    let current_participants: Int
    let difficulty_level: String
    let is_featured: Bool
    let image_url: String?
    let instructor: SupabaseInstructor?
    let venue: SupabaseVenue?
    
    func toClassItem() -> ClassItem {
        let startDate = ISO8601DateFormatter().date(from: start_time) ?? Date()
        let endDate = ISO8601DateFormatter().date(from: end_time) ?? Date()
        
        return ClassItem(
            id: id,
            name: name,
            category: category,
            instructor: instructor?.name ?? "Unknown",
            instructorInitials: String(instructor?.name.prefix(2) ?? "??"),
            description: description,
            duration: "\(duration_minutes) min",
            difficulty: difficulty_level,
            price: "$\(Int(price))",
            startTime: startDate,
            endTime: endDate,
            location: venue?.address ?? "",
            venueName: venue?.name ?? "",
            address: venue?.address ?? "",
            coordinate: CLLocationCoordinate2D(
                latitude: venue?.latitude ?? 0,
                longitude: venue?.longitude ?? 0
            ),
            spotsAvailable: max_participants - current_participants,
            totalSpots: max_participants,
            rating: "4.8", // Would come from aggregated reviews
            reviewCount: "42", // Would come from review count
            icon: categoryIcon(for: category),
            categoryColor: categoryColor(for: category),
            isFeatured: is_featured,
            requirements: ["Water bottle", "Comfortable clothing"],
            amenities: venue?.amenities.map { Amenity(name: $0, icon: "checkmark") } ?? [],
            equipment: []
        )
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "yoga": return "figure.yoga"
        case "pilates": return "figure.pilates"
        case "cycling": return "figure.outdoor.cycle"
        case "dance": return "figure.dance"
        case "boxing": return "figure.boxing"
        default: return "figure.run"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "yoga": return .purple
        case "pilates": return .blue
        case "cycling": return .green
        case "dance": return .pink
        case "boxing": return .red
        default: return .orange
        }
    }
}

struct SupabaseInstructor: Codable {
    let id: String
    let name: String
    let bio: String?
    let rating: Double
    let specialties: [String]
}

struct SupabaseVenue: Codable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let amenities: [String]
}

struct SupabaseBooking: Codable {
    let id: String
    let user_id: String
    let class_id: String
    let participant_count: Int
    let total_amount: Double
    let payment_intent_id: String
    let special_requests: String?
    let status: String
    let created_at: String
    
    func toBooking() -> Booking {
        // Convert to app Booking model
        Booking(
            id: id,
            userId: user_id,
            classId: class_id,
            participantCount: participant_count,
            totalAmount: total_amount,
            status: BookingStatus(rawValue: status) ?? .pending,
            createdAt: ISO8601DateFormatter().date(from: created_at) ?? Date()
        )
    }
}

struct SupabaseReview: Codable {
    let id: String
    let user_id: String
    let class_id: String
    let rating: Int
    let comment: String
    let created_at: String
    let user: SupabaseUser?
    
    func toReview() -> Review {
        Review(
            id: id,
            userName: user?.name ?? "Anonymous",
            userInitials: String(user?.name.prefix(2) ?? "??"),
            rating: rating,
            comment: comment,
            date: ISO8601DateFormatter().date(from: created_at) ?? Date()
        )
    }
}

struct SupabaseUser: Codable {
    let id: String
    let name: String
    let avatar_url: String?
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case authRequired
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .authRequired:
            return "Authentication required"
        case .networkError:
            return "Network error occurred"
        case .decodingError:
            return "Failed to decode data"
        }
    }
}