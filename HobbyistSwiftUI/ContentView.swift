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
                // Loading state while checking authentication and onboarding
                ProgressView("Loading HobbyApp...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
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

// MARK: - Enhanced Onboarding Flow

struct EnhancedOnboardingFlow: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @State private var currentStep = 0
    @State private var userPreferences: [String: Any] = [:]
    @State private var isSavingPreferences = false

    let onComplete: () -> Void

    private let totalSteps = 6

    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            OnboardingProgressView(
                currentStep: currentStep,
                totalSteps: totalSteps
            )

            // Current Step Content
            currentStepView
                .animation(.easeInOut(duration: 0.3), value: currentStep)

            // Navigation Controls
            OnboardingNavigationView(
                currentStep: currentStep,
                totalSteps: totalSteps,
                onBack: { currentStep = max(0, currentStep - 1) },
                onNext: {
                    if currentStep < totalSteps - 1 {
                        currentStep += 1
                    } else {
                        // Save preferences to Supabase before completing
                        Task {
                            isSavingPreferences = true
                            let success = await supabaseService.saveOnboardingPreferences(userPreferences)
                            isSavingPreferences = false

                            if success {
                                onComplete()
                            } else {
                                // Could show an error here, but for now just complete anyway
                                print("⚠️ Failed to save preferences, but continuing with onboarding completion")
                                onComplete()
                            }
                        }
                    }
                },
                onSkip: { currentStep += 1 }
            )
        }
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case 0:
            // Welcome Step - Vancouver themed
            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.2), .green.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 140, height: 140)

                    Image(systemName: "figure.yoga")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(LinearGradient(
                            colors: [.blue, .green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }

                VStack(spacing: 16) {
                    Text("Welcome to HobbyApp!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Discover Vancouver's most creative hobby classes and connect with a community of passionate learners.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()

        case 1:
            // Profile Setup Step
            VStack(spacing: 24) {
                Text("Tell us about yourself")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Help us personalize your Vancouver creative class experience")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 16) {
                    TextField("Full Name", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Select Neighborhood") {}
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding()

        case 2:
            // Preferences Step
            VStack(spacing: 24) {
                Text("Your Class Preferences")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Help us find the perfect classes for you")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(spacing: 16) {
                    Text("Preferred Times")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(["Morning", "Afternoon", "Evening", "Weekend"], id: \.self) { time in
                            Button(time) {}
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }

                Spacer()
            }
            .padding()

        case 3:
            // Interests Step - No fitness/boxing
            VStack(spacing: 24) {
                Text("What interests you?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Select the creative activities that spark your curiosity")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(["Pottery & Ceramics", "Cooking & Culinary", "Arts & Crafts", "Photography", "Music & Performance", "Dance & Movement"], id: \.self) { interest in
                        VStack(spacing: 12) {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.blue)
                                )

                            Text(interest)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }

                Spacer()
            }
            .padding()

        case 4:
            // Notifications Step
            VStack(spacing: 24) {
                Image(systemName: "bell.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Stay in the Loop")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Get notifications about your classes and discover new opportunities")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 16) {
                    HStack {
                        Text("Class Reminders")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    HStack {
                        Text("New Classes")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding()

        case 5:
            // Completion Step
            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.green.opacity(0.2), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)

                    if isSavingPreferences {
                        ProgressView()
                            .scaleEffect(2)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                    }
                }

                VStack(spacing: 16) {
                    Text(isSavingPreferences ? "Saving your preferences..." : "Welcome to Vancouver's Creative Community!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(isSavingPreferences ? "Just a moment while we personalize your experience." : "You're all set! Your personalized class recommendations are waiting.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Show preferences summary
                if !isSavingPreferences && !userPreferences.isEmpty {
                    VStack(spacing: 8) {
                        if let interests = userPreferences["interests"] as? [String], !interests.isEmpty {
                            Text("Interests: \(interests.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        if let neighborhood = userPreferences["neighborhood"] as? String, !neighborhood.isEmpty {
                            Text("Preferred Area: \(neighborhood)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding()

        default:
            Text("Welcome!")
                .font(.title)
                .padding()
        }
    }
}

// MARK: - Progress View

struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int

    private var progress: Double {
        Double(currentStep + 1) / Double(totalSteps)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Setup Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }

            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 2)
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Navigation View

struct OnboardingNavigationView: View {
    let currentStep: Int
    let totalSteps: Int
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack {
            // Back Button
            if currentStep > 0 {
                Button("Back", action: onBack)
                    .foregroundColor(.secondary)
            } else {
                Spacer()
                    .frame(width: 60)
            }

            Spacer()

            // Skip Button (except for first and last steps)
            if currentStep > 0 && currentStep < totalSteps - 1 {
                Button("Skip", action: onSkip)
                    .foregroundColor(.secondary)
            }

            // Next/Complete Button
            Button(currentStep == totalSteps - 1 ? "Complete" : "Next") {
                onNext()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 2, y: -2)
    }
}

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