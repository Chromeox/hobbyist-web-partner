import SwiftUI

// MARK: - Brand Constants

struct BrandConstants {
    struct Colors {
        static let primary = Color("BrandPrimary")
        static let teal = Color("BrandTeal")
        static let coral = Color("BrandCoral")
        static let gradientStart = Color("LandingGradientStart")
        static let gradientEnd = Color("LandingGradientEnd")
    }

    struct Typography {
        static let heroTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 18, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .medium)
        static let caption = Font.system(size: 13, weight: .medium)
    }

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
    }

    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
    }

    struct Gradients {
        static let landing = LinearGradient(
            colors: [Colors.gradientStart, Colors.gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let primary = LinearGradient(
            colors: [Colors.primary, Colors.primary.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let darkBackground = LinearGradient(
            colors: [
                Color(hex: "#1a1a2e"),
                Color(hex: "#16213e"),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Category Colors

struct CategoryColors {
    static let ceramics = Color(hex: "#D97757")      // Warm terracotta/clay
    static let cooking = Color(hex: "#E8B44C")       // Golden yellow
    static let arts = Color(hex: "#B565D8")          // Rich purple
    static let photography = Color(hex: "#4A90E2")   // Sky blue
    static let music = Color(hex: "#52B788")         // Forest green
    static let movement = Color(hex: "#E63946")      // Vibrant red/pink
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView: View {
    @StateObject private var supabaseService = SimpleSupabaseService.shared
    @StateObject private var hapticService = HapticFeedbackService.shared
    @StateObject private var creditService = CreditService.shared
    @State private var isLoggedIn = false
    @State private var needsOnboarding = false
    @State private var isCheckingStatus = true
    @State private var showWelcomeLanding = true
    @State private var isGuestMode = false

    var body: some View {
        ZStack {
            if isCheckingStatus {
                // Enhanced loading splash screen
                SplashView()
            } else if showWelcomeLanding && !isLoggedIn {
                // First time user - show welcome landing page
                WelcomeLandingView(
                    onGetStarted: {
                        UserDefaults.standard.set(true, forKey: "hobbyist_has_seen_landing")
                        withAnimation(BrandConstants.Animation.spring) {
                            showWelcomeLanding = false
                        }
                    },
                    onContinueAsGuest: {
                        UserDefaults.standard.set(true, forKey: "hobbyist_has_seen_landing")
                        isGuestMode = true
                        showWelcomeLanding = false
                    }
                )
            } else if !showWelcomeLanding && !isLoggedIn && !isGuestMode {
                // User tapped Get Started - show login/signup
                LoginView(onLoginSuccess: { isNewUser in
                    isLoggedIn = true
                    needsOnboarding = isNewUser
                })
                .environmentObject(supabaseService)
            } else if isGuestMode {
                // Guest mode - limited app access
                MainTabView()
                    .environmentObject(supabaseService)
                    .environmentObject(hapticService)
                    .environmentObject(creditService)
            } else if needsOnboarding {
                // User authenticated but needs onboarding - show enhanced onboarding flow
                EnhancedOnboardingFlow(onComplete: {
                    needsOnboarding = false
                    UserDefaults.standard.set(true, forKey: "hobbyist_onboarding_completed")
                })
                .environmentObject(supabaseService)
                .environmentObject(hapticService)
            } else {
                // User authenticated and onboarded - show main app
                MainTabView()
                    .environmentObject(supabaseService)
                    .environmentObject(hapticService)
                    .environmentObject(creditService)
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
                // Skip landing page for logged in users
                showWelcomeLanding = false

                // Check if onboarding is needed from Supabase backend
                if let userPreferences = await supabaseService.fetchUserPreferences(),
                   let onboardingCompleted = userPreferences["onboarding_completed"] as? Bool,
                   onboardingCompleted {
                    needsOnboarding = false
                } else {
                    // No preferences found or onboarding not completed - show onboarding
                    needsOnboarding = true
                }
            } else {
                // Check if user has seen landing page before
                let hasSeenLanding = UserDefaults.standard.bool(forKey: "hobbyist_has_seen_landing")
                if hasSeenLanding {
                    showWelcomeLanding = false
                }
            }

            isCheckingStatus = false
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Background gradient
            BrandConstants.Gradients.landing
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // App icon placeholder with animation
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)

                    Image(systemName: "figure.yoga")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.white)
                        .scaleEffect(scale)
                }

                Text("HobbyApp")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)

                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                    .padding(.top, 8)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - Enhanced Onboarding Flow

// MARK: - Branded UI Components

/// Primary branded button with gradient background
struct BrandedButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(BrandConstants.Gradients.primary)
            .cornerRadius(20)
        }
    }
}

/// Secondary outline button
struct OutlineButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(BrandConstants.Colors.primary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(BrandConstants.Colors.primary, lineWidth: 2)
            )
        }
    }
}

/// Text button style
struct TextButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(BrandConstants.Colors.primary)
                .underline()
        }
    }
}

