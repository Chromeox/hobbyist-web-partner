import SwiftUI

struct ContentView: View {
    @StateObject private var supabaseService = SimpleSupabaseService.shared
    @State private var isLoggedIn = false
    @State private var needsOnboarding = false
    @State private var isCheckingStatus = true

    var body: some View {
        Group {
            if isCheckingStatus {
                // Loading state while checking authentication and onboarding
                ProgressView("Loading HobbyApp...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            } else if !isLoggedIn {
                // User not authenticated - show login/signup
                LoginView(onLoginSuccess: { isNewUser in
                    isLoggedIn = true
                    needsOnboarding = isNewUser
                })
                .environmentObject(supabaseService)
            } else if needsOnboarding {
                // User authenticated but needs onboarding - temporary simple view
                VStack(spacing: 24) {
                    Text("Welcome to HobbyApp!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Let's get you set up")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Button("Complete Setup") {
                        // For now, just mark as complete
                        needsOnboarding = false
                        UserDefaults.standard.set(true, forKey: "hobbyist_onboarding_completed")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                // User authenticated and onboarded - show main app
                MainTabView()
                    .environmentObject(supabaseService)
            }
        }
        .onAppear {
            checkAuthenticationAndOnboarding()
        }
    }

    private func checkAuthenticationAndOnboarding() {
        Task {
            // Check authentication
            isLoggedIn = supabaseService.isAuthenticated

            if isLoggedIn {
                // Check if onboarding is needed - simplified check
                needsOnboarding = !UserDefaults.standard.bool(forKey: "hobbyist_onboarding_completed")
            }

            isCheckingStatus = false
        }
    }
}

#Preview {
    ContentView()
}