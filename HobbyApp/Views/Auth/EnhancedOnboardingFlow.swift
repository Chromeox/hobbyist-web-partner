import SwiftUI

// MARK: - Enhanced Onboarding Flow

struct EnhancedOnboardingFlow: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @State private var currentStep = 0
    @State private var userPreferences: [String: Any] = [:]
    @State private var isSavingPreferences = false

    let onComplete: () -> Void

    private let totalSteps = 7

    var body: some View {
        ZStack {
            // Brand gradient background
            BrandConstants.Gradients.landing
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress Bar
                OnboardingProgressView(
                    currentStep: currentStep,
                    totalSteps: totalSteps
                )

                // Current Step Content
                currentStepView
                    .animation(BrandConstants.Animation.spring, value: currentStep)

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
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case 0:
            // Welcome Step - Vancouver themed with brand design
            VStack(spacing: BrandConstants.Spacing.xl) {
                Spacer()

                // Logo with glassmorphic circle
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [BrandConstants.Colors.surface.opacity(0.3), BrandConstants.Colors.surface.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 140, height: 140)

                    Image(systemName: "figure.yoga")
                        .font(BrandConstants.Typography.heroTitle)
                        .foregroundColor(BrandConstants.Colors.surface)
                }

                // Hero text with brand typography
                VStack(spacing: BrandConstants.Spacing.md) {
                    Text("Welcome to HobbyApp!")
                        .font(BrandConstants.Typography.heroTitle)
                        .foregroundColor(BrandConstants.Colors.surface)
                        .multilineTextAlignment(.center)

                    Text("Discover Vancouver's most creative hobby classes and connect with a community of passionate learners.")
                        .font(BrandConstants.Typography.body)
                        .foregroundColor(BrandConstants.Colors.surface.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BrandConstants.Spacing.md)
                }

                Spacer()
            }
            .padding(BrandConstants.Spacing.md)

        case 1:
            // Demographics Step - Age, Gender, Neighborhood
            DemographicsStep(userPreferences: $userPreferences)

        case 2:
            // Profile Setup Step with brand styling
            ScrollView(showsIndicators: false) {
                VStack(spacing: BrandConstants.Spacing.xl) {
                    Spacer(minLength: BrandConstants.Spacing.xxl)

                    // Header
                    VStack(spacing: BrandConstants.Spacing.md) {
                        Text("Tell us about yourself")
                            .font(BrandConstants.Typography.largeTitle)
                            .foregroundColor(BrandConstants.Colors.surface)
                            .multilineTextAlignment(.center)

                        Text("Help us personalize your Vancouver creative class experience")
                            .font(BrandConstants.Typography.body)
                            .foregroundColor(BrandConstants.Colors.surface.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }

                    // Glassmorphic form card
                    VStack(spacing: BrandConstants.Spacing.md) {
                        TextField("Full Name", text: .constant(""))
                            .padding(BrandConstants.Spacing.md)
                            .background(BrandConstants.Colors.surface.opacity(0.95))
                            .cornerRadius(BrandConstants.CornerRadius.md)

                        OutlineButton("Select Neighborhood", icon: "mappin.circle.fill", borderColor: BrandConstants.Colors.primary) {}
                    }
                    .padding(BrandConstants.Spacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                            .fill(BrandConstants.Colors.surface.opacity(0.15))
                            .shadow(color: BrandConstants.Colors.text.opacity(0.1), radius: 16, y: 8)
                    )
                    .padding(.horizontal, BrandConstants.Spacing.md)

                    Spacer()
                }
            }
            .padding(BrandConstants.Spacing.md)

        case 3:
            // Preferences Step with brand styling
            ScrollView(showsIndicators: false) {
                VStack(spacing: BrandConstants.Spacing.xl) {
                    Spacer(minLength: BrandConstants.Spacing.xxl)

                    // Header
                    VStack(spacing: BrandConstants.Spacing.md) {
                        Text("Your Class Preferences")
                            .font(BrandConstants.Typography.largeTitle)
                            .foregroundColor(BrandConstants.Colors.surface)
                            .multilineTextAlignment(.center)

                        Text("Help us find the perfect classes for you")
                            .font(BrandConstants.Typography.body)
                            .foregroundColor(BrandConstants.Colors.surface.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }

                    // Glassmorphic card with time preferences
                    VStack(spacing: BrandConstants.Spacing.md) {
                        Text("Preferred Times")
                            .font(BrandConstants.Typography.headline)
                            .foregroundColor(BrandConstants.Colors.surface)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.sm) {
                            ForEach(["Morning", "Afternoon", "Evening", "Weekend"], id: \.self) { time in
                                Button(action: {}) {
                                    Text(time)
                                        .font(BrandConstants.Typography.subheadline)
                                        .foregroundColor(BrandConstants.Colors.text)
                                        .frame(maxWidth: .infinity)
                                        .padding(BrandConstants.Spacing.md)
                                        .background(BrandConstants.Colors.surface.opacity(0.95))
                                        .cornerRadius(BrandConstants.CornerRadius.md)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                                                .stroke(BrandConstants.Colors.primary.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    .padding(BrandConstants.Spacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                            .fill(BrandConstants.Colors.surface.opacity(0.15))
                            .shadow(color: BrandConstants.Colors.text.opacity(0.1), radius: 16, y: 8)
                    )
                    .padding(.horizontal, BrandConstants.Spacing.md)

                    Spacer()
                }
            }
            .padding(BrandConstants.Spacing.md)

        case 4:
            // Interests Step with brand styling
            ScrollView(showsIndicators: false) {
                VStack(spacing: BrandConstants.Spacing.xl) {
                    Spacer(minLength: BrandConstants.Spacing.lg)

                    // Header
                    VStack(spacing: BrandConstants.Spacing.md) {
                        Text("What interests you?")
                            .font(BrandConstants.Typography.largeTitle)
                            .foregroundColor(BrandConstants.Colors.surface)
                            .multilineTextAlignment(.center)

                        Text("Select the creative activities that spark your curiosity")
                            .font(BrandConstants.Typography.body)
                            .foregroundColor(BrandConstants.Colors.surface.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }

                    // Interest selection grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.md) {
                        ForEach(["Pottery & Ceramics", "Cooking & Culinary", "Arts & Crafts", "Photography", "Music & Performance", "Dance & Movement"], id: \.self) { interest in
                            Button(action: {}) {
                                VStack(spacing: BrandConstants.Spacing.sm) {
                                    ZStack {
                                        Circle()
                                            .fill(BrandConstants.Colors.primary.opacity(0.2))
                                            .frame(width: 50, height: 50)

                                        Image(systemName: "heart.fill")
                                            .foregroundColor(BrandConstants.Colors.primary)
                                    }

                                    Text(interest)
                                        .font(BrandConstants.Typography.caption)
                                        .foregroundColor(BrandConstants.Colors.text)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(BrandConstants.Spacing.md)
                                .frame(maxWidth: .infinity)
                                .background(BrandConstants.Colors.surface.opacity(0.95))
                                .cornerRadius(BrandConstants.CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                                        .stroke(BrandConstants.Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, BrandConstants.Spacing.md)

                    Spacer()
                }
            }
            .padding(BrandConstants.Spacing.md)

        case 5:
            // Notifications Step with brand styling
            ScrollView(showsIndicators: false) {
                VStack(spacing: BrandConstants.Spacing.xl) {
                    Spacer(minLength: BrandConstants.Spacing.xxl)

                    // Icon
                    ZStack {
                        Circle()
                            .fill(BrandConstants.Colors.surface.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: "bell.circle.fill")
                            .font(BrandConstants.Typography.heroTitle)
                            .foregroundColor(BrandConstants.Colors.surface)
                    }

                    // Header
                    VStack(spacing: BrandConstants.Spacing.md) {
                        Text("Stay in the Loop")
                            .font(BrandConstants.Typography.largeTitle)
                            .foregroundColor(BrandConstants.Colors.surface)
                            .multilineTextAlignment(.center)

                        Text("Get notifications about your classes and discover new opportunities")
                            .font(BrandConstants.Typography.body)
                            .foregroundColor(BrandConstants.Colors.surface.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }

                    // Notification preferences card
                    VStack(spacing: BrandConstants.Spacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                                Text("Class Reminders")
                                    .font(BrandConstants.Typography.headline)
                                Text("Get notified before your classes")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(BrandConstants.Colors.secondaryText)
                            }
                            Spacer()
                            Toggle("", isOn: .constant(true))
                                .tint(BrandConstants.Colors.primary)
                        }
                        .padding(BrandConstants.Spacing.md)
                        .background(BrandConstants.Colors.surface.opacity(0.95))
                        .cornerRadius(BrandConstants.CornerRadius.md)

                        HStack {
                            VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                                Text("New Classes")
                                    .font(BrandConstants.Typography.headline)
                                Text("Discover fresh creative opportunities")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(BrandConstants.Colors.secondaryText)
                            }
                            Spacer()
                            Toggle("", isOn: .constant(true))
                                .tint(BrandConstants.Colors.primary)
                        }
                        .padding(BrandConstants.Spacing.md)
                        .background(BrandConstants.Colors.surface.opacity(0.95))
                        .cornerRadius(BrandConstants.CornerRadius.md)
                    }
                    .padding(BrandConstants.Spacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                            .fill(BrandConstants.Colors.surface.opacity(0.15))
                            .shadow(color: BrandConstants.Colors.text.opacity(0.1), radius: 16, y: 8)
                    )
                    .padding(.horizontal, BrandConstants.Spacing.md)

                    Spacer()
                }
            }
            .padding(BrandConstants.Spacing.md)

        case 6:
            // Completion Step with brand styling
            VStack(spacing: BrandConstants.Spacing.xxl) {
                Spacer()

                // Success icon with glassmorphic background
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [BrandConstants.Colors.surface.opacity(0.3), BrandConstants.Colors.surface.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)

                    if isSavingPreferences {
                        ProgressView()
                            .scaleEffect(2)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(BrandConstants.Typography.heroTitle)
                            .foregroundColor(BrandConstants.Colors.teal)
                    }
                }

                // Success message
                VStack(spacing: BrandConstants.Spacing.md) {
                    Text(isSavingPreferences ? "Saving your preferences..." : "Welcome to Vancouver's Creative Community!")
                        .font(BrandConstants.Typography.largeTitle)
                        .foregroundColor(BrandConstants.Colors.surface)
                        .multilineTextAlignment(.center)

                    Text(isSavingPreferences ? "Just a moment while we personalize your experience." : "You're all set! Your personalized class recommendations are waiting.")
                        .font(BrandConstants.Typography.body)
                        .foregroundColor(BrandConstants.Colors.surface.opacity(0.9))
                        .multilineTextAlignment(.center)
                }

                // Preferences summary card
                if !isSavingPreferences && !userPreferences.isEmpty {
                    VStack(spacing: BrandConstants.Spacing.sm) {
                        if let interests = userPreferences["interests"] as? [String], !interests.isEmpty {
                            Text("Interests: \(interests.joined(separator: ", "))")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(BrandConstants.Colors.text)
                                .multilineTextAlignment(.center)
                        }

                        if let neighborhood = userPreferences["neighborhood"] as? String, !neighborhood.isEmpty {
                            Text("Preferred Area: \(neighborhood)")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(BrandConstants.Colors.text)
                        }
                    }
                    .padding(BrandConstants.Spacing.md)
                    .background(BrandConstants.Colors.surface.opacity(0.95))
                    .cornerRadius(BrandConstants.CornerRadius.md)
                    .padding(.horizontal, BrandConstants.Spacing.md)
                }

                Spacer()
            }
            .padding(BrandConstants.Spacing.md)

        default:
            Text("Welcome!")
                .font(BrandConstants.Typography.title)
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
        VStack(spacing: BrandConstants.Spacing.sm) {
            HStack {
                Text("Setup Progress")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(BrandConstants.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(BrandConstants.Colors.surface)
            }

            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .scaleEffect(y: 2)
        }
        .padding(BrandConstants.Spacing.md)
        .background(BrandConstants.Colors.surface.opacity(0.15))
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
        HStack(spacing: BrandConstants.Spacing.md) {
            // Back Button
            if currentStep > 0 {
                AnimatedButton("Back", style: .minimal) {
                    onBack()
                }
            } else {
                Spacer()
                    .frame(width: 60)
            }

            Spacer()

            // Skip Button (except for first and last steps)
            if currentStep > 0 && currentStep < totalSteps - 1 {
                TextButton("Skip", color: .white.opacity(0.7), action: onSkip)
            }

            // Next/Complete Button
            BrandedButton(
                currentStep == totalSteps - 1 ? "Complete" : "Next",
                icon: currentStep == totalSteps - 1 ? "checkmark.circle.fill" : "arrow.right.circle.fill",
                action: onNext
            )
        }
        .padding(BrandConstants.Spacing.md)
        .background(BrandConstants.Colors.surface.opacity(0.1))
        .shadow(color: BrandConstants.Colors.text.opacity(0.1), radius: 2, y: -2)
    }
}