/// Speech bubble component
struct SpeechBubble: View {
    let text: String
    let alignment: Alignment

    init(_ text: String, alignment: Alignment = .leading) {
        self.text = text
        self.alignment = alignment
    }

    var body: some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.black.opacity(0.85)))
    }
}

// MARK: - Welcome Landing View

struct WelcomeLandingView: View {
    @State private var showContent = false
    @State private var heroOffset: CGFloat = 0
    @State private var showFeatures = false

    let onGetStarted: () -> Void
    let onContinueAsGuest: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            BrandConstants.Gradients.landing
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    // Hero Section
                    VStack(spacing: 32) {
                        // Hero placeholder (will use image when available)
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 280, height: 280)

                            Image(systemName: "figure.yoga")
                                .font(.system(size: 120, weight: .light))
                                .foregroundColor(.white)
                        }
                        .frame(height: 320)
                        .offset(y: heroOffset)
                        .onAppear {
                            withAnimation(
                                Animation.easeInOut(duration: 2.5)
                                    .repeatForever(autoreverses: true)
                            ) {
                                heroOffset = -8
                            }
                        }

                        // Speech Bubbles
                        HStack(spacing: 40) {
                            SpeechBubble("Let's create!", alignment: .leading)
                            Spacer()
                            SpeechBubble("Let's go!", alignment: .trailing)
                        }
                        .padding(.horizontal, 40)
                        .offset(y: -20)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    Spacer(minLength: 40)

                    // Content Card
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Text("Start Creating Now 🚀")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)

                            Text("Discover Vancouver's most creative hobby classes and connect with a community of passionate learners.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        VStack(spacing: 12) {
                            BrandedButton("Get Started", icon: "arrow.right.circle.fill") {
                                onGetStarted()
                            }

                            OutlineButton("Learn More", icon: "info.circle") {
                                withAnimation {
                                    showFeatures = true
                                }
                            }

                            TextButton(title: "Continue as Guest") {
                                onContinueAsGuest()
                            }
                        }
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(.systemBackground).opacity(0.95))
                            .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                    )
                    .padding(.horizontal, 16)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)

                    Spacer(minLength: 40)
                }
            }

            // Features modal
            if showFeatures {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showFeatures = false
                        }
                    }

                VStack {
                    Spacer()

                    VStack(spacing: 24) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 40, height: 5)

                        Text("Why HobbyApp?")
                            .font(.system(size: 28, weight: .bold, design: .rounded))

                        VStack(spacing: 20) {
                            FeatureRow(
                                icon: "paintpalette.fill",
                                title: "12+ Creative Categories",
                                description: "Pottery, cooking, painting, photography, and more"
                            )

                            FeatureRow(
                                icon: "creditcard.fill",
                                title: "Smart Credit System",
                                description: "Save money with bonus credits on larger packs"
                            )

                            FeatureRow(
                                icon: "star.fill",
                                title: "Earn Achievements",
                                description: "Track progress and unlock badges as you learn"
                            )

                            FeatureRow(
                                icon: "person.2.fill",
                                title: "Join the Community",
                                description: "Follow instructors and discover classes with friends"
                            )
                        }

                        BrandedButton("Got It!", icon: "checkmark.circle.fill") {
                            withAnimation {
                                showFeatures = false
                            }
                        }
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(.systemBackground))
                    )
                }
                .ignoresSafeArea()
                .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    ContentView()
}