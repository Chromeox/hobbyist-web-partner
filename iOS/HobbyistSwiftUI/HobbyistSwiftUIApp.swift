import SwiftUI

@main
struct HobbyistSwiftUIApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var navigationManager = NavigationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(navigationManager)
        }
    }
}

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    func login(email: String, password: String) async throws {
        // Will integrate with Supabase auth
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
    }
}

class NavigationManager: ObservableObject {
    @Published var selectedTab = 0
    @Published var navigationPath = NavigationPath()
    
    func navigateToHome() {
        selectedTab = 0
        navigationPath = NavigationPath()
    }
}