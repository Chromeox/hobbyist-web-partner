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
    
    private init() {}
    
    func configure() {
        setupSupabase()
        setupServices()
    }
    
    private func setupSupabase() {
        guard let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? getDefaultSupabaseURL(),
              let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? getDefaultSupabaseKey() else {
            fatalError("Missing Supabase configuration")
        }
        
        supabaseClient = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
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
    
    private func getDefaultSupabaseURL() -> String? {
        #if DEBUG
        return "https://mcjqvdzdhtcvbrejvrtp.supabase.co"
        #else
        return nil
        #endif
    }
    
    private func getDefaultSupabaseKey() -> String? {
        #if DEBUG
        // This is the anon key (safe for client-side)
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1janF2ZHpkaHRjdmJyZWp2cnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjMwOTI4MzMsImV4cCI6MjAzODY2ODgzM30.example"
        #else
        return nil
        #endif
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
        Crashlytics.crashlytics().record(error: error)
        
        if let context = context {
            for (key, value) in context {
                Crashlytics.crashlytics().setCustomValue(value, forKey: key)
            }
        }
    }
    
    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
    
    func setUserIdentifier(_ userId: String) {
        Crashlytics.crashlytics().setUserID(userId)
    }
    
    func setCustomValue(_ value: Any, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
}
