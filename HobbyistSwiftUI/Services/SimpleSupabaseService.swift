import Foundation
import Supabase
import AuthenticationServices

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

            // Check if user is immediately authenticated (no email confirmation required)
            if let session = response.session, session.accessToken != nil {
                let user = response.user
                currentUser = SimpleUser(
                    id: user.id.uuidString,
                    email: user.email ?? email,
                    name: fullName
                )
                isAuthenticated = true
                print("✅ User signed up and authenticated immediately: \(email)")
            } else {
                print("✅ User signed up: \(email)")
                print("ℹ️ User needs to verify email before signing in")
            }
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

    // MARK: - Apple Sign In

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        errorMessage = nil

        print("🍎 Starting Apple Sign In process...")
        print("🍎 User ID: \(credential.user)")
        print("🍎 Email: \(credential.email ?? "nil")")
        print("🍎 Full Name: \(credential.fullName?.givenName ?? "nil") \(credential.fullName?.familyName ?? "nil")")

        do {
            guard let identityToken = credential.identityToken else {
                print("❌ Apple Sign In: No identity token found")
                errorMessage = "Failed to get Apple ID token - no token provided"
                isLoading = false
                return
            }

            guard let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                print("❌ Apple Sign In: Failed to convert identity token to string")
                errorMessage = "Failed to process Apple ID token - invalid format"
                isLoading = false
                return
            }

            print("🍎 Identity token obtained successfully (length: \(identityTokenString.count))")
            print("🍎 Attempting Supabase authentication...")

            let response = try await supabaseClient.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: identityTokenString
                )
            )

            print("🍎 Supabase authentication successful!")
            print("🍎 User ID from Supabase: \(response.user.id)")

            let user = response.user
            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            currentUser = SimpleUser(
                id: user.id.uuidString,
                email: user.email ?? credential.email ?? "",
                name: fullName.isEmpty ? (user.userMetadata["full_name"]?.value as? String ?? "User") : fullName
            )
            isAuthenticated = true
            print("✅ Apple Sign In completed successfully")
            print("✅ User authenticated: \(currentUser?.name ?? "Unknown")")

        } catch {
            print("❌ Apple Sign In error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error details: \(error.localizedDescription)")

            // Check for NSError with specific codes
            if let nsError = error as NSError? {
                print("❌ NSError domain: \(nsError.domain)")
                print("❌ NSError code: \(nsError.code)")
                print("❌ NSError userInfo: \(nsError.userInfo)")
            }

            // Enhanced error messaging based on common issues
            if error.localizedDescription.contains("invalid_client") {
                errorMessage = "Apple Sign In configuration error. Bundle ID may not be registered in Apple Developer Console."
            } else if error.localizedDescription.contains("invalid_request") {
                errorMessage = "Apple Sign In request error. Please verify app capabilities and try again."
            } else if error.localizedDescription.contains("network") || error.localizedDescription.contains("internet") {
                errorMessage = "Network error. Please check your internet connection and try again."
            } else if let nsError = error as NSError?, nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" {
                switch nsError.code {
                case 1000:
                    errorMessage = "Apple Sign In canceled by user."
                case 1001:
                    errorMessage = "Apple Sign In failed. Please verify your Apple Developer Console configuration for bundle ID: com.hobbyist.bookingapp"
                case 1004:
                    errorMessage = "Apple Sign In not supported on this device."
                default:
                    errorMessage = "Apple Sign In failed with error code \(nsError.code). Please check your app configuration."
                }
            } else {
                errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            }

        }

        isLoading = false
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

    // MARK: - User Preferences & Onboarding

    func saveOnboardingPreferences(_ preferences: [String: Any]) async -> Bool {
        guard let userId = currentUser?.id else {
            print("❌ No authenticated user for saving preferences")
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            // For now, just save to UserDefaults as a fallback
            // TODO: Implement proper Supabase integration when user_profiles table is ready
            UserDefaults.standard.set(true, forKey: "hobbyist_onboarding_completed")
            UserDefaults.standard.set(preferences, forKey: "hobbyist_user_preferences")

            print("✅ Onboarding preferences saved successfully (to UserDefaults)")
            isLoading = false
            return true

        } catch {
            print("❌ Error saving onboarding preferences: \(error)")
            errorMessage = "Failed to save your preferences. Please try again."
            isLoading = false
            return false
        }
    }

    func fetchUserPreferences() async -> [String: Any]? {
        guard let userId = currentUser?.id else {
            print("❌ No authenticated user for fetching preferences")
            return nil
        }

        // For now, fetch from UserDefaults as fallback
        // TODO: Implement proper Supabase integration when user_profiles table is ready
        if let preferences = UserDefaults.standard.dictionary(forKey: "hobbyist_user_preferences") {
            var result = preferences
            result["onboarding_completed"] = UserDefaults.standard.bool(forKey: "hobbyist_onboarding_completed")
            print("✅ User preferences fetched successfully (from UserDefaults)")
            return result
        } else {
            print("ℹ️ No user preferences found")
            return nil
        }
    }

    func updateOnboardingCompletion(_ isCompleted: Bool) async -> Bool {
        guard let userId = currentUser?.id else {
            print("❌ No authenticated user for updating onboarding status")
            return false
        }

        // For now, update UserDefaults as fallback
        // TODO: Implement proper Supabase integration when user_profiles table is ready
        UserDefaults.standard.set(isCompleted, forKey: "hobbyist_onboarding_completed")
        print("✅ Onboarding completion status updated (to UserDefaults)")
        return true
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