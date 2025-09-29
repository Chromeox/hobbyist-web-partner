import Foundation
import SwiftUI

// MARK: - Onboarding Steps

enum OnboardingStep: String, CaseIterable, Identifiable {
    case welcome
    case userProfile
    case preferences
    case interests
    case notifications
    case location
    case completion

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .welcome:
            return "Welcome"
        case .userProfile:
            return "Profile Setup"
        case .preferences:
            return "Preferences"
        case .interests:
            return "Your Interests"
        case .notifications:
            return "Notifications"
        case .location:
            return "Location"
        case .completion:
            return "Complete"
        }
    }

    var isSkippable: Bool {
        switch self {
        case .welcome, .completion:
            return false
        case .userProfile, .preferences, .interests, .notifications, .location:
            return true
        }
    }
}

// MARK: - Onboarding State

struct OnboardingState {
    var currentStep: OnboardingStep = .welcome
    var completedSteps: Set<OnboardingStep> = []
    var userPreferences: [String: Any] = [:]
    var isCompleted: Bool = false

    var previousAvailableStep: OnboardingStep? {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else {
            return nil
        }
        return OnboardingStep.allCases[currentIndex - 1]
    }

    var nextAvailableStep: OnboardingStep? {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex < OnboardingStep.allCases.count - 1 else {
            return nil
        }
        return OnboardingStep.allCases[currentIndex + 1]
    }
}

// MARK: - Simplified Onboarding Service

@MainActor
final class OnboardingService: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var currentState = OnboardingState()
    @Published private(set) var isLoading = false
    @Published var error: String?

    // MARK: - Private Properties

    private let userDefaultsKey = "hobbyist_onboarding_completed"
    private let preferencesKey = "hobbyist_user_preferences"

    // MARK: - Public Methods

    func isOnboardingRequired() async -> Bool {
        return !UserDefaults.standard.bool(forKey: userDefaultsKey)
    }

    func resumeOnboarding() async throws {
        // Load any saved preferences
        if let preferencesData = UserDefaults.standard.data(forKey: preferencesKey),
           let preferences = try? JSONSerialization.jsonObject(with: preferencesData) as? [String: Any] {
            currentState.userPreferences = preferences
        }

        // Start from the first incomplete step
        currentState.currentStep = getFirstIncompleteStep()
    }

    func nextStep() async throws -> Bool {
        guard let nextStep = currentState.nextAvailableStep else {
            // No more steps, complete onboarding
            await completeOnboarding()
            return false
        }

        // Mark current step as completed
        currentState.completedSteps.insert(currentState.currentStep)

        // Move to next step
        currentState.currentStep = nextStep

        return true
    }

    func previousStep() async throws -> Bool {
        guard let previousStep = currentState.previousAvailableStep else {
            return false
        }

        currentState.currentStep = previousStep
        return true
    }

    func skipCurrentStep() async throws -> Bool {
        guard currentState.currentStep.isSkippable else {
            return false
        }

        return try await nextStep()
    }

    func saveUserPreferences(_ preferences: [String: Any]) async throws {
        // Merge with existing preferences
        currentState.userPreferences.merge(preferences) { _, new in new }

        // Save to UserDefaults
        if let data = try? JSONSerialization.data(withJSONObject: currentState.userPreferences) {
            UserDefaults.standard.set(data, forKey: preferencesKey)
        }
    }

    func getProgress() -> Double {
        let totalSteps = Double(OnboardingStep.allCases.count)
        let currentStepIndex = Double(OnboardingStep.allCases.firstIndex(of: currentState.currentStep) ?? 0)
        return currentStepIndex / totalSteps
    }

    // MARK: - Private Methods

    private func getFirstIncompleteStep() -> OnboardingStep {
        for step in OnboardingStep.allCases {
            if !currentState.completedSteps.contains(step) {
                return step
            }
        }
        return .completion
    }

    private func completeOnboarding() async {
        currentState.isCompleted = true
        UserDefaults.standard.set(true, forKey: userDefaultsKey)

        // Here you could also sync preferences to Supabase
        await syncPreferencesToBackend()
    }

    private func syncPreferencesToBackend() async {
        // TODO: Sync user preferences to Supabase
        // This would integrate with SimpleSupabaseService to save user preferences
        print("✅ Onboarding completed with preferences: \(currentState.userPreferences)")
    }
}

// MARK: - Vancouver-Specific Enhancements

extension OnboardingService {

    /// Get Vancouver-specific hobby recommendations
    func getVancouverHobbyRecommendations() -> [String] {
        return [
            "Pottery at Claymates Studio",
            "Rumble Boxing at Mount Pleasant",
            "Cooking Classes in Gastown",
            "Photography Walks in Stanley Park",
            "Yoga in Kitsilano",
            "Painting Classes in Commercial Drive"
        ]
    }

    /// Get Vancouver neighborhoods for location preferences
    func getVancouverNeighborhoods() -> [String] {
        return [
            "Downtown", "Gastown", "Yaletown", "West End",
            "Kitsilano", "Commercial Drive", "Mount Pleasant",
            "Fairview", "Kerrisdale", "Richmond", "North Vancouver"
        ]
    }
}