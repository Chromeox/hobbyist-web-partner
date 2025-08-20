import SwiftUI
import Supabase

@main
struct HobbyistApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var serviceContainer = ServiceContainer.shared
    
    init() {
        setupSupabase()
        configureServices()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(serviceContainer)
                .onAppear {
                    Task {
                        await authManager.checkAuthStatus()
                    }
                }
        }
    }
    
    private func setupSupabase() {
        // Initialize Supabase client with configuration
        let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
        
        if !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty {
            SupabaseManager.shared.initialize(url: supabaseURL, key: supabaseAnonKey)
        }
    }
    
    private func configureServices() {
        // Register all services in the dependency injection container
        serviceContainer.register(AuthServiceProtocol.self, AuthService())
        serviceContainer.register(DataServiceProtocol.self, DataService())
        serviceContainer.register(PaymentServiceProtocol.self, PaymentService())
        serviceContainer.register(NotificationServiceProtocol.self, NotificationService())
        serviceContainer.register(GamificationServiceProtocol.self, GamificationService())
    }
}