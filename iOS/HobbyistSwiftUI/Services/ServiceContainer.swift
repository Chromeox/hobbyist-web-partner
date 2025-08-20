import Foundation
import Combine

// MARK: - Service Container

final class ServiceContainer {
    static let shared = ServiceContainer()
    
    // Core Services
    private(set) var authService: AuthServiceProtocol!
    private(set) var classService: ClassServiceProtocol!
    private(set) var bookingService: BookingServiceProtocol!
    private(set) var userService: UserServiceProtocol!
    private(set) var paymentService: PaymentServiceProtocol!
    
    // Alpha Testing Services
    private(set) var crashReportingService: CrashReportingServiceProtocol!
    private(set) var feedbackService: FeedbackServiceProtocol!
    private(set) var analyticsService: AnalyticsServiceProtocol!
    private(set) var testFlightService: TestFlightServiceProtocol!
    
    // Support Services
    private(set) var networkService: NetworkServiceProtocol!
    private(set) var storageService: StorageServiceProtocol!
    private(set) var cacheService: CacheServiceProtocol!
    private(set) var notificationService: NotificationServiceProtocol!
    
    private init() {}
    
    func configure(useMocks: Bool = false) {
        if useMocks || isRunningTests() {
            configureMockServices()
        } else {
            configureProductionServices()
        }
        
        // Always use production crash reporting in TestFlight
        if isTestFlight() {
            crashReportingService = CrashReportingService()
            feedbackService = FeedbackService()
        }
    }
    
    private func configureProductionServices() {
        // Network and Storage
        networkService = NetworkService()
        storageService = StorageService()
        cacheService = CacheService()
        
        // Core Services
        authService = AuthService(networkService: networkService)
        userService = UserService(networkService: networkService, cacheService: cacheService)
        classService = ClassService(networkService: networkService, cacheService: cacheService)
        bookingService = BookingService(networkService: networkService, classService: classService)
        paymentService = PaymentService(networkService: networkService)
        
        // Alpha Testing Services
        crashReportingService = CrashReportingService()
        feedbackService = FeedbackService()
        analyticsService = AnalyticsService()
        testFlightService = TestFlightService()
        
        // Support Services
        notificationService = NotificationService()
    }
    
    private func configureMockServices() {
        // Network and Storage
        networkService = MockNetworkService()
        storageService = MockStorageService()
        cacheService = MockCacheService()
        
        // Core Services
        authService = MockAuthService()
        userService = MockUserService()
        classService = MockClassService()
        bookingService = MockBookingService()
        paymentService = MockPaymentService()
        
        // Alpha Testing Services
        crashReportingService = MockCrashReportingService()
        feedbackService = MockFeedbackService()
        analyticsService = MockAnalyticsService()
        testFlightService = MockTestFlightService()
        
        // Support Services
        notificationService = MockNotificationService()
    }
    
    private func isRunningTests() -> Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    private func isTestFlight() -> Bool {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
            return false
        }
        return appStoreReceiptURL.lastPathComponent == "sandboxReceipt"
    }
}

// MARK: - Core Service Protocols

protocol AuthServiceProtocol {
    var isAuthenticated: AnyPublisher<Bool, Never> { get }
    var currentUser: AnyPublisher<User?, Never> { get }
    
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, fullName: String) async throws -> User
    func signOut() async throws
    func resetPassword(email: String) async throws
    func refreshToken() async throws
}

protocol ClassServiceProtocol {
    func getClasses(filter: ClassFilter?) async throws -> [ClassModel]
    func getClass(by id: String) async throws -> ClassModel
    func searchClasses(query: String) async throws -> [ClassModel]
    func getFeaturedClasses() async throws -> [ClassModel]
    func getClassesByCategory(_ category: ClassCategory) async throws -> [ClassModel]
    func getClassesByInstructor(_ instructorId: String) async throws -> [ClassModel]
}

protocol BookingServiceProtocol {
    func createBooking(for classId: String, spots: Int) async throws -> BookingModel
    func getBookings(for userId: String) async throws -> [BookingModel]
    func getBooking(by id: String) async throws -> BookingModel
    func cancelBooking(_ bookingId: String) async throws
    func modifyBooking(_ bookingId: String, newSpots: Int) async throws -> BookingModel
    func getUpcomingBookings() async throws -> [BookingModel]
    func getPastBookings() async throws -> [BookingModel]
}

protocol UserServiceProtocol {
    func getProfile() async throws -> UserProfile
    func updateProfile(_ profile: UserProfile) async throws -> UserProfile
    func uploadProfileImage(_ imageData: Data) async throws -> URL
    func deleteAccount() async throws
    func getPreferences() async throws -> UserPreferences
    func updatePreferences(_ preferences: UserPreferences) async throws
}

