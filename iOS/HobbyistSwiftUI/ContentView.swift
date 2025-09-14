import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // User is logged in - show main app
                MainTabView()
            } else {
                // User not logged in - show authentication flow
                if shouldShowOnboarding {
                    OnboardingView()
                } else {
                    LoginView()
                }
            }
        }
        .onAppear {
            checkOnboardingStatus()
        }
    }

    private var shouldShowOnboarding: Bool {
        // Check if user has completed onboarding
        !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    private func checkOnboardingStatus() {
        // This could be expanded to check server-side onboarding status
        showOnboarding = shouldShowOnboarding
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(NavigationManager.shared)
}