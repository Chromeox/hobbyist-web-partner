import SwiftUI

// MARK: - Onboarding Coordinator for Flow Management

struct OnboardingCoordinator: View {
    @StateObject private var onboardingService = OnboardingService()
    @EnvironmentObject private var supabaseService: SimpleSupabaseService
    @State private var showingOnboarding = false

    let onComplete: () -> Void

    var body: some View {
        Group {
            if showingOnboarding {
                OnboardingFlowView(
                    onboardingService: onboardingService,
                    onComplete: {
                        showingOnboarding = false
                        onComplete()
                    }
                )
            } else {
                // Placeholder while checking onboarding status
                ProgressView("Checking setup...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
        }
        .onAppear {
            checkOnboardingStatus()
        }
    }

    private func checkOnboardingStatus() {
        Task {
            if await onboardingService.isOnboardingRequired() {
                showingOnboarding = true
                try? await onboardingService.resumeOnboarding()
            } else {
                onComplete()
            }
        }
    }
}

// MARK: - Main Onboarding Flow View

struct OnboardingFlowView: View {
    @ObservedObject var onboardingService: OnboardingService
    @State private var isAnimating = false

    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            OnboardingProgressBar(
                currentStep: onboardingService.currentState.currentStep,
                progress: onboardingService.getProgress()
            )

            // Current Step Content
            currentStepView
                .animation(.easeInOut(duration: 0.3), value: onboardingService.currentState.currentStep)

            // Navigation Controls
            OnboardingNavigationBar(
                currentStep: onboardingService.currentState.currentStep,
                canGoBack: onboardingService.currentState.previousAvailableStep != nil,
                canSkip: onboardingService.currentState.currentStep.isSkippable,
                onBack: {
                    HapticFeedbackService.shared.playLight()
                    Task {
                        _ = try? await onboardingService.previousStep()
                    }
                },
                onNext: {
                    HapticFeedbackService.shared.playLight()
                    Task {
                        let hasNext = try? await onboardingService.nextStep()
                        if hasNext == false {
                            HapticFeedbackService.shared.playSuccess()
                            onComplete()
                        }
                    }
                },
                onSkip: {
                    HapticFeedbackService.shared.playLight()
                    Task {
                        _ = try? await onboardingService.skipCurrentStep()
                    }
                }
            )
        }
        .background(Color(.systemBackground))
        .onAppear {
            isAnimating = true
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch onboardingService.currentState.currentStep {
        case .welcome:
            WelcomeView()
        case .userProfile:
            UserProfileView(onboardingService: onboardingService)
        case .preferences:
            PreferencesView(onboardingService: onboardingService)
        case .interests:
            InterestsView(onboardingService: onboardingService)
        case .notifications:
            NotificationsView(onboardingService: onboardingService)
        case .location:
            LocationView(onboardingService: onboardingService)
        case .completion:
            CompletionView()
        }
    }
}

// MARK: - Progress Bar Component

struct OnboardingProgressBar: View {
    let currentStep: OnboardingStep
    let progress: Double

    var body: some View {
        VStack(spacing: HobbyistSpacing.sm) {
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

            Text(currentStep.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(HobbyistSpacing.md)
        .background(Color(.systemGray6))
    }
}

// MARK: - Navigation Bar Component

struct OnboardingNavigationBar: View {
    let currentStep: OnboardingStep
    let canGoBack: Bool
    let canSkip: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack {
            // Back Button
            if canGoBack {
                Button("Back", action: onBack)
                    .foregroundColor(.secondary)
            } else {
                Spacer()
                    .frame(width: 60)
            }

            Spacer()

            // Skip Button
            if canSkip {
                Button("Skip", action: onSkip)
                    .foregroundColor(.secondary)
            }

            // Next/Complete Button
            Button(currentStep == .completion ? "Complete" : "Next") {
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

// MARK: - Welcome View

struct WelcomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()

                // Enhanced App Logo with Vancouver elements
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
                    Text("Welcome to Hobbyist!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(LinearGradient(
                            colors: [.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))

                    Text("Discover Vancouver's most creative hobby classes and connect with a community of passionate learners.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    FeatureHighlight(
                        icon: "magnifyingglass.circle.fill",
                        title: "Discover Vancouver Classes",
                        description: "Find pottery at Claymates, boxing at Rumble, and more across the city"
                    )

                    FeatureHighlight(
                        icon: "calendar.circle.fill",
                        title: "Easy Booking",
                        description: "Secure booking with instant confirmations and local transit info"
                    )

                    FeatureHighlight(
                        icon: "person.2.circle.fill",
                        title: "Join the Community",
                        description: "Connect with Vancouver's most passionate hobby enthusiasts"
                    )

                    FeatureHighlight(
                        icon: "location.circle.fill",
                        title: "Neighborhood-Focused",
                        description: "From Gastown to Kitsilano - find classes in your area"
                    )
                }

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - User Profile View

struct UserProfileView: View {
    @ObservedObject var onboardingService: OnboardingService
    @State private var fullName = ""
    @State private var birthDate = Date()
    @State private var experienceLevel = "Beginner"

    private let experienceLevels = ["Beginner", "Intermediate", "Advanced", "Expert"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingStepHeader(
                    icon: "person.circle",
                    title: "Tell us about yourself",
                    description: "Help us personalize your Hobbyist experience"
                )

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.headline)
                        TextField("Enter your full name", text: $fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date of Birth")
                            .font(.headline)
                        DatePicker("", selection: $birthDate, displayedComponents: .date)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Experience Level")
                            .font(.headline)
                        Picker("Experience Level", selection: $experienceLevel) {
                            ForEach(experienceLevels, id: \.self) { level in
                                Text(level).tag(level)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                .padding()

                Spacer()
            }
            .padding()
        }
        .onDisappear {
            savePreferences()
        }
    }

    private func savePreferences() {
        Task {
            let preferences: [String: Any] = [
                "fullName": fullName,
                "birthDate": birthDate.ISO8601Format(),
                "experienceLevel": experienceLevel
            ]
            try? await onboardingService.saveUserPreferences(preferences)
        }
    }
}

// MARK: - Preferences View

struct PreferencesView: View {
    @ObservedObject var onboardingService: OnboardingService
    @State private var preferredTimes: Set<String> = []
    @State private var maxTravelDistance = 10.0
    @State private var budgetRange = 50.0

    private let timeSlots = ["Morning", "Afternoon", "Evening", "Weekend"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingStepHeader(
                    icon: "slider.horizontal.3",
                    title: "Your Preferences",
                    description: "Set your preferences for finding the perfect classes"
                )

                VStack(spacing: 20) {
                    // Preferred Times
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferred Times")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(timeSlots, id: \.self) { time in
                                Button(action: {
                                    HapticFeedbackService.shared.playSelection()
                                    if preferredTimes.contains(time) {
                                        preferredTimes.remove(time)
                                    } else {
                                        preferredTimes.insert(time)
                                    }
                                }) {
                                    Text(time)
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(preferredTimes.contains(time) ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(preferredTimes.contains(time) ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }

                    // Travel Distance
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Max Travel Distance")
                            .font(.headline)

                        VStack {
                            Slider(value: $maxTravelDistance, in: 1...50, step: 1)
                            Text("\(Int(maxTravelDistance)) km")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Budget Range
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Typical Budget per Class")
                            .font(.headline)

                        VStack {
                            Slider(value: $budgetRange, in: 10...200, step: 5)
                            Text("Up to $\(Int(budgetRange))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()

                Spacer()
            }
            .padding()
        }
        .onDisappear {
            savePreferences()
        }
    }

    private func savePreferences() {
        Task {
            let preferences: [String: Any] = [
                "preferredTimes": Array(preferredTimes),
                "maxTravelDistance": maxTravelDistance,
                "budgetRange": budgetRange
            ]
            try? await onboardingService.saveUserPreferences(preferences)
        }
    }
}

// MARK: - Interests View

struct InterestsView: View {
    @ObservedObject var onboardingService: OnboardingService
    @State private var selectedInterests: Set<String> = []

    private let interestCategories = [
        "Arts & Crafts": ["Pottery at Claymates", "Painting", "Drawing", "Jewelry Making", "Woodworking", "Ceramics"],
        "Fitness & Wellness": ["Rumble Boxing", "Yoga", "Pilates", "Dance", "Martial Arts", "Meditation", "Rock Climbing"],
        "Culinary": ["Cooking Classes", "Baking", "Wine Tasting", "Cocktail Making", "Food Photography", "Brewing"],
        "Music & Performance": ["Guitar", "Piano", "Singing", "Acting", "Stand-up Comedy", "DJ Skills"],
        "Technology": ["Programming", "Photography", "Video Editing", "3D Printing", "App Development", "Digital Art"],
        "Outdoor & Adventure": ["Hiking Groups", "Kayaking", "Cycling", "Photography Walks", "Nature Sketching", "Urban Exploration"]
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingStepHeader(
                    icon: "heart.circle",
                    title: "What interests you?",
                    description: "Select Vancouver activities you'd like to explore (you can always change these later)"
                )

                VStack(spacing: 20) {
                    ForEach(Array(interestCategories.keys.sorted()), id: \.self) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category)
                                .font(.headline)
                                .foregroundColor(.blue)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(interestCategories[category] ?? [], id: \.self) { interest in
                                    Button(action: {
                                        HapticFeedbackService.shared.playSelection()
                                        if selectedInterests.contains(interest) {
                                            selectedInterests.remove(interest)
                                        } else {
                                            selectedInterests.insert(interest)
                                        }
                                    }) {
                                        Text(interest)
                                            .font(.subheadline)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedInterests.contains(interest) ? Color.blue : Color(.systemGray5))
                                            .foregroundColor(selectedInterests.contains(interest) ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()

                Spacer()
            }
            .padding()
        }
        .onDisappear {
            savePreferences()
        }
    }

    private func savePreferences() {
        Task {
            let preferences: [String: Any] = [
                "selectedInterests": Array(selectedInterests)
            ]
            try? await onboardingService.saveUserPreferences(preferences)
        }
    }
}

// MARK: - Notifications View

struct NotificationsView: View {
    @ObservedObject var onboardingService: OnboardingService
    @State private var classReminders = true
    @State private var newClassAlerts = true
    @State private var promotionalOffers = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingStepHeader(
                    icon: "bell.circle",
                    title: "Stay in the loop",
                    description: "Choose how you'd like to receive updates about your classes and new opportunities"
                )

                VStack(spacing: 16) {
                    NotificationToggle(
                        title: "Class Reminders",
                        description: "Get notified about upcoming classes you've booked",
                        isOn: $classReminders
                    )

                    NotificationToggle(
                        title: "New Class Alerts",
                        description: "Be first to know about new classes in your interests",
                        isOn: $newClassAlerts
                    )

                    NotificationToggle(
                        title: "Promotional Offers",
                        description: "Receive special discounts and promotional offers",
                        isOn: $promotionalOffers
                    )
                }
                .padding()

                Spacer()
            }
            .padding()
        }
        .onDisappear {
            savePreferences()
        }
    }

    private func savePreferences() {
        Task {
            let preferences: [String: Any] = [
                "classReminders": classReminders,
                "newClassAlerts": newClassAlerts,
                "promotionalOffers": promotionalOffers
            ]
            try? await onboardingService.saveUserPreferences(preferences)
        }
    }
}

// MARK: - Location View

struct LocationView: View {
    @ObservedObject var onboardingService: OnboardingService
    @State private var locationPermissionGranted = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                OnboardingStepHeader(
                    icon: "location.circle",
                    title: "Find classes in Vancouver",
                    description: "Enable location access to discover amazing classes in your neighborhood"
                )

                VStack(spacing: 20) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    VStack(spacing: 12) {
                        Text("Location Benefits")
                            .font(.headline)

                        VStack(spacing: 8) {
                            LocationBenefit(icon: "map", text: "Find classes within your preferred distance in Vancouver")
                            LocationBenefit(icon: "clock", text: "Get accurate travel time via TransLink")
                            LocationBenefit(icon: "star", text: "Discover hidden gems from Gastown to Kitsilano")
                        }
                    }

                    Button(action: {
                        HapticFeedbackService.shared.playLight()
                        requestLocationPermission()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Enable Location Access")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }

                    Button("Maybe Later") {
                        // Continue without location
                    }
                    .foregroundColor(.secondary)
                }
                .padding()

                Spacer()
            }
            .padding()
        }
        .onDisappear {
            savePreferences()
        }
    }

    private func requestLocationPermission() {
        // In a real app, this would request location permission
        locationPermissionGranted = true
    }

    private func savePreferences() {
        Task {
            let preferences: [String: Any] = [
                "locationEnabled": locationPermissionGranted
            ]
            try? await onboardingService.saveUserPreferences(preferences)
        }
    }
}

// MARK: - Completion View

struct CompletionView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)

                VStack(spacing: 16) {
                    Text("You're all set!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Welcome to Vancouver's most vibrant hobby community. Start exploring amazing local classes and discover your next creative passion.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    CompletionFeature(
                        icon: "magnifyingglass.circle.fill",
                        title: "Start Exploring",
                        description: "Browse classes across Vancouver's neighborhoods"
                    )

                    CompletionFeature(
                        icon: "person.2.circle.fill",
                        title: "Join the Community",
                        description: "Connect with Vancouver's creative community"
                    )

                    CompletionFeature(
                        icon: "trophy.circle.fill",
                        title: "Track Your Progress",
                        description: "Earn achievements as you explore new hobbies"
                    )
                }

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Supporting Components

struct OnboardingStepHeader: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct NotificationToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LocationBenefit: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }
}

struct CompletionFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.green)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    OnboardingCoordinator(onComplete: {})
        .environmentObject(SimpleSupabaseService.shared)
}