protocol PaymentServiceProtocol {
    func processPayment(amount: Double, paymentMethod: PaymentMethod) async throws -> PaymentResult
    func addPaymentMethod(_ method: PaymentMethod) async throws
    func getPaymentMethods() async throws -> [PaymentMethod]
    func removePaymentMethod(_ methodId: String) async throws
    func getPaymentHistory() async throws -> [PaymentTransaction]
}

// MARK: - Alpha Testing Service Protocols

protocol CrashReportingServiceProtocol {
    func initialize()
    func recordError(_ error: Error, context: [String: Any]?)
    func recordFatalError(_ error: Error, context: [String: Any]?)
    func logMessage(_ message: String, level: LogLevel)
    func setUserIdentifier(_ userId: String?)
    func setCustomValue(_ value: Any, forKey key: String)
    func recordBreadcrumb(_ breadcrumb: String, metadata: [String: Any]?)
}

protocol FeedbackServiceProtocol {
    var currentFeedbackType: FeedbackType { get set }
    
    func submitFeedback(_ feedback: FeedbackModel) async throws
    func reportBug(_ bug: BugReport) async throws
    func suggestFeature(_ feature: FeatureRequest) async throws
    func rateExperience(_ rating: ExperienceRating) async throws
    func reportError(_ error: AppError?) 
    func attachScreenshot(_ imageData: Data, to feedbackId: String) async throws
    func getFeedbackHistory() async throws -> [FeedbackModel]
}

protocol AnalyticsServiceProtocol {
    func trackEvent(_ event: AnalyticsEvent, parameters: [String: Any]?)
    func trackScreen(_ screen: String, parameters: [String: Any]?)
    func trackUserProperty(_ property: String, value: Any)
    func trackAppLaunch()
    func trackPurchase(amount: Double, currency: String, items: [String])
    func trackBookingFlow(step: BookingFlowStep, classId: String)
    func trackError(_ error: Error, context: [String: Any]?)
}

protocol TestFlightServiceProtocol {
    var isTestFlightBuild: Bool { get }
    var testFlightVersion: String? { get }
    
    func checkForUpdates() async throws -> TestFlightUpdate?
    func getTestFlightMetadata() -> TestFlightMetadata
    func submitTestFlightFeedback(_ feedback: String) async throws
    func trackTestFlightEvent(_ event: String, metadata: [String: Any]?)
}

// MARK: - Support Service Protocols

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func upload(_ data: Data, to endpoint: Endpoint) async throws -> URL
    func download(from url: URL) async throws -> Data
    func webSocket(_ endpoint: Endpoint) -> AsyncStream<WebSocketMessage>
}

protocol StorageServiceProtocol {
    func save<T: Codable>(_ object: T, key: String) throws
    func load<T: Codable>(_ type: T.Type, key: String) throws -> T?
    func delete(key: String) throws
    func clearAll() throws
}

protocol CacheServiceProtocol {
    func cache<T: Codable>(_ object: T, key: String, expiration: TimeInterval?)
    func retrieve<T: Codable>(_ type: T.Type, key: String) -> T?
    func invalidate(key: String)
    func invalidateAll()
    func isExpired(key: String) -> Bool
}

protocol NotificationServiceProtocol {
    func requestAuthorization() async throws -> Bool
    func scheduleNotification(_ notification: LocalNotification) throws
    func cancelNotification(identifier: String)
    func cancelAllNotifications()
    func getPendingNotifications() async -> [LocalNotification]
}

// MARK: - Supporting Types

enum LogLevel: String {
    case verbose, debug, info, warning, error, fatal
}

enum FeedbackType {
    case bug, feature, rating, general
}

enum BookingFlowStep: String {
    case selectClass = "select_class"
    case chooseTime = "choose_time"
    case selectSpots = "select_spots"
    case enterDetails = "enter_details"
    case payment = "payment"
    case confirmation = "confirmation"
}

struct AnalyticsEvent {
    let name: String
    let category: String
    let action: String?
    let label: String?
    let value: Double?
}

struct TestFlightUpdate {
    let version: String
    let buildNumber: String
    let releaseNotes: String
    let isMandatory: Bool
}

struct TestFlightMetadata {
    let version: String
    let buildNumber: String
    let installDate: Date
    let testerEmail: String?
    let testerId: String?
}

struct LocalNotification {
    let identifier: String
    let title: String
    let body: String
    let triggerDate: Date
    let userInfo: [String: Any]?
}

struct WebSocketMessage {
    enum MessageType {
        case text(String)
        case data(Data)
        case error(Error)
        case connected
        case disconnected
    }
    
    let type: MessageType
    let timestamp: Date
}