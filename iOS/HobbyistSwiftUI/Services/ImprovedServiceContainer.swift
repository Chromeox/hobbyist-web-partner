import Foundation
import Combine

// MARK: - Service Protocols

protocol AuthenticationServiceProtocol {
    var currentUser: User? { get }
    var currentUserPublisher: AnyPublisher<User?, Never> { get }
    func signUp(email: String, password: String, fullName: String) async throws
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    func resetPassword(email: String) async throws
    func checkCurrentSession() async
}

protocol ClassServiceProtocol {
    func fetchClasses() async throws -> [HobbyClass]
    func fetchMoreClasses(offset: Int, limit: Int) async throws -> [HobbyClass]
    func fetchClass(id: String) async throws -> HobbyClass
}

protocol BookingServiceProtocol {
    var bookings: [Booking] { get }
    var bookingsPublisher: AnyPublisher<[Booking], Never> { get }
    func createBooking(_ request: BookingRequest) async throws -> Booking
    func fetchUserBookings(userId: String) async throws -> [Booking]
    func cancelBooking(bookingId: String) async throws
    func sendConfirmationEmail(for booking: Booking) async throws
}

protocol PaymentServiceProtocol {
    func processPayment(amount: Double, method: PaymentMethod, userId: String) async throws -> PaymentService.PaymentResult
    func processRefund(paymentId: String, amount: Double) async throws
    func validateCoupon(code: String) async throws -> Coupon
}

protocol FavoritesServiceProtocol {
    var favoriteClassIds: Set<String> { get }
    var favoritesPublisher: AnyPublisher<Set<String>, Never> { get }
    func toggleFavorite(classId: String) async throws
    func fetchFavoriteClasses(userId: String) async throws -> [HobbyClass]
}

protocol SearchServiceProtocol {
    func search(with parameters: SearchParameters) async throws -> [SearchResult]
    func fetchAutocompleteSuggestions(for query: String) async throws -> [String]
    func fetchRecentSearches() async throws -> [String]
    func saveRecentSearches(_ searches: [String]) async throws
    func fetchPopularSearches() async throws -> [String]
    func fetchSuggestedClasses() async throws -> [HobbyClass]
    func fetchNearbyClasses(location: CLLocation, radius: Double) async throws -> [HobbyClass]
    func fetchTrendingCategories() async throws -> [TrendingCategory]
}

protocol ProfileServiceProtocol {
    func fetchProfile(userId: String) async throws -> User
    func updateProfile(userId: String, updates: ProfileUpdate) async throws -> User
    func fetchUserStatistics(userId: String) async throws -> UserStatistics
    func fetchUserPreferences(userId: String) async throws -> UserPreferences
    func updatePreferences(userId: String, preferences: UserPreferences) async throws -> UserPreferences
    func fetchAchievements(userId: String) async throws -> [Achievement]
    func fetchNotificationSettings(userId: String) async throws -> NotificationSettings
    func updateNotificationSettings(userId: String, settings: NotificationSettings) async throws -> NotificationSettings
    func deleteAccount(userId: String) async throws
    func exportUserData(userId: String) async throws -> URL
}

protocol LocationServiceProtocol {
    var currentLocation: CLLocation? { get }
    var locationPublisher: AnyPublisher<CLLocation?, Never> { get }
    func requestLocationPermission() async
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

protocol StorageServiceProtocol {
    func uploadProfileImage(image: UIImage, userId: String) async throws -> String
}

protocol AnalyticsServiceProtocol {
    func trackEvent(_ name: String, parameters: [String: Any]?)
    func trackScreen(_ name: String)
    func trackSearch(query: String, scope: String, resultCount: Int, locationFilter: String) async
}

// MARK: - Improved Service Container

final class ImprovedServiceContainer {
    static let shared = ImprovedServiceContainer()
    
    // Service storage
    private var services: [ObjectIdentifier: Any] = [:]
    
    // Environment configuration
    private let environment: AppConfiguration.Environment
    private let useMockServices: Bool
    
    private init() {
        self.environment = AppConfiguration.Environment.current
        
        // Use mock services for testing
        #if DEBUG
        self.useMockServices = ProcessInfo.processInfo.arguments.contains("--use-mock-services")
        #else
        self.useMockServices = false
        #endif
        
        configure()
    }
    
    // MARK: - Configuration
    
    private func configure() {
        // Validate configuration first
        guard AppConfiguration.shared.validateConfiguration() else {
            fatalError("Invalid app configuration. Please check AppConfiguration setup.")
        }
        
        // Perform security checks
        performSecurityChecks()
        
        // Register all services
        registerServices()
    }
    
    private func performSecurityChecks() {
        let securityResult = SecurityManager.shared.performSecurityCheck()
        
        if !securityResult.isSecure {
            for issue in securityResult.issues {
                print("⚠️ Security Issue: \(issue.message) (Severity: \(issue.severity))")
                
                // In production, you might want to restrict functionality or alert the user
                #if !DEBUG
                if issue.severity == .critical {
                    // Handle critical security issues
                    NotificationCenter.default.post(
                        name: Notification.Name("CriticalSecurityIssue"),
                        object: issue
                    )
                }
                #endif
            }
        }
        
        // Enable anti-debugging in production
        #if !DEBUG
        SecurityManager.shared.enableAntiDebugging()
        #endif
    }
    
