import Foundation
import Supabase

final class ServiceContainer {
    static let shared = ServiceContainer()
    
    private(set) var supabaseClient: SupabaseClient!
    private(set) var authManager: AuthenticationManager!
    private(set) var userService: UserService!
    private(set) var classService: ClassService!
    private(set) var bookingService: BookingService!
    private(set) var paymentService: PaymentService!
    private(set) var creditService: CreditService!
    private(set) var analyticsService: AnalyticsService!
    private(set) var crashReportingService: CrashReportingService!
    private(set) var cacheService: CacheService!
    private(set) var networkMonitor: NetworkMonitor!
    private(set) var notificationService: NotificationService!
    private(set) var dataService: DataService!
    private(set) var appCoordinator: AppCoordinator!
    
    // Convenience accessors for legacy code
    var authService: AuthenticationManager? { authManager }
    
    private init() {}
    
    func configure() {
        setupSupabase()
        setupServices()
    }
    
    private func setupSupabase() {
        // Use the secure configuration system
        guard let config = AppConfiguration.shared.current else {
            fatalError("Supabase configuration not loaded. Please check Config-Dev.plist")
        }
        
        guard let url = URL(string: config.supabaseURL) else {
            fatalError("Invalid Supabase URL: \(config.supabaseURL)")
        }
        
        supabaseClient = SupabaseClient(
            supabaseURL: url,
            supabaseKey: config.supabaseAnonKey
        )
        
        print("✅ Supabase client initialized with URL: \(config.supabaseURL)")
    }
    
    private func setupServices() {
        // Core services
        authManager = AuthenticationManager.shared
        userService = UserService(supabase: supabaseClient)
        classService = ClassService(supabase: supabaseClient)
        bookingService = BookingService(supabase: supabaseClient)
        paymentService = PaymentService(supabase: supabaseClient)
        creditService = CreditService(supabase: supabaseClient)
        
        // Support services
        analyticsService = AnalyticsService()
        crashReportingService = CrashReportingService()
        cacheService = CacheService()
        networkMonitor = NetworkMonitor()
        notificationService = NotificationService()
        dataService = DataService(supabase: supabaseClient)
        appCoordinator = AppCoordinator()
        
        // Start monitoring
        networkMonitor.startMonitoring()
    }
}

// MARK: - Network Monitor

final class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType = ConnectionType.unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case unknown
    }
    
    func startMonitoring() {
        // Network monitoring implementation
    }
    
    func stopMonitoring() {
        // Stop monitoring
    }
}

// MARK: - Cache Service

final class CacheService {
    private let cache = NSCache<NSString, AnyObject>()
    private let imageCache = NSCache<NSString, NSData>()
    
    func set(_ object: AnyObject, forKey key: String) {
        cache.setObject(object, forKey: key as NSString)
    }
    
    func get(forKey key: String) -> AnyObject? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ data: Data, forKey key: String) {
        imageCache.setObject(data as NSData, forKey: key as NSString)
    }
    
    func getImage(forKey key: String) -> Data? {
        return imageCache.object(forKey: key as NSString) as Data?
    }
    
    func clearAll() {
        cache.removeAllObjects()
        imageCache.removeAllObjects()
    }
}

// MARK: - Analytics Service

final class AnalyticsService {
    func trackEvent(_ name: String, parameters: [String: Any]? = nil) {
        // Analytics implementation
        #if DEBUG
        print("📊 Analytics Event: \(name)", parameters ?? [:])
        #endif
    }
    
    func trackScreen(_ name: String) {
        trackEvent("screen_view", parameters: ["screen_name": name])
    }
    
    func trackAppLaunch() {
        trackEvent("app_launch", parameters: [
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        ])
    }
}

// MARK: - Crash Reporting Service

import Sentry

final class CrashReportingService {
    private var isInitialized = false
    
    init() {
        initializeSentry()
    }
    
    private func initializeSentry() {
        SentrySDK.start { options in
            options.dsn = "https://your-sentry-dsn@sentry.io/project-id" // TODO: Replace with actual DSN
            options.environment = AppConfiguration.shared.isProduction ? "production" : "development"
            options.enableCrashHandler = true
            options.enableMetricKit = true
            options.enableWatchdogTerminationTracking = true
            options.enableAppHangTracking = true
            options.enableNetworkTracking = true
            options.enableFileIOTracking = true
            options.enableUserInteractionTracing = true
            options.enableUIViewControllerTracking = true
            options.enableNetworkBreadcrumbs = true
            options.enableAutoBreadcrumbTracking = true
            options.attachStacktrace = true
            options.enableAutoSessionTracking = true
            
            // Set sample rates
            options.tracesSampleRate = AppConfiguration.shared.isProduction ? 0.1 : 1.0
            options.profilesSampleRate = AppConfiguration.shared.isProduction ? 0.1 : 1.0
            
            #if DEBUG
            options.debug = true
            #endif
        }
        isInitialized = true
    }
    
    func recordError(_ error: Error, context: [String: Any]? = nil) {
        // Log to console in debug mode
        #if DEBUG
        print("🚨 Error recorded: \(error)")
        if let context = context {
            print("Context: \(context)")
        }
        #endif
        
        if isInitialized {
            SentrySDK.capture(error: error) { scope in
                if let context = context {
                    for (key, value) in context {
                        scope.setContext(value: [key: value], key: "custom_context")
                    }
                }
            }
        }
    }
    
    func log(_ message: String) {
        #if DEBUG
        print("📝 Log: \(message)")
        #endif
        
        if isInitialized {
            SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "app.log", message: message))
        }
    }
    
    func setUserID(_ userId: String) {
        #if DEBUG
        print("👤 User ID set: \(userId)")
        #endif
        
        if isInitialized {
            SentrySDK.setUser(Sentry.User(userId: userId))
        }
    }
    
    func setUserIdentifier(_ userId: String) {
        setUserID(userId)
    }
    
    func setCustomValue(_ value: Any, forKey key: String) {
        #if DEBUG
        print("🏷️ Custom value set: \(key) = \(value)")
        #endif
        
        if isInitialized {
            SentrySDK.setTag(value: "\(value)", key: key)
        }
    }
    
    func recordPerformance(operationName: String, description: String? = nil, operation: () throws -> Void) rethrows {
        if isInitialized {
            let transaction = SentrySDK.startTransaction(name: operationName, operation: "performance")
            if let description = description {
                transaction.setData(value: description, key: "description")
            }
            
            do {
                try operation()
                transaction.finish(status: .ok)
            } catch {
                transaction.finish(status: .internalError)
                recordError(error, context: ["operation": operationName])
                throw error
            }
        } else {
            try operation()
        }
    }
}

// MARK: - App Coordinator

final class AppCoordinator: ObservableObject {
    @Published var currentTab: MainTab = .home
    @Published var selectedClass: ClassModel?
    @Published var showBookingFlow = false
    @Published var showFeedback = false
    @Published var pendingDeepLink: URL?
    
    enum MainTab: String, CaseIterable {
        case home = "Home"
        case discover = "Discover"
        case bookings = "Bookings"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .discover: return "magnifyingglass"
            case .bookings: return "calendar"
            case .profile: return "person.fill"
            }
        }
    }
    
    func handleDeepLink(_ url: URL) {
        // Parse and handle deep links
        pendingDeepLink = url
        
        if url.pathComponents.contains("class") {
            // Handle class deep link
            if let classId = url.pathComponents.last {
                loadAndShowClass(classId: classId)
            }
        } else if url.pathComponents.contains("booking") {
            // Handle booking deep link
            currentTab = .bookings
        } else if url.pathComponents.contains("feedback") {
            // Show feedback form
            showFeedback = true
        }
    }
    
    private func loadAndShowClass(classId: String) {
        Task {
            do {
                let classModel = try await ServiceContainer.shared.classService.getClass(by: classId)
                await MainActor.run {
                    // Convert to ClassModel if needed
                    // self.selectedClass = classModel
                    self.showBookingFlow = true
                }
            } catch {
                ServiceContainer.shared.crashReportingService.recordError(error, context: ["action": "deep_link_class_load", "class_id": classId])
            }
        }
    }
}
