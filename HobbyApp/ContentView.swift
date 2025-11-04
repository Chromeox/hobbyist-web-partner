import SwiftUI

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

            VStack(spacing: BrandConstants.Spacing.lg) {
                // App icon placeholder with animation
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [BrandConstants.Colors.surface.opacity(0.3), BrandConstants.Colors.surface.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)

                    Image(systemName: "figure.yoga")
                        .font(BrandConstants.Typography.heroTitle)
                        .foregroundColor(BrandConstants.Colors.surface)
                        .scaleEffect(scale)
                }

                Text("HobbyApp")
                    .font(BrandConstants.Typography.largeTitle)
                    .foregroundColor(BrandConstants.Colors.surface)
                    .opacity(opacity)

                ProgressView()
                    .tint(BrandConstants.Colors.surface)
                    .scaleEffect(1.2)
                    .padding(.top, BrandConstants.Spacing.sm)
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
            HStack(spacing: BrandConstants.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(BrandConstants.Colors.surface)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(BrandConstants.Gradients.primary)
            .cornerRadius(BrandConstants.CornerRadius.lg)
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
            HStack(spacing: BrandConstants.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(BrandConstants.Colors.primary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color(.systemBackground))
            .cornerRadius(BrandConstants.CornerRadius.lg)
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
            .font(BrandConstants.Typography.subheadline)
            .fontWeight(.medium)
            .foregroundColor(BrandConstants.Colors.surface)
            .padding(.horizontal, BrandConstants.Spacing.md)
            .padding(.vertical, BrandConstants.Spacing.sm)
            .background(Capsule().fill(BrandConstants.Colors.text.opacity(0.85)))
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
                    VStack(spacing: BrandConstants.Spacing.xl) {
                        // Hero placeholder (will use image when available)
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [BrandConstants.Colors.surface.opacity(0.3), BrandConstants.Colors.surface.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 280, height: 280)

                            Image(systemName: "figure.yoga")
                                .font(BrandConstants.Typography.heroTitle)
                                .foregroundColor(BrandConstants.Colors.surface)
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
                        HStack(spacing: BrandConstants.Spacing.xxl) {
                            SpeechBubble("Let's create!", alignment: .leading)
                            Spacer()
                            SpeechBubble("Let's go!", alignment: .trailing)
                        }
                        .padding(.horizontal, BrandConstants.Spacing.xxl)
                        .offset(y: -20)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    Spacer(minLength: 40)

                    // Content Card
                    VStack(spacing: BrandConstants.Spacing.lg) {
                        VStack(spacing: BrandConstants.Spacing.md) {
                            Text("Start Creating Now 🚀")
                                .font(BrandConstants.Typography.largeTitle)
                                .multilineTextAlignment(.center)

                            Text("Discover Vancouver's most creative hobby classes and connect with a community of passionate learners.")
                                .font(BrandConstants.Typography.body)
                                .foregroundColor(BrandConstants.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }

                        VStack(spacing: BrandConstants.Spacing.md) {
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
                    .padding(BrandConstants.Spacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(.systemBackground).opacity(0.95))
                            .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                    )
                    .padding(.horizontal, BrandConstants.Spacing.md)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)

                    Spacer(minLength: 40)
                }
            }

            // Features modal
            if showFeatures {
                BrandConstants.Colors.text.opacity(0.4)
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
                            .fill(BrandConstants.Colors.secondaryText.opacity(0.3))
                            .frame(width: BrandConstants.Spacing.xxl, height: BrandConstants.Spacing.xs)

                        Text("Why HobbyApp?")
                            .font(BrandConstants.Typography.largeTitle)

                        VStack(spacing: BrandConstants.Spacing.lg) {
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
                    .padding(BrandConstants.Spacing.xl)
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
        HStack(alignment: .top, spacing: BrandConstants.Spacing.md) {
            ZStack {
                Circle()
                    .fill(BrandConstants.Colors.primary.opacity(0.15))
                    .frame(width: BrandConstants.Spacing.xxl, height: BrandConstants.Spacing.xxl)

                Image(systemName: icon)
                    .font(BrandConstants.Typography.title)
                    .foregroundColor(BrandConstants.Colors.primary)
            }

            VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                Text(title)
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(BrandConstants.Colors.secondaryText)
            }

            Spacer()
        }
    }
}

#Preview {
    ContentView()
}