    private func registerServices() {
        if useMockServices {
            registerMockServices()
        } else {
            registerProductionServices()
        }
    }
    
    private func registerProductionServices() {
        // Authentication
        register(AuthenticationService.shared as AuthenticationServiceProtocol, for: AuthenticationServiceProtocol.self)
        
        // Core Services
        register(ClassService.shared as ClassServiceProtocol, for: ClassServiceProtocol.self)
        register(BookingService.shared as BookingServiceProtocol, for: BookingServiceProtocol.self)
        register(PaymentService.shared as PaymentServiceProtocol, for: PaymentServiceProtocol.self)
        register(FavoritesService.shared as FavoritesServiceProtocol, for: FavoritesServiceProtocol.self)
        register(SearchService.shared as SearchServiceProtocol, for: SearchServiceProtocol.self)
        register(ProfileService.shared as ProfileServiceProtocol, for: ProfileServiceProtocol.self)
        
        // Support Services
        register(LocationService.shared as LocationServiceProtocol, for: LocationServiceProtocol.self)
        register(StorageService.shared as StorageServiceProtocol, for: StorageServiceProtocol.self)
        register(AnalyticsService.shared as AnalyticsServiceProtocol, for: AnalyticsServiceProtocol.self)
        
        // Security Services
        register(KeychainService.shared, for: KeychainService.self)
        register(SecurityManager.shared, for: SecurityManager.self)
        register(CertificatePinningService.shared, for: CertificatePinningService.self)
    }
    
    private func registerMockServices() {
        // Register mock implementations for testing
        // These would be created in a separate MockServices file
        print("📱 Using mock services for testing")
    }
    
    // MARK: - Service Registration & Resolution
    
    /// Register a service instance for a protocol
    func register<T>(_ service: T, for type: T.Type) {
        let key = ObjectIdentifier(type)
        services[key] = service
    }
    
    /// Resolve a service for a protocol
    func resolve<T>(_ type: T.Type) -> T {
        let key = ObjectIdentifier(type)
        
        guard let service = services[key] as? T else {
            fatalError("Service of type \(type) is not registered")
        }
        
        return service
    }
    
    /// Check if a service is registered
    func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = ObjectIdentifier(type)
        return services[key] != nil
    }
    
    // MARK: - Convenience Accessors
    
    var authService: AuthenticationServiceProtocol {
        resolve(AuthenticationServiceProtocol.self)
    }
    
    var classService: ClassServiceProtocol {
        resolve(ClassServiceProtocol.self)
    }
    
    var bookingService: BookingServiceProtocol {
        resolve(BookingServiceProtocol.self)
    }
    
    var paymentService: PaymentServiceProtocol {
        resolve(PaymentServiceProtocol.self)
    }
    
    var favoritesService: FavoritesServiceProtocol {
        resolve(FavoritesServiceProtocol.self)
    }
    
    var searchService: SearchServiceProtocol {
        resolve(SearchServiceProtocol.self)
    }
    
    var profileService: ProfileServiceProtocol {
        resolve(ProfileServiceProtocol.self)
    }
    
    var locationService: LocationServiceProtocol {
        resolve(LocationServiceProtocol.self)
    }
    
    var storageService: StorageServiceProtocol {
        resolve(StorageServiceProtocol.self)
    }
    
    var analyticsService: AnalyticsServiceProtocol {
        resolve(AnalyticsServiceProtocol.self)
    }
    
    var keychainService: KeychainService {
        resolve(KeychainService.self)
    }
    
    var securityManager: SecurityManager {
        resolve(SecurityManager.self)
    }
    
    var certificatePinner: CertificatePinningService {
        resolve(CertificatePinningService.self)
    }
    
    // MARK: - Testing Support
    
    /// Reset container for testing
    func reset() {
        services.removeAll()
        configure()
    }
    
    /// Replace a service for testing
    func replaceService<T>(_ service: T, for type: T.Type) {
        register(service, for: type)
    }
}

// MARK: - Service Container Extension for ViewModels

extension ImprovedServiceContainer {
    
    /// Create a configured AuthViewModel
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authService: authService)
    }
    
    /// Create a configured ClassListViewModel
    func makeClassListViewModel() -> ClassListViewModel {
        ClassListViewModel(
            classService: classService,
            favoritesService: favoritesService
        )
    }
    
    /// Create a configured BookingViewModel
    func makeBookingViewModel() -> BookingViewModel {
        BookingViewModel(
            bookingService: bookingService,
            paymentService: paymentService,
            authService: authService
        )
    }
    
    /// Create a configured ProfileViewModel
    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            authService: authService,
            profileService: profileService,
            bookingService: bookingService,
            favoritesService: favoritesService,
            storageService: storageService
        )
    }
    
    /// Create a configured SearchViewModel
    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(
            searchService: searchService,
            locationService: locationService,
            analyticsService: analyticsService
        )
    }
}

// Import required for location services
import CoreLocation
import UIKit