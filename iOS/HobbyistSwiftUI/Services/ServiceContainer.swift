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
    
    // Convenience accessors for legacy code
    var authService: AuthenticationManager? { authManager }
    var dataService: DataService? { nil } // To be implemented if needed
    var notificationService: NotificationService? { nil } // To be implemented if needed
    var appCoordinator: AppCoordinator? { nil } // To be implemented if needed
    
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

final class CrashReportingService {
    func recordError(_ error: Error, context: [String: Any]? = nil) {
        // Log to console in debug mode
        #if DEBUG
        print("🚨 Error recorded: \(error)")
        if let context = context {
            print("Context: \(context)")
        }
        #endif
        
        // TODO: Integrate with crash reporting service (Sentry, etc.)
        // For now, just log locally
    }
    
    func log(_ message: String) {
        #if DEBUG
        print("📝 Log: \(message)")
        #endif
        // TODO: Send to logging service
    }
    
    func setUserIdentifier(_ userId: String) {
        #if DEBUG
        print("👤 User ID set: \(userId)")
        #endif
        // TODO: Set user context in crash reporting
    }
    
    func setCustomValue(_ value: Any, forKey key: String) {
        #if DEBUG
        print("🏷️ Custom value set: \(key) = \(value)")
        #endif
        // TODO: Set custom values in crash reporting
    }
}
