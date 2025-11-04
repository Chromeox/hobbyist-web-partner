import Foundation
import Supabase
import CoreLocation
import Combine
import SwiftUI

// MARK: - Missing Models (Nuclear Option Stubs)
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

class ServiceContainer {
    static let shared = ServiceContainer()
    private init() {}

    func searchClasses(query: String) async throws -> [HobbyClass] {
        return []
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

class SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    func fetchActivities() async throws -> [Any] {
        return []
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

class InstructorService {
    static let shared = InstructorService()
    private init() {}

    func fetchInstructors() async throws -> [Any] {
        return []
    }

    func fetchAllInstructors() async throws -> [Instructor] {
        return []
    }

    func fetchNearbyInstructors(location: CLLocation, radius: Double) async throws -> [Instructor] {
        return []
    }
}

class VenueService {
    static let shared = VenueService()
    private init() {}

    func fetchVenues() async throws -> [Any] {
        return []
    }

    func fetchAllVenues() async throws -> [Venue] {
        return []
    }
}


class ClassService {
    static let shared = ClassService()
    private let supabaseService = SimpleSupabaseService.shared

    private init() {}

    func fetchUpcomingClasses() async throws -> [ClassItem] {
        let classes = await supabaseService.fetchClasses()
        if classes.isEmpty {
            throw makeServiceError()
        }
        return Array(classes.prefix(10)).map { ClassItem.from(simpleClass: $0) }
    }

    func searchClasses(query: String) async throws -> [ClassItem] {
        let classes = await supabaseService.fetchClasses()
        if classes.isEmpty {
            throw makeServiceError()
        }

        guard !query.isEmpty else {
            return classes.map { ClassItem.from(simpleClass: $0) }
        }

        let lowerQuery = query.lowercased()
        let filtered = classes.filter { simpleClass in
            simpleClass.title.lowercased().contains(lowerQuery) ||
            simpleClass.description.lowercased().contains(lowerQuery) ||
            simpleClass.instructor.lowercased().contains(lowerQuery) ||
            simpleClass.category.lowercased().contains(lowerQuery)
        }

        return filtered.map { ClassItem.from(simpleClass: $0) }
    }

    func fetchClasses() async throws -> [HobbyClass] {
        let classes = await supabaseService.fetchClasses()
        if classes.isEmpty {
            throw makeServiceError()
        }
        return classes.map { HobbyClass(simpleClass: $0) }
    }

    func fetchMoreClasses(offset: Int) async throws -> [HobbyClass] {
        let classes = try await fetchClasses()
        guard offset < classes.count else { return [] }
        return Array(classes[offset...].prefix(10))
    }

    private func makeServiceError() -> NSError {
        NSError(
            domain: "ClassService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: supabaseService.errorMessage ?? "Unable to load classes from Supabase."]
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
    private let userDefaultsKey = "hobbyist.recentSearches"

    private init() {}

    func searchClasses(query: String) async throws -> [HobbyClass] {
        let classes = try await classService.fetchClasses()

        let filtered: [HobbyClass]
        if query.isEmpty {
            filtered = classes
        } else {
            let lowerQuery = query.lowercased()
            filtered = classes.filter { hobbyClass in
                hobbyClass.title.lowercased().contains(lowerQuery) ||
                hobbyClass.description.lowercased().contains(lowerQuery) ||
                hobbyClass.instructor.name.lowercased().contains(lowerQuery) ||
                hobbyClass.category.rawValue.lowercased().contains(lowerQuery)
            }
        }

        return filtered.sorted { $0.startDate < $1.startDate }
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
        return Array(Set(classes.map { $0.category.rawValue })).sorted()
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
