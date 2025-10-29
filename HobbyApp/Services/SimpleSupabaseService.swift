import Foundation
import Supabase
import AuthenticationServices

// Simplified Supabase service for working backend integration
@MainActor
final class SimpleSupabaseService: ObservableObject {
    static let shared = SimpleSupabaseService()

    private lazy var supabaseClient: SupabaseClient = {
        guard let configuration = AppConfiguration.shared.current else {
            fatalError("""
            Supabase configuration missing.
            Configure Config-Dev.plist or environment variables before running the app.
            """)
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

    // Published properties for UI binding
    @Published var isAuthenticated = false
    @Published var currentUser: SimpleUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {
        setupSupabase()
    }

    var client: SupabaseClient {
        supabaseClient
    }

    private func setupSupabase() {
        _ = supabaseClient

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
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let nowString = isoFormatter.string(from: Date())

            let response = try await supabaseClient
                .from("class_schedules")
                .select("""
                    id,
                    start_time,
                    end_time,
                    spots_total,
                    spots_available,
                    classes(
                        *,
                        instructors(
                            id,
                            name,
                            email
                        ),
                        studios(
                            id,
                            name,
                            address,
                            city,
                            province,
                            postal_code
                        )
                    )
                """)
                .gte("start_time", value: nowString)
                .eq("classes.is_active", value: true)
                .order("start_time", ascending: true)
                .limit(50)
                .execute()

            guard let schedules = try response.value as? [[String: Any]] else {
                return []
            }

            return schedules.compactMap { schedule in
                guard var classData = schedule["classes"] as? [String: Any] else { return nil }

                classData["schedule_id"] = schedule["id"]
                classData["start_time"] = schedule["start_time"]
                classData["end_time"] = schedule["end_time"]
                classData["spots_total"] = schedule["spots_total"]
                classData["spots_available"] = schedule["spots_available"]
                classData["max_participants"] = schedule["spots_total"]

                if let total = schedule["spots_total"] as? Int,
                   let available = schedule["spots_available"] as? Int {
                    classData["current_participants"] = max(0, total - available)
                }

                if let instructors = classData["instructors"] as? [[String: Any]],
                   let primaryInstructor = instructors.first {
                    classData["instructor_name"] = primaryInstructor["name"]
                    classData["instructor_profile"] = primaryInstructor
                }

                if let studio = classData["studios"] as? [String: Any] {
                    let address: [String: Any] = [
                        "street": studio["address"] ?? "",
                        "city": studio["city"] ?? "",
                        "state": studio["province"] ?? "",
                        "zip": studio["postal_code"] ?? "",
                        "country": "Canada"
                    ]
                    classData["location"] = [
                        "type": "in_person",
                        "name": studio["name"] ?? "",
                        "address": address
                    ]
                }

                classData.removeValue(forKey: "instructors")
                classData.removeValue(forKey: "studios")

                return SimpleClass(from: classData)
            }
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
                .select("""
                    id,
                    status,
                    credits_used,
                    created_at,
                    class_schedule:class_schedules(
                        id,
                        start_time,
                        end_time,
                        classes(
                            *,
                            instructors(
                                id,
                                name,
                                email
                            ),
                            studios(
                                id,
                                name,
                                address,
                                city,
                                province,
                                postal_code
                            )
                        )
                    )
                """)
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()

            guard let bookings = try response.value as? [[String: Any]] else {
                return []
            }

            return bookings.compactMap { SimpleBooking(from: $0) }
        } catch {
            print("❌ Fetch bookings error: \(error)")
            errorMessage = error.localizedDescription
            return []
        }
    }

    func createBooking(classId: String, date: Date, scheduleId: String? = nil, creditsUsed: Int = 1, paymentMethod: String? = "credits") async -> Bool {
        guard let userId = currentUser?.id else { return false }

        isLoading = true
        errorMessage = nil

        do {
            var targetScheduleId = scheduleId

            if targetScheduleId == nil {
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                let startWindow = isoFormatter.string(from: date.addingTimeInterval(-3600))
                let endWindow = isoFormatter.string(from: date.addingTimeInterval(3600))

                let response = try await supabaseClient
                    .from("class_schedules")
                    .select("id")
                    .eq("class_id", value: classId)
                    .gte("start_time", value: startWindow)
                    .lte("start_time", value: endWindow)
                    .order("start_time", ascending: true)
                    .limit(1)
                    .execute()

                if let rows = try response.value as? [[String: Any]],
                   let foundId = rows.first?["id"] as? String {
                    targetScheduleId = foundId
                }
            }

            guard let scheduleIdentifier = targetScheduleId else {
                errorMessage = "Unable to find a matching class schedule."
                isLoading = false
                return false
            }

            var payload: [String: Any] = [
                "user_id": userId,
                "class_schedule_id": scheduleIdentifier,
                "credits_used": creditsUsed,
                "status": "confirmed"
            ]

            if let paymentMethod {
                payload["payment_method"] = paymentMethod
            }

            let _ = try await supabaseClient
                .from("bookings")
                .insert(payload)
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

    // MARK: - Storage (Profile Pictures)

    func uploadProfilePicture(_ imageData: Data) async throws -> String {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SimpleSupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }

        // Generate unique filename
        let fileName = "\(userId)_\(UUID().uuidString).jpg"
        let filePath = "profile-photos/\(fileName)"

        print("📸 Uploading profile picture to: \(filePath)")
        print("📸 Image size: \(imageData.count) bytes")

        do {
            // Upload to Supabase Storage 'avatars' bucket
            let uploadResponse = try await supabaseClient.storage
                .from("avatars")
                .upload(path: filePath, file: imageData, options: .init(upsert: true))

            print("✅ Upload successful: \(uploadResponse)")

            // Get public URL
            let publicURL = try supabaseClient.storage
                .from("avatars")
                .getPublicURL(path: filePath)

            print("✅ Public URL generated: \(publicURL)")

            // Update user_profiles table with avatar URL
            try await updateUserProfile(avatarURL: publicURL.absoluteString)

            return publicURL.absoluteString

        } catch {
            print("❌ Profile picture upload failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
    }

    func updateUserProfile(avatarURL: String? = nil, fullName: String? = nil, bio: String? = nil) async throws {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SimpleSupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }

        print("📝 Upserting user profile with avatar URL...")

        do {
            // Use UPSERT to insert if row doesn't exist, update if it does
            var payload: [String: Any] = [
                "id": userId,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]

            if let avatarURL {
                payload["avatar_url"] = avatarURL
            }

            if let fullName {
                payload["full_name"] = fullName
            }

            if let bio {
                payload["bio"] = bio
            }

            let _ = try await supabaseClient
                .from("user_profiles")
                .upsert(payload)
                .execute()

            print("✅ User profile upserted successfully (avatar URL saved)")

            if let fullName = fullName, let currentUser = currentUser {
                self.currentUser = SimpleUser(
                    id: currentUser.id,
                    email: currentUser.email,
                    name: fullName
                )
            }

        } catch {
            print("❌ Failed to upsert user profile: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchUserProfileAvatarURL() async -> String? {
        guard let userId = currentUser?.id else {
            print("❌ No authenticated user for fetching avatar")
            return nil
        }

        do {
            let response = try await supabaseClient
                .from("user_profiles")
                .select("avatar_url")
                .eq("id", value: userId)
                .single()
                .execute()

            let data = try response.value as! [String: Any]
            let avatarURL = data["avatar_url"] as? String
            print("✅ Fetched avatar URL: \(avatarURL ?? "nil")")
            return avatarURL

        } catch {
            print("❌ Failed to fetch avatar URL: \(error)")
            return nil
        }
    }

    func deleteProfilePicture(avatarURL: String) async throws {
        // Extract file path from URL
        guard let url = URL(string: avatarURL),
              let pathComponents = url.pathComponents.last else {
            throw NSError(domain: "SimpleSupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid avatar URL"])
        }

        let filePath = "profile-photos/\(pathComponents)"

        print("🗑️ Deleting profile picture: \(filePath)")

        do {
            let _ = try await supabaseClient.storage
                .from("avatars")
                .remove(paths: [filePath])

            print("✅ Profile picture deleted successfully")

            // Clear avatar URL from user profile
            try await updateUserProfile(avatarURL: "")

        } catch {
            print("❌ Failed to delete profile picture: \(error)")
            throw error
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

    // MARK: - User Profile Summary

    func fetchUserProfile() async -> SimpleUserProfile? {
        guard let userId = currentUser?.id else {
            print("❌ No authenticated user for fetching profile")
            return nil
        }

        do {
            let response = try await supabaseClient
                .from("user_profiles")
                .select("""
                    id,
                    full_name,
                    first_name,
                    last_name,
                    avatar_url,
                    bio,
                    created_at,
                    updated_at
                """)
                .eq("id", value: userId)
                .single()
                .execute()

            let data = try response.value as! [String: Any]
            return SimpleUserProfile(from: data, fallbackEmail: currentUser?.email ?? "")
        } catch {
            print("❌ Failed to fetch user profile: \(error)")
            return nil
        }
    }
}

// MARK: - Simple Models

struct SimpleUser {
    let id: String
    let email: String
    let name: String
}

struct SimpleClass: Identifiable {
    let id: String
    let scheduleId: String?
    let title: String
    let description: String
    let instructor: String
    let price: Double
    let duration: Int // minutes
    let category: String
    let difficulty: String
    let spotsTotal: Int?
    let spotsAvailable: Int?
    let maxParticipants: Int?
    let currentParticipants: Int?
    let tags: [String]
    let requirements: [String]
    let whatToBring: [String]
    let scheduleType: String?
    let startDate: Date?
    let endDate: Date?
    let locationType: String?
    let locationName: String?
    let locationAddress: String?
    let locationCity: String?
    let locationState: String?
    let locationZip: String?
    let locationCountry: String?
    let latitude: Double?
    let longitude: Double?
    let isOnline: Bool
    let onlineLink: String?
    let imageURL: String?
    let averageRating: Double
    let totalReviews: Int
    let cancellationPolicy: String?

    var priceFormatted: String {
        if price == 0 { return "Free" }
        return price.truncatingRemainder(dividingBy: 1) == 0
            ? "$\(Int(price))"
            : String(format: "$%.2f", price)
    }

    var spotsRemaining: Int? {
        if let spotsAvailable {
            return spotsAvailable
        }
        guard let maxParticipants else { return nil }
        let current = currentParticipants ?? 0
        return max(0, maxParticipants - current)
    }

    var displayLocation: String {
        if isOnline {
            return "Online"
        }

        if let locationName, !locationName.isEmpty {
            return locationName
        }

        if let street = locationAddress, !street.isEmpty,
           let city = locationCity, !city.isEmpty {
            return "\(street), \(city)"
        }

        if let city = locationCity, !city.isEmpty {
            return city
        }

        if let street = locationAddress, !street.isEmpty {
            return street
        }

        return "In person"
    }

    var fullAddress: String? {
        guard !isOnline else { return nil }

        var components: [String] = []

        if let street = locationAddress, !street.isEmpty {
            components.append(street)
        }

        var cityStateZip: [String] = []
        if let city = locationCity, !city.isEmpty {
            cityStateZip.append(city)
        }
        if let state = locationState, !state.isEmpty {
            cityStateZip.append(state)
        }
        if let zip = locationZip, !zip.isEmpty {
            cityStateZip.append(zip)
        }
        if !cityStateZip.isEmpty {
            components.append(cityStateZip.joined(separator: ", "))
        }

        if let country = locationCountry, !country.isEmpty {
            components.append(country)
        }

        return components.isEmpty ? nil : components.joined(separator: "\n")
    }

    init?(from data: [String: Any]) {
        // Identifier
        guard let rawId = data["id"] else { return nil }
        if let stringId = rawId as? String {
            self.id = stringId
        } else if let uuid = rawId as? UUID {
            self.id = uuid.uuidString
        } else {
            return nil
        }

        let extractedScheduleId = data["schedule_id"] as? String ?? data["class_schedule_id"] as? String
        let extractedSpotsTotal = SimpleClass.int(from: data["spots_total"])
        let extractedSpotsAvailable = SimpleClass.int(from: data["spots_available"])

        self.scheduleId = extractedScheduleId
        self.spotsTotal = extractedSpotsTotal
        self.spotsAvailable = extractedSpotsAvailable

        // Title / description
        guard let title = data["title"] as? String ?? data["name"] as? String else {
            return nil
        }
        self.title = title
        self.description = data["description"] as? String
            ?? data["summary"] as? String
            ?? ""

        // Instructor details (support multiple shapes)
        if let instructor = data["instructor"] as? String {
            self.instructor = instructor
        } else if let instructorName = data["instructor_name"] as? String {
            self.instructor = instructorName
        } else if let instructorProfile = data["instructor"] as? [String: Any],
                  let displayName = instructorProfile["display_name"] as? String ?? instructorProfile["name"] as? String {
            self.instructor = displayName
        } else if let instructorProfile = data["instructor_profile"] as? [String: Any],
                  let displayName = instructorProfile["display_name"] as? String ?? instructorProfile["name"] as? String {
            self.instructor = displayName
        } else {
            self.instructor = "Instructor"
        }

        // Duration in minutes (accept multiple key formats)
        let durationValue: Int
        if let duration = data["duration"] as? Int {
            durationValue = duration
        } else if let duration = data["duration_minutes"] as? Int {
            durationValue = duration
        } else if let durationDouble = data["duration"] as? Double {
            durationValue = Int(durationDouble)
        } else if let durationString = data["duration"] as? String,
                  let durationParsed = Int(durationString) {
            durationValue = durationParsed
        } else {
            durationValue = 60
        }
        self.duration = durationValue

        // Category
        if let category = data["category"] as? String {
            self.category = category
        } else if let categoryName = data["category_name"] as? String {
            self.category = categoryName
        } else if let categoryDict = data["category"] as? [String: Any],
                  let categoryName = categoryDict["name"] as? String {
            self.category = categoryName
        } else if let categoryDict = data["categories"] as? [String: Any],
                  let categoryName = categoryDict["name"] as? String {
            self.category = categoryName
        } else {
            self.category = "General"
        }

        // Difficulty
        let difficultyRaw = (data["difficulty_level"] as? String ?? data["difficulty"] as? String ?? "all_levels")
        self.difficulty = difficultyRaw

        // Participants
        let maxParticipantsValue = SimpleClass.int(from: data["max_participants"]) ?? extractedSpotsTotal
        self.maxParticipants = maxParticipantsValue

        if let explicitCurrent = SimpleClass.int(from: data["current_participants"]) {
            self.currentParticipants = explicitCurrent
        } else if let maxParticipantsValue, let extractedSpotsAvailable {
            self.currentParticipants = max(0, maxParticipantsValue - extractedSpotsAvailable)
        } else {
            self.currentParticipants = nil
        }

        // Tags and requirements
        if let tags = data["tags"] as? [String] {
            self.tags = tags
        } else if let tagsAny = data["tags"] as? [Any] {
            self.tags = tagsAny.compactMap { $0 as? String }
        } else {
            self.tags = []
        }

        if let requirements = data["requirements"] as? [String] {
            self.requirements = requirements
        } else if let requirementsAny = data["requirements"] as? [Any] {
            self.requirements = requirementsAny.compactMap { $0 as? String }
        } else {
            self.requirements = []
        }

        if let whatToBring = data["what_to_bring"] as? [String] {
            self.whatToBring = whatToBring
        } else if let whatToBringAny = data["what_to_bring"] as? [Any] {
            self.whatToBring = whatToBringAny.compactMap { $0 as? String }
        } else {
            self.whatToBring = []
        }

        // Price (support cents, strings, decimals)
        let rawPrice = data["price"]
            ?? data["price_cents"]
            ?? data["base_price"]
            ?? (data["pricing"] as? [String: Any])?["amount"]
        if let price = rawPrice as? Double {
            self.price = price >= 1000 ? price / 100.0 : price
        } else if let price = rawPrice as? Int {
            self.price = price >= 100 ? Double(price) / 100.0 : Double(price)
        } else if let priceNSNumber = rawPrice as? NSNumber {
            let value = priceNSNumber.doubleValue
            self.price = value >= 100 ? value / 100.0 : value
        } else if let priceString = rawPrice as? String,
                  let priceValue = Double(priceString) {
            self.price = priceValue >= 100 ? priceValue / 100.0 : priceValue
        } else {
            self.price = 0
        }

        // Location
        let locationDict = data["location"] as? [String: Any]
        let addressDict = locationDict?["address"] as? [String: Any]
        let explicitOnlineFlag = data["is_online"] as? Bool ?? false
        let resolvedLocationType = locationDict?["type"] as? String ?? (explicitOnlineFlag ? "online" : nil)
        self.locationType = resolvedLocationType
        self.isOnline = explicitOnlineFlag || (resolvedLocationType == "online")
        self.onlineLink = locationDict?["online_link"] as? String

        let locationNameCandidates: [String?] = [
            locationDict?["name"] as? String,
            locationDict?["venue_name"] as? String,
            locationDict?["business_name"] as? String,
            locationDict?["label"] as? String,
            addressDict?["street"] as? String
        ]
        self.locationName = locationNameCandidates.first(where: { ($0?.isEmpty ?? true) == false }) ?? nil
        self.locationAddress = addressDict?["street"] as? String
        self.locationCity = addressDict?["city"] as? String
        self.locationState = addressDict?["state"] as? String
        self.locationZip = addressDict?["zip"] as? String
        self.locationCountry = addressDict?["country"] as? String
        self.latitude = SimpleClass.double(from: addressDict?["lat"])
        self.longitude = SimpleClass.double(from: addressDict?["lng"])

        // Schedule
        let scheduleDict = data["schedule"] as? [String: Any]
        self.scheduleType = scheduleDict?["type"] as? String

        var startDateValue = SimpleClass.parseISODate(from: data["start_time"])
        var endDateValue = SimpleClass.parseISODate(from: data["end_time"])

        if startDateValue == nil {
            startDateValue = SimpleClass.parseDate(
                date: scheduleDict?["start_date"] as? String,
                time: scheduleDict?["start_time"] as? String
            )
        }

        if endDateValue == nil {
            endDateValue = SimpleClass.parseDate(
                date: (scheduleDict?["end_date"] as? String) ?? (scheduleDict?["start_date"] as? String),
                time: (scheduleDict?["end_time"] as? String) ?? (scheduleDict?["start_time"] as? String)
            )
        }

        self.startDate = startDateValue
        if let endDateValue {
            self.endDate = endDateValue
        } else if let startDateValue {
            self.endDate = startDateValue.addingTimeInterval(Double(durationValue) * 60)
        } else {
            self.endDate = nil
        }

        // Ratings / reviews
        if let rating = data["average_rating"] as? Double {
            self.averageRating = rating
        } else if let rating = data["rating"] as? Double {
            self.averageRating = rating
        } else if let ratingNumber = data["average_rating"] as? NSNumber {
            self.averageRating = ratingNumber.doubleValue
        } else if let ratingString = data["average_rating"] as? String,
                  let ratingValue = Double(ratingString) {
            self.averageRating = ratingValue
        } else {
            self.averageRating = 0
        }

        self.totalReviews = SimpleClass.int(from: data["total_reviews"])
            ?? SimpleClass.int(from: data["reviews_count"])
            ?? 0

        // Cancellation policy
        if let policy = data["cancellation_policy"] as? String {
            self.cancellationPolicy = policy
        } else if let policyDict = data["cancellation_policy"] as? [String: Any],
                  let summary = policyDict["summary"] as? String {
            self.cancellationPolicy = summary
        } else {
            self.cancellationPolicy = nil
        }

        // Preferred image
        if let directURL = data["image_url"] as? String {
            self.imageURL = directURL
        } else if let images = data["images"] as? [[String: Any]] {
            let primaryImage = images.first { ($0["is_primary"] as? Bool) == true } ?? images.first
            self.imageURL = primaryImage?["url"] as? String
        } else if let media = data["media"] as? [[String: Any]] {
            self.imageURL = media.first?["url"] as? String
        } else {
            self.imageURL = nil
        }
    }

    private static func parseDate(date: String?, time: String?) -> Date? {
        guard let date else { return nil }

        if let time, !time.isEmpty {
            let combined = "\(date) \(time)"
            if let dateTime = dateTimeFormatter.date(from: combined) {
                return dateTime
            }
            if let dateTimeWithSeconds = dateTimeWithSecondsFormatter.date(from: combined) {
                return dateTimeWithSeconds
            }
        }

        return dateFormatter.date(from: date)
    }

    private static func double(from value: Any?) -> Double? {
        switch value {
        case let doubleValue as Double:
            return doubleValue
        case let number as NSNumber:
            return number.doubleValue
        case let string as String:
            return Double(string)
        default:
            return nil
        }
    }

    private static func int(from value: Any?) -> Int? {
        switch value {
        case let intValue as Int:
            return intValue
        case let number as NSNumber:
            return number.intValue
        case let string as String:
            return Int(string)
        default:
            return nil
        }
    }

    private static let isoFractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func parseISODate(from value: Any?) -> Date? {
        guard let stringValue = value as? String else { return nil }
        return isoFractionalFormatter.date(from: stringValue) ?? isoFormatter.date(from: stringValue)
    }

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    private static let dateTimeWithSecondsFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct SimpleBooking {
    let id: String
    let classId: String
    let classScheduleId: String
    let className: String
    let instructor: String
    let bookingDate: Date
    let status: String
    let price: Double
    let venue: String?

    var formattedPrice: String {
        if price == 0 { return "Free" }
        return price.truncatingRemainder(dividingBy: 1) == 0
            ? "$\(Int(price))"
            : String(format: "$%.2f", price)
    }

    init?(from data: [String: Any]) {
        // Identifier handling
        guard let rawId = data["id"] else { return nil }
        let bookingId: String
        if let stringId = rawId as? String {
            bookingId = stringId
        } else if let uuid = rawId as? UUID {
            bookingId = uuid.uuidString
        } else {
            return nil
        }

        guard let scheduleDict = data["class_schedule"] as? [String: Any] else {
            return nil
        }

        let scheduleIdentifier: String
        if let stringId = scheduleDict["id"] as? String {
            scheduleIdentifier = stringId
        } else if let uuid = scheduleDict["id"] as? UUID {
            scheduleIdentifier = uuid.uuidString
        } else {
            return nil
        }

        guard let classData = scheduleDict["classes"] as? [String: Any] else {
            return nil
        }

        let classIdentifier: String
        if let classIdString = classData["id"] as? String {
            classIdentifier = classIdString
        } else if let classIdUUID = classData["id"] as? UUID {
            classIdentifier = classIdUUID.uuidString
        } else {
            return nil
        }

        self.id = bookingId
        self.classId = classIdentifier
        self.classScheduleId = scheduleIdentifier
        self.status = data["status"] as? String ?? "pending"

        self.className = classData["name"] as? String
            ?? classData["title"] as? String
            ?? "Unknown Class"

        if let instructors = classData["instructors"] as? [[String: Any]],
           let primaryInstructor = instructors.first,
           let name = primaryInstructor["name"] as? String {
            self.instructor = name
        } else if let instructorName = classData["instructor_name"] as? String {
            self.instructor = instructorName
        } else {
            self.instructor = "Unknown Instructor"
        }

        let rawPrice = classData["price"]
            ?? classData["price_cents"]
            ?? (classData["pricing"] as? [String: Any])?["amount"]
        if let price = rawPrice as? Double {
            self.price = price >= 1000 ? price / 100.0 : price
        } else if let price = rawPrice as? Int {
            self.price = price >= 100 ? Double(price) / 100.0 : Double(price)
        } else if let priceNSNumber = rawPrice as? NSNumber {
            let value = priceNSNumber.doubleValue
            self.price = value >= 100 ? value / 100.0 : value
        } else if let priceString = rawPrice as? String,
                  let priceValue = Double(priceString) {
            self.price = priceValue >= 100 ? priceValue / 100.0 : priceValue
        } else {
            self.price = 0.0
        }

        var venueValue: String?
        if let studio = classData["studios"] as? [String: Any] {
            if let address = studio["address"] as? String,
               let city = studio["city"] as? String,
               !address.isEmpty, !city.isEmpty {
                venueValue = "\(address), \(city)"
            } else if let address = studio["address"] as? String, !address.isEmpty {
                venueValue = address
            } else if let city = studio["city"] as? String, !city.isEmpty {
                venueValue = city
            } else if let name = studio["name"] as? String {
                venueValue = name
            }
        } else if let locationDict = classData["location"] as? [String: Any],
                  let address = locationDict["address"] as? [String: Any] {
            let street = address["street"] as? String
            let city = address["city"] as? String
            if let street, !street.isEmpty, let city, !city.isEmpty {
                venueValue = "\(street), \(city)"
            } else if let street, !street.isEmpty {
                venueValue = street
            } else if let city, !city.isEmpty {
                venueValue = city
            }
        }

        self.venue = venueValue

        let bookingDateString = scheduleDict["start_time"] as? String
            ?? data["created_at"] as? String
            ?? data["updated_at"] as? String

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let standardFormatter = ISO8601DateFormatter()

        if let bookingDateString,
           let parsed = fractionalFormatter.date(from: bookingDateString) ?? standardFormatter.date(from: bookingDateString) {
            self.bookingDate = parsed
        } else {
            self.bookingDate = Date()
        }
    }
}

struct SimpleUserProfile {
    let id: String
    let firstName: String
    let lastName: String
    let fullName: String
    let email: String
    let avatarURL: String?
    let bio: String?
    let createdAt: Date?
    let updatedAt: Date?

    var memberSinceText: String {
        guard let createdAt else { return "Member" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Member since \(formatter.string(from: createdAt))"
    }

    init?(from data: [String: Any], fallbackEmail: String) {
        guard let id = data["id"] as? String else { return nil }

        self.id = id
        self.firstName = data["first_name"] as? String
            ?? (data["full_name"] as? String)?.components(separatedBy: " ").first
            ?? ""
        self.lastName = data["last_name"] as? String
            ?? (data["full_name"] as? String)?.components(separatedBy: " ").dropFirst().joined(separator: " ")
            ?? ""
        let combinedName = data["full_name"] as? String
            ?? [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        self.fullName = combinedName.isEmpty ? "Hobbyist" : combinedName
        self.email = data["email"] as? String ?? fallbackEmail
        self.avatarURL = data["avatar_url"] as? String
        self.bio = data["bio"] as? String

        let isoFormatter = ISO8601DateFormatter()
        if let createdAtString = data["created_at"] as? String,
           let date = isoFormatter.date(from: createdAtString) {
            self.createdAt = date
        } else {
            self.createdAt = nil
        }

        if let updatedAtString = data["updated_at"] as? String,
           let date = isoFormatter.date(from: updatedAtString) {
            self.updatedAt = date
        } else {
            self.updatedAt = nil
        }
    }

    init(
        id: String,
        firstName: String,
        lastName: String,
        fullName: String,
        email: String,
        avatarURL: String?,
        bio: String?,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.fullName = fullName
        self.email = email
        self.avatarURL = avatarURL
        self.bio = bio
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
