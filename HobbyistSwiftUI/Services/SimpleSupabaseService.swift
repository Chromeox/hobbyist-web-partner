import Foundation
import Supabase

// Simplified Supabase service for working backend integration
@MainActor
final class SimpleSupabaseService: ObservableObject {
    static let shared = SimpleSupabaseService()

    private var supabaseClient: SupabaseClient!

    // Published properties for UI binding
    @Published var isAuthenticated = false
    @Published var currentUser: SimpleUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {
        setupSupabase()
    }

    private func setupSupabase() {
        // Use the current valid configuration (updated API key from Jan 2025)
        let supabaseURL = "https://mcjqvdzdhtcvbrejvrtp.supabase.co"
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1janF2ZHpkaHRjdmJyZWp2cnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5MDIzNzksImV4cCI6MjA2NDQ3ODM3OX0.puthoId8ElCgYzuyKJTTyzR9FeXmVA-Tkc8RV1rqdkc"

        guard let url = URL(string: supabaseURL) else {
            print("❌ Invalid Supabase URL")
            return
        }

        supabaseClient = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey
        )

        print("✅ Simple Supabase client initialized")

        // Check if user is already authenticated
        Task {
            await checkAuthenticationStatus()
        }
    }

    // MARK: - Authentication

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await supabaseClient.auth.signIn(
                email: email,
                password: password
            )

            let user = response.user
            currentUser = SimpleUser(
                id: user.id.uuidString,
                email: user.email ?? email,
                name: user.userMetadata["full_name"]?.value as? String ?? "User"
            )
            isAuthenticated = true
            print("✅ User signed in: \(email)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Sign in error: \(error)")
        }

        isLoading = false
    }

    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await supabaseClient.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullName)]
            )

            print("✅ User signed up: \(email)")
            // Note: User will need to verify email before signing in
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Sign up error: \(error)")
        }

        isLoading = false
    }

    func signOut() async {
        do {
            try await supabaseClient.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            print("✅ User signed out")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Sign out error: \(error)")
        }
    }

    private func checkAuthenticationStatus() async {
        do {
            let session = try await supabaseClient.auth.session
            let user = session.user
            currentUser = SimpleUser(
                id: user.id.uuidString,
                email: user.email ?? "",
                name: user.userMetadata["full_name"]?.value as? String ?? "User"
            )
            isAuthenticated = true
            print("✅ User already authenticated")
        } catch {
            print("❌ Auth check error: \(error)")
            // User not authenticated, continue with login flow
        }
    }

    // MARK: - Data Operations

    func fetchClasses() async -> [SimpleClass] {
        do {
            let response = try await supabaseClient
                .from("classes")
                .select("*")
                .execute()

            let classes = try response.value as! [[String: Any]]
            return classes.compactMap { SimpleClass(from: $0) }
        } catch {
            print("❌ Fetch classes error: \(error)")
            errorMessage = error.localizedDescription
            return []
        }
    }

    func fetchUserBookings() async -> [SimpleBooking] {
        guard let userId = currentUser?.id else { return [] }

        do {
            let response = try await supabaseClient
                .from("bookings")
                .select("*, classes(*)")
                .eq("user_id", value: userId)
                .execute()

            let bookings = try response.value as! [[String: Any]]
            return bookings.compactMap { SimpleBooking(from: $0) }
        } catch {
            print("❌ Fetch bookings error: \(error)")
            errorMessage = error.localizedDescription
            return []
        }
    }

    func createBooking(classId: String, date: Date) async -> Bool {
        guard let userId = currentUser?.id else { return false }

        isLoading = true

        do {
            let _ = try await supabaseClient
                .from("bookings")
                .insert([
                    "user_id": userId,
                    "class_id": classId,
                    "booking_date": ISO8601DateFormatter().string(from: date),
                    "status": "confirmed"
                ])
                .execute()

            print("✅ Booking created successfully")
            isLoading = false
            return true
        } catch {
            print("❌ Create booking error: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}

// MARK: - Simple Models

struct SimpleUser {
    let id: String
    let email: String
    let name: String
}

struct SimpleClass {
    let id: String
    let title: String
    let description: String
    let instructor: String
    let price: Double
    let duration: Int // minutes
    let category: String
    let imageURL: String?

    init?(from data: [String: Any]) {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let instructor = data["instructor"] as? String else {
            return nil
        }

        self.id = id
        self.title = title
        self.description = data["description"] as? String ?? ""
        self.instructor = instructor
        self.price = data["price"] as? Double ?? 0.0
        self.duration = data["duration"] as? Int ?? 60
        self.category = data["category"] as? String ?? "General"
        self.imageURL = data["image_url"] as? String
    }
}

struct SimpleBooking {
    let id: String
    let classId: String
    let className: String
    let instructor: String
    let bookingDate: Date
    let status: String
    let price: Double

    init?(from data: [String: Any]) {
        guard let id = data["id"] as? String,
              let classId = data["class_id"] as? String,
              let bookingDateString = data["booking_date"] as? String else {
            return nil
        }

        self.id = id
        self.classId = classId
        self.status = data["status"] as? String ?? "pending"

        // Handle nested class data
        if let classData = data["classes"] as? [String: Any] {
            self.className = classData["title"] as? String ?? "Unknown Class"
            self.instructor = classData["instructor"] as? String ?? "Unknown Instructor"
            self.price = classData["price"] as? Double ?? 0.0
        } else {
            self.className = "Unknown Class"
            self.instructor = "Unknown Instructor"
            self.price = 0.0
        }

        // Parse date
        let formatter = ISO8601DateFormatter()
        self.bookingDate = formatter.date(from: bookingDateString) ?? Date()
    }
}