import Foundation

// MARK: - Onboarding Module Tests
// In a production app, these would be proper XCTest cases

class OnboardingModuleTests {

    private var onboardingService: OnboardingService!
    private var mockDataService: MockOnboardingDataService!

    init() {
        print("🧪 Initializing OnboardingModuleTests")
        setup()
    }

    private func setup() {
        mockDataService = MockOnboardingDataService()
        onboardingService = OnboardingService(dataService: mockDataService)
    }

    // MARK: - Test Methods

    func runAllTests() async {
        print("🧪 Running Onboarding Module Tests...")

        await testModuleInitialization()
        await testOnboardingFlow()
        await testStepNavigation()
        await testPreferencesSaving()
        await testFeatureFlagIntegration()

        print("✅ All onboarding tests completed")
    }

    private func testModuleInitialization() async {
        print("🧪 Testing module initialization...")

        do {
            try await onboardingService.initialize()
            assert(onboardingService.moduleId == "onboarding", "Module ID should be 'onboarding'")
            print("✅ Module initialization test passed")
        } catch {
            print("❌ Module initialization test failed: \(error)")
        }
    }

    private func testOnboardingFlow() async {
        print("🧪 Testing onboarding flow...")

        do {
            // Start onboarding
            try await onboardingService.startOnboarding()
            assert(onboardingService.currentState.currentStep == .welcome, "Should start with welcome step")

            // Move through steps
            let hasNext = try await onboardingService.nextStep()
            assert(hasNext == true, "Should have next step after welcome")
            assert(onboardingService.currentState.currentStep == .userProfile, "Should move to user profile")

            // Complete onboarding
            try await onboardingService.completeOnboarding()
            assert(onboardingService.currentState.isCompleted == true, "Should be marked as completed")

            print("✅ Onboarding flow test passed")
        } catch {
            print("❌ Onboarding flow test failed: \(error)")
        }
    }

    private func testStepNavigation() async {
        print("🧪 Testing step navigation...")

        do {
            try await onboardingService.startOnboarding()

            // Test forward navigation
            _ = try await onboardingService.nextStep() // Welcome -> UserProfile
            _ = try await onboardingService.nextStep() // UserProfile -> Preferences
            assert(onboardingService.currentState.currentStep == .preferences, "Should be at preferences step")

            // Test backward navigation
            _ = try await onboardingService.previousStep()
            assert(onboardingService.currentState.currentStep == .userProfile, "Should go back to user profile")

            // Test skipping
            if onboardingService.currentState.currentStep.isSkippable {
                _ = try await onboardingService.skipCurrentStep()
                print("✅ Step skipping works")
            }

            print("✅ Step navigation test passed")
        } catch {
            print("❌ Step navigation test failed: \(error)")
        }
    }

    private func testPreferencesSaving() async {
        print("🧪 Testing preferences saving...")

        do {
            try await onboardingService.startOnboarding()

            let testPreferences: [String: Any] = [
                "fullName": "Test User",
                "preferredTimes": ["Morning", "Evening"],
                "selectedInterests": ["Yoga", "Cooking"]
            ]

            try await onboardingService.saveUserPreferences(testPreferences)

            // Verify preferences were saved
            let savedName = onboardingService.currentState.userPreferences["fullName"]?.value as? String
            assert(savedName == "Test User", "Full name should be saved correctly")

            print("✅ Preferences saving test passed")
        } catch {
            print("❌ Preferences saving test failed: \(error)")
        }
    }

    private func testFeatureFlagIntegration() async {
        print("🧪 Testing feature flag integration...")

        let featureFlagManager = FeatureFlagManager.shared

        // Test with feature disabled
        featureFlagManager.setFlag(.onboardingModule, enabled: false)

        do {
            try await onboardingService.start()
            print("❌ Service should not start when feature flag is disabled")
        } catch {
            print("✅ Service correctly fails when feature flag is disabled")
        }

        // Test with feature enabled
        featureFlagManager.setFlag(.onboardingModule, enabled: true)

        do {
            try await onboardingService.start()
            print("✅ Service starts correctly when feature flag is enabled")
        } catch {
            print("❌ Service should start when feature flag is enabled: \(error)")
        }
    }

    // MARK: - Progress Validation

    func testProgressCalculation() {
        print("🧪 Testing progress calculation...")

        var state = OnboardingState()
        assert(state.progress == 0.0, "Initial progress should be 0")

        state = OnboardingState(completedSteps: [.welcome, .userProfile])
        let expectedProgress = 2.0 / Double(OnboardingStep.allCases.count)
        assert(abs(state.progress - expectedProgress) < 0.01, "Progress calculation should be correct")

        print("✅ Progress calculation test passed")
    }

    // MARK: - Integration Test with SimpleSupabaseService

    func testSupabaseIntegration() async {
        print("🧪 Testing Supabase integration...")

        let supabaseService = SimpleSupabaseService.shared

        // This test would verify that onboarding works with actual authentication
        if supabaseService.isAuthenticated {
            do {
                let isRequired = await onboardingService.isOnboardingRequired()
                print("✅ Onboarding requirement check works: \(isRequired)")

                try await onboardingService.resumeOnboarding()
                print("✅ Onboarding resume works with authenticated user")
            } catch {
                print("⚠️ Supabase integration test encountered error: \(error)")
            }
        } else {
            print("ℹ️ Skipping Supabase integration test - user not authenticated")
        }
    }
}

// MARK: - Mock Data Service for Testing

private class MockOnboardingDataService: OnboardingDataServiceProtocol {

    private var savedStates: [String: OnboardingState] = [:]
    private var savedPreferences: [String: [String: Any]] = [:]
    private var completedUsers: Set<String> = []

    func saveOnboardingState(_ state: OnboardingState) async throws {
        guard let userId = state.userId else { return }
        savedStates[userId] = state
        print("🧪 Mock: Saved onboarding state for user: \(userId)")
    }

    func loadOnboardingState(for userId: String) async throws -> OnboardingState? {
        return savedStates[userId]
    }

    func clearOnboardingState(for userId: String) async throws {
        savedStates.removeValue(forKey: userId)
    }

    func saveUserPreferences(_ preferences: [String: Any], for userId: String) async throws {
        savedPreferences[userId] = preferences
        print("🧪 Mock: Saved preferences for user: \(userId)")
    }

    func loadUserPreferences(for userId: String) async throws -> [String: Any] {
        return savedPreferences[userId] ?? [:]
    }

    func markOnboardingCompleted(for userId: String) async throws {
        completedUsers.insert(userId)
        print("🧪 Mock: Marked onboarding completed for user: \(userId)")
    }

    func hasCompletedOnboarding(userId: String) async throws -> Bool {
        return completedUsers.contains(userId)
    }
}

// MARK: - Test Runner

extension OnboardingModuleTests {

    static func runTests() async {
        let testSuite = OnboardingModuleTests()
        await testSuite.runAllTests()
        testSuite.testProgressCalculation()
        await testSuite.testSupabaseIntegration()
    }
}

// MARK: - Debug Helper for Manual Testing

#if DEBUG
extension OnboardingModuleTests {

    func printModuleStatus() {
        print("📊 Onboarding Module Status:")
        print("- Module ID: \(onboardingService.moduleId)")
        print("- Module Name: \(onboardingService.moduleName)")
        print("- Is Healthy: \(onboardingService.isHealthy)")
        print("- Current Step: \(onboardingService.currentState.currentStep.displayName)")
        print("- Progress: \(Int(onboardingService.getProgress() * 100))%")
        print("- Completed Steps: \(onboardingService.currentState.completedSteps.count)")
    }

    func simulateCompleteFlow() async {
        print("🎬 Simulating complete onboarding flow...")

        do {
            try await onboardingService.startOnboarding()

            // Add some preferences for each step
            let stepPreferences: [[String: Any]] = [
                ["fullName": "Test User", "experienceLevel": "Beginner"],
                ["preferredTimes": ["Morning"], "budgetRange": 50],
                ["selectedInterests": ["Yoga", "Cooking"]],
                ["classReminders": true, "newClassAlerts": true],
                ["locationEnabled": true]
            ]

            for (index, preferences) in stepPreferences.enumerated() {
                try await onboardingService.saveUserPreferences(preferences)
                _ = try await onboardingService.nextStep()
                print("✅ Completed step \(index + 1)")
            }

            try await onboardingService.completeOnboarding()
            print("🎉 Simulation completed successfully!")

        } catch {
            print("❌ Simulation failed: \(error)")
        }
    }
}