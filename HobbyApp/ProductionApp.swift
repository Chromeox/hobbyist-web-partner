import SwiftUI

// Production-ready app entry point
// This is now the main entry point for the production app
@main
struct ProductionHobbyistApp: App {
    @StateObject private var supabaseService = SimpleSupabaseService.shared

    var body: some Scene {
        WindowGroup {
            ProductionContentView()
                .environmentObject(supabaseService)
                .onAppear {
                    configureAppAppearance()
                }
        }
    }

    private func configureAppAppearance() {
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

        print("✅ Production app appearance configured")
    }
}

struct ProductionContentView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @StateObject private var featureFlagManager = FeatureFlagManager.shared
    @State private var showOnboarding = false
    @State private var hasCompletedOnboarding = false
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if showOnboarding {
                // Use new modular onboarding if feature flag is enabled
                if featureFlagManager.isEnabled(.onboardingModule) {
                    OnboardingCoordinator {
                        showOnboarding = false
                        hasCompletedOnboarding = true
                    }
                } else {
                    // Fallback to original onboarding
                    ProductionOnboardingView {
                        showOnboarding = false
                        hasCompletedOnboarding = true
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    }
                }
            } else if supabaseService.isAuthenticated {
                ProductionMainTabView()
            } else {
                ProductionLoginView()
            }
        }
        .onAppear {
            initializeApp()
        }
    }

    private func initializeApp() {
        // Show loading screen for minimum 2.5 seconds for branding
        Task {
            // Initialize services and check authentication in parallel
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    // Minimum loading time for branding
                    try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
                }

                group.addTask {
                    // Check onboarding status
                    await checkOnboardingStatus()
                }
            }

            // Update UI on main thread
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func checkOnboardingStatus() async {
        await MainActor.run {
            hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

            // Show onboarding for first-time users
            if !hasCompletedOnboarding && supabaseService.isAuthenticated {
                showOnboarding = true
            }
        }
    }
}

struct ProductionOnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    private let totalPages = 3

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "figure.yoga",
                    title: "Discover Your Passion",
                    subtitle: "Explore hundreds of hobby classes",
                    description: "From pottery to yoga, cooking to dance - find your next adventure with expert instructors in Vancouver."
                )
                .tag(0)

                OnboardingPage(
                    icon: "calendar.badge.plus",
                    title: "Book with Confidence",
                    subtitle: "Simple scheduling made easy",
                    description: "Secure booking, instant confirmations, and flexible scheduling. Manage all your classes in one place."
                )
                .tag(1)

                OnboardingPage(
                    icon: "heart.circle.fill",
                    title: "Your Hobby Journey",
                    subtitle: "Track progress & connect",
                    description: "Save favorites, write reviews, and join a community of passionate learners on their hobby journey."
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            VStack(spacing: 24) {
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }

                // Navigation
                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation { currentPage -= 1 }
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    if currentPage < totalPages - 1 {
                        Button("Next") {
                            withAnimation { currentPage += 1 }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    } else {
                        Button("Get Started") {
                            onComplete()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 50)
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }
}

struct ProductionLoginView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var fullName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    Image(systemName: "figure.yoga")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("Hobbyist")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Discover your next passion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Form
                VStack(spacing: 16) {
                    if isSignUp {
                        TextField("Full Name", text: $fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.name)
                    }

                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                }
                .padding(.horizontal)

                // Action Button
                Button(isSignUp ? "Create Account" : "Sign In") {
                    Task {
                        if isSignUp {
                            await supabaseService.signUp(
                                email: email,
                                password: password,
                                fullName: fullName
                            )
                        } else {
                            await supabaseService.signIn(
                                email: email,
                                password: password
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(formIsValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(supabaseService.isLoading || !formIsValid)
                .padding(.horizontal)

                // Toggle
                Button(isSignUp ? "Already have an account? Sign In" : "Need an account? Sign Up") {
                    isSignUp.toggle()
                    fullName = ""
                }
                .foregroundColor(.blue)

                if supabaseService.isLoading {
                    ProgressView(isSignUp ? "Creating account..." : "Signing in...")
                        .padding()
                }

                Spacer()
            }
            .padding()
        }
    }

    private var formIsValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !fullName.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
}

struct ProductionMainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ProductionHomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "magnifyingglass" : "magnifyingglass")
                    Text("Search")
                }
                .tag(1)

            BookingsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "calendar" : "calendar")
                    Text("Bookings")
                }
                .tag(2)

            ProductionProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

struct ProductionHomeView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back,")
                                    .font(.title2)
                                    .foregroundColor(.secondary)

                                Text(supabaseService.currentUser?.name ?? "Hobbyist")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                            }

                            Spacer()

                            Button(action: {}) {
                                Image(systemName: "bell")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Quick Stats
                    HStack(spacing: 16) {
                        StatCard(icon: "calendar", value: "3", label: "Upcoming", color: .blue)
                        StatCard(icon: "star.fill", value: "12", label: "Completed", color: .yellow)
                    }
                    .padding(.horizontal)

                    // Featured Classes
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Featured Classes")
                                .font(.title3)
                                .fontWeight(.semibold)

                            Spacer()

                            Button("See All") {}
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<3, id: \.self) { _ in
                                    FeaturedClassCard()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            QuickActionButton(icon: "magnifyingglass", title: "Browse Classes", color: .blue)
                            QuickActionButton(icon: "calendar.badge.plus", title: "My Bookings", color: .purple)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FeaturedClassCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.6), .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 200, height: 120)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "figure.yoga")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Morning Yoga")
                    .font(.headline)

                Text("with Sarah Johnson")
                    .font(.subheadline)
                    .foregroundColor(.blue)

                Text("$25")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 200)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct ProductionProfileView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @StateObject private var featureFlagManager = FeatureFlagManager.shared

    var body: some View {
        Group {
            if featureFlagManager.isEnabled(.profileModule) {
                // Use new modular profile system
                ProfileCoordinator()
            } else {
                // Fallback to original profile view
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile Header
                            VStack(spacing: 16) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.blue)

                                VStack(spacing: 4) {
                                    Text(supabaseService.currentUser?.name ?? "User")
                                        .font(.title2)
                                        .fontWeight(.bold)

                                    Text(supabaseService.currentUser?.email ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Profile Menu
                            VStack(spacing: 16) {
                                ProfileMenuItem(icon: "person.crop.circle", title: "Edit Profile")
                                ProfileMenuItem(icon: "calendar", title: "My Bookings")
                                ProfileMenuItem(icon: "heart", title: "Favorites")
                                ProfileMenuItem(icon: "gear", title: "Settings")
                                ProfileMenuItem(icon: "questionmark.circle", title: "Help & Support")
                            }
                            .padding(.horizontal)

                            // Sign Out
                            Button("Sign Out") {
                                Task {
                                    await supabaseService.signOut()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.large)
                }
            }
        }
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String

    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 32)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2)
        }
    }
}

#Preview("Production App") {
    ProductionContentView()
        .environmentObject(SimpleSupabaseService.shared)
}

#Preview("Onboarding") {
    ProductionOnboardingView(onComplete: {})
}

#Preview("Login") {
    ProductionLoginView()
        .environmentObject(SimpleSupabaseService.shared)
}