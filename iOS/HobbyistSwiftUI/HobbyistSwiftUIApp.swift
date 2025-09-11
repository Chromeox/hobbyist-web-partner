import SwiftUI
import Supabase
import UserNotifications

// MARK: - Type Aliases
typealias ClassModel = HobbyClass

@main
struct HobbyistSwiftUIApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var navigationManager = NavigationManager.shared
    @StateObject private var errorHandler = ErrorHandler()
    @StateObject private var notificationManager = NotificationManager()
    
    init() {
        // Initialize Supabase configuration first
        initializeSupabase()
        
        // Configure app appearance
        configureAppearance()
        
        // Setup service container
        ServiceContainer.shared.configure()
        
        // Migrate any old configuration
        SecureConfigurationLoader.migrateConfiguration()
    }
    
    private func initializeSupabase() {
        // Ensure configuration is loaded
        let appConfig = AppConfiguration.shared
        
        if !appConfig.validateConfiguration() {
            #if DEBUG
            print("⚠️ Supabase configuration validation failed. Please check Config-Dev.plist")
            #else
            fatalError("Invalid Supabase configuration")
            #endif
        } else {
            print("✅ Supabase configuration loaded successfully")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(navigationManager)
                .environmentObject(errorHandler)
                .onAppear {
                    setupInitialState()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .alert("Error", isPresented: $errorHandler.showErrorAlert) {
                    Button("OK") {
                        errorHandler.clearError()
                    }
                } message: {
                    Text(errorHandler.currentError?.localizedDescription ?? "An unknown error occurred")
                }
        }
    }
    
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func setupInitialState() {
        // Request notification permissions
        notificationManager.requestAuthorization()
        
        // Check authentication state
        authManager.checkAuthenticationState()
        
        // Initialize analytics
        ServiceContainer.shared.analyticsService.trackAppLaunch()
        
        // Setup crash reporting user context
        if let userId = authManager.currentUser?.id {
            ServiceContainer.shared.crashReportingService.setUserIdentifier(userId)
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Handle deep links for TestFlight invitations, class bookings, etc.
        navigationManager.handleDeepLink(url)
    }
}

// MARK: - App Coordinator

class AppCoordinator: ObservableObject {
    @Published var currentTab: MainTab = .home
    @Published var selectedClass: ClassModel?
    @Published var showBookingFlow = false
    @Published var showFeedback = false
    @Published var pendingDeepLink: URL?
    
    enum MainTab: String, CaseIterable {
        case home = "Home"
        case search = "Search"
        case bookings = "Bookings"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .search: return "magnifyingglass"
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
                    self.selectedClass = classModel
                    self.showBookingFlow = true
                }
            } catch {
                ServiceContainer.shared.crashReportingService.recordError(error, context: ["action": "deep_link_class_load", "class_id": classId])
            }
        }
    }
}

// MARK: - Error Handler

class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showErrorAlert = false
    
    func handle(_ error: Error, context: [String: Any]? = nil) {
        // Log to crash reporting
        ServiceContainer.shared.crashReportingService.recordError(error, context: context)
        
        // Convert to app error
        if let appError = error as? AppError {
            currentError = appError
        } else {
            currentError = AppError.unknown(error.localizedDescription)
        }
        
        showErrorAlert = true
    }
    
    func clearError() {
        currentError = nil
        showErrorAlert = false
    }
}

// MARK: - Notification Manager

class NotificationManager: ObservableObject {
    @Published var hasNotificationPermission = false
    @Published var pendingNotifications: [NotificationModel] = []
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.hasNotificationPermission = granted
                
                if let error = error {
                    ServiceContainer.shared.crashReportingService.recordError(error, context: ["action": "notification_permission"])
                }
            }
        }
    }
    
    func scheduleClassReminder(for classModel: ClassModel) {
        guard hasNotificationPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Class Reminder"
        content.body = "Your \(classModel.title) class starts in 1 hour"
        content.sound = .default
        content.categoryIdentifier = "CLASS_REMINDER"
        content.userInfo = ["class_id": classModel.id]
        
        // Schedule 1 hour before class
        if let triggerDate = Calendar.current.date(byAdding: .hour, value: -1, to: classModel.startTime) {
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate), repeats: false)
            
            let request = UNNotificationRequest(identifier: "class_\(classModel.id)", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    ServiceContainer.shared.crashReportingService.recordError(error, context: ["action": "schedule_notification", "class_id": classModel.id])
                }
            }
        }
    }
}

// MARK: - UIDevice Extension

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

// MARK: - Notification Model

struct NotificationModel: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let timestamp: Date
    let type: NotificationType
    let metadata: [String: Any]?
    
    enum NotificationType {
        case classReminder
        case bookingConfirmation
        case promotionalOffer
        case systemUpdate
    }
}