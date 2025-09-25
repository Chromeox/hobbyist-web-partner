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
                // User authenticated but needs onboarding - show enhanced onboarding flow
                EnhancedOnboardingFlow(onComplete: {
                    needsOnboarding = false
                    UserDefaults.standard.set(true, forKey: "hobbyist_onboarding_completed")
                })
                .environmentObject(supabaseService)
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
                // Check if onboarding is needed from Supabase backend
                if let userPreferences = await supabaseService.fetchUserPreferences(),
                   let onboardingCompleted = userPreferences["onboarding_completed"] as? Bool,
                   onboardingCompleted {
                    needsOnboarding = false
                } else {
                    // No preferences found or onboarding not completed - show onboarding
                    needsOnboarding = true
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

#Preview {
    ContentView()
}