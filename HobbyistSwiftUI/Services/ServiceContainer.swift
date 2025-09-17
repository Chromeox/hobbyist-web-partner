import Foundation
import Supabase

final class ServiceContainer {
    static let shared = ServiceContainer()
    
    private(set) var supabaseClient: SupabaseClient!
    private(set) var authManager: AuthenticationManager!
    private(set) var userService: UserService!
    private(set) var classService: ClassService!
    private(set) var bookingService: BookingService?  // Optional until implemented
    private(set) var paymentService: PaymentService?  // Optional until implemented
    // private(set) var creditService: CreditService?    // Temporarily disabled
    private(set) var analyticsService: ContainerAnalyticsService!
    private(set) var crashReportingService: CrashReportingService!
    private(set) var cacheService: CacheService!
    private(set) var networkMonitor: NetworkMonitor!
    private(set) var notificationService: NotificationService!
    private(set) var dataService: DataService?        // Optional until implemented
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
        classService = ClassService.shared  // Use existing singleton

        // TODO: Initialize these services when they're properly implemented
        // bookingService = BookingService(supabase: supabaseClient)
        // paymentService = PaymentService(supabase: supabaseClient)
        // creditService = CreditService(supabase: supabaseClient)
        // dataService = DataService(supabase: supabaseClient)

        // Support services
        analyticsService = ContainerAnalyticsService()
        crashReportingService = CrashReportingService()
        cacheService = CacheService()
        networkMonitor = NetworkMonitor()
        notificationService = NotificationService()
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

final class ContainerAnalyticsService {
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

// CrashReportingService implementation is in CrashReportingService.swift

// MARK: - App Coordinator

final class AppCoordinator: ObservableObject {
    @Published var currentTab: MainTab = .home
    @Published var selectedClass: String? // ClassModel?
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
