import Foundation

// MARK: - Core Onboarding Service Implementation

@MainActor
final class OnboardingService: BaseModuleService, OnboardingModuleProtocol {

    // MARK: - Published State

    @Published private(set) var currentState: OnboardingState
    @Published private(set) var isOnboardingInProgress: Bool = false

    // MARK: - Dependencies

    private let dataService: OnboardingDataServiceProtocol
    private let dataStore: ModuleDataStore<OnboardingState>

    // MARK: - Initialization

    init(dataService: OnboardingDataServiceProtocol? = nil) {
        self.currentState = OnboardingState()
        self.dataService = dataService ?? OnboardingDataService()
        self.dataStore = ModuleDataStore<OnboardingState>(moduleId: "onboarding")

        super.init(
            moduleId: "onboarding",
            moduleName: "Onboarding Module",
            dependencies: []
        )

        print("🎯 OnboardingService initialized")
    }

    // MARK: - Module Lifecycle

    override func initializeModule() async throws {
        // Load any existing onboarding state
        if let userId = supabaseService.currentUser?.id {
            if let savedState = try await dataService.loadOnboardingState(for: userId) {
                currentState = savedState
                print("📋 Loaded existing onboarding state for user: \(userId)")
            }
        }
    }

    override func startModule() async throws {
        // Check if onboarding feature is enabled
        guard featureFlagManager.isEnabled(.onboardingModule) else {
            throw ModuleError.initializationFailed("Onboarding module is disabled")
        }

        print("▶️ Onboarding module started")
    }

    override func performHealthCheck() async throws {
        // Call parent health check first
        try await super.performHealthCheck()

        // Additional onboarding-specific health checks
        if isOnboardingInProgress {
            // Ensure we can save state
            try await dataStore.store(currentState, key: "health_check")
            try await dataStore.delete(key: "health_check")
        }
    }

    // MARK: - OnboardingModuleProtocol Implementation

    var availableSteps: [OnboardingStep] {
        return OnboardingStep.allCases
    }

    func startOnboarding() async throws {
        guard let user = supabaseService.currentUser else {
            throw ModuleError.authenticationRequired
        }

        isOnboardingInProgress = true

        // Create new onboarding state
        currentState = OnboardingState(
            userId: user.id,
            currentStep: .welcome,
            startedAt: Date()
        )

        // Save initial state
        try await saveCurrentState()

        // Publish onboarding started event
        let event = ModuleEvent.onboardingStarted(from: moduleId)
        ModuleEventBus.shared.publish(event)

        print("🎯 Onboarding started for user: \(user.id)")
    }

    func nextStep() async throws -> Bool {
        guard isOnboardingInProgress else {
            throw ModuleError.initializationFailed("Onboarding is not in progress")
        }

        guard let nextStep = currentState.nextAvailableStep else {
            // No more steps, complete onboarding
            try await completeOnboarding()
            return false
        }

        // Validate current step before moving
        let validation = currentState.currentStep.validateCompletion(
            with: currentState.userPreferences.mapValues { $0.value }
        )

        guard validation.isValid else {
            throw ModuleError.initializationFailed("Current step validation failed: \(validation.message ?? "Unknown error")")
        }

        // Mark current step as completed
        let updatedState = OnboardingState(
            userId: currentState.userId,
            currentStep: nextStep,
            completedSteps: currentState.completedSteps.union([currentState.currentStep]),
            userPreferences: currentState.userPreferences,
            startedAt: currentState.startedAt,
            lastUpdatedAt: Date(),
            isCompleted: currentState.isCompleted
        )

        currentState = updatedState
        try await saveCurrentState()

        print("👉 Moved to next step: \(nextStep.displayName)")
        return true
    }

    func previousStep() async throws -> Bool {
        guard isOnboardingInProgress else {
            throw ModuleError.initializationFailed("Onboarding is not in progress")
        }

        guard let previousStep = currentState.previousAvailableStep else {
            return false
        }

        let updatedState = OnboardingState(
            userId: currentState.userId,
            currentStep: previousStep,
            completedSteps: currentState.completedSteps,
            userPreferences: currentState.userPreferences,
            startedAt: currentState.startedAt,
            lastUpdatedAt: Date(),
            isCompleted: currentState.isCompleted
        )

        currentState = updatedState
        try await saveCurrentState()

        print("👈 Moved to previous step: \(previousStep.displayName)")
        return true
    }

    func skipCurrentStep() async throws -> Bool {
        guard isOnboardingInProgress else {
            throw ModuleError.initializationFailed("Onboarding is not in progress")
        }

        guard currentState.currentStep.isSkippable else {
            throw ModuleError.initializationFailed("Current step cannot be skipped")
        }

        print("⏭️ Skipping step: \(currentState.currentStep.displayName)")
        return try await nextStep()
    }

    func completeOnboarding() async throws {
        guard let userId = currentState.userId else {
            throw ModuleError.authenticationRequired
        }

        // Mark all remaining steps as completed
        let allSteps = Set(OnboardingStep.allCases)
        let updatedState = OnboardingState(
            userId: currentState.userId,
            currentStep: .completion,
            completedSteps: allSteps,
            userPreferences: currentState.userPreferences,
            startedAt: currentState.startedAt,
            lastUpdatedAt: Date(),
            isCompleted: true
        )

        currentState = updatedState
        isOnboardingInProgress = false

        // Save final state
        try await saveCurrentState()
        try await dataService.markOnboardingCompleted(for: userId)

        // Save user preferences to Supabase
        let preferences = currentState.userPreferences.mapValues { $0.value }
        try await dataService.saveUserPreferences(preferences, for: userId)

        // Publish completion event
        let event = ModuleEvent.onboardingCompleted(from: moduleId, userData: preferences)
        ModuleEventBus.shared.publish(event)

        print("🎉 Onboarding completed for user: \(userId)")
    }

    func resumeOnboarding() async throws {
        guard let user = supabaseService.currentUser else {
            throw ModuleError.authenticationRequired
        }

        if let savedState = try await dataService.loadOnboardingState(for: user.id) {
            currentState = savedState
            isOnboardingInProgress = !savedState.isCompleted

            print("🔄 Resumed onboarding for user: \(user.id)")
        } else {
            // No saved state, start fresh
            try await startOnboarding()
        }
    }

    func isOnboardingRequired() async -> Bool {
        guard let user = supabaseService.currentUser else {
            return false
        }

        do {
            return !(try await dataService.hasCompletedOnboarding(userId: user.id))
        } catch {
            // If we can't check, assume onboarding is required
            return true
        }
    }

    func saveUserPreferences(_ preferences: [String: Any]) async throws {
        let anyCodablePreferences = preferences.mapValues { AnyCodable($0) }

        let updatedState = OnboardingState(
            userId: currentState.userId,
            currentStep: currentState.currentStep,
            completedSteps: currentState.completedSteps,
            userPreferences: currentState.userPreferences.merging(anyCodablePreferences) { _, new in new },
            startedAt: currentState.startedAt,
            lastUpdatedAt: Date(),
            isCompleted: currentState.isCompleted
        )

        currentState = updatedState
        try await saveCurrentState()

        print("💾 Saved user preferences: \(preferences.keys.joined(separator: ", "))")
    }

    func getProgress() -> Double {
        return currentState.progress
    }

    // MARK: - Private Helpers

    private func saveCurrentState() async throws {
        guard let userId = currentState.userId else { return }

        try await dataStore.store(currentState, key: "current_state")
        try await dataService.saveOnboardingState(currentState)
    }
}

// MARK: - Onboarding Data Service Implementation

private class OnboardingDataService: OnboardingDataServiceProtocol {

    private let supabaseService = SimpleSupabaseService.shared

    func saveOnboardingState(_ state: OnboardingState) async throws {
        guard let userId = state.userId else {
            throw ModuleError.authenticationRequired
        }

        // Convert state to dictionary for Supabase storage
        let stateData: [String: Any] = [
            "user_id": userId,
            "current_step": state.currentStep.rawValue,
            "completed_steps": Array(state.completedSteps).map { $0.rawValue },
            "user_preferences": state.userPreferences.mapValues { $0.value },
            "started_at": state.startedAt.ISO8601Format(),
            "last_updated_at": state.lastUpdatedAt.ISO8601Format(),
            "is_completed": state.isCompleted
        ]

        // For now, store in UserDefaults. In production, this would go to Supabase
        let key = "onboarding_state_\(userId)"
        if let data = try? JSONSerialization.data(withJSONObject: stateData) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadOnboardingState(for userId: String) async throws -> OnboardingState? {
        let key = "onboarding_state_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Parse the saved state
        guard let currentStepRaw = dict["current_step"] as? String,
              let currentStep = OnboardingStep(rawValue: currentStepRaw),
              let completedStepsRaw = dict["completed_steps"] as? [String],
              let startedAtString = dict["started_at"] as? String,
              let startedAt = ISO8601DateFormatter().date(from: startedAtString) else {
            return nil
        }

        let completedSteps = Set(completedStepsRaw.compactMap { OnboardingStep(rawValue: $0) })
        let userPreferences = (dict["user_preferences"] as? [String: Any] ?? [:]).mapValues { AnyCodable($0) }
        let lastUpdatedAtString = dict["last_updated_at"] as? String
        let lastUpdatedAt = lastUpdatedAtString.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
        let isCompleted = dict["is_completed"] as? Bool ?? false

        return OnboardingState(
            userId: userId,
            currentStep: currentStep,
            completedSteps: completedSteps,
            userPreferences: userPreferences,
            startedAt: startedAt,
            lastUpdatedAt: lastUpdatedAt,
            isCompleted: isCompleted
        )
    }

    func clearOnboardingState(for userId: String) async throws {
        let key = "onboarding_state_\(userId)"
        UserDefaults.standard.removeObject(forKey: key)
    }

    func saveUserPreferences(_ preferences: [String: Any], for userId: String) async throws {
        // Store preferences in UserDefaults for now
        let key = "user_preferences_\(userId)"
        if let data = try? JSONSerialization.data(withJSONObject: preferences) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadUserPreferences(for userId: String) async throws -> [String: Any] {
        let key = "user_preferences_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let preferences = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return preferences
    }

    func markOnboardingCompleted(for userId: String) async throws {
        let key = "onboarding_completed_\(userId)"
        UserDefaults.standard.set(true, forKey: key)
    }

    func hasCompletedOnboarding(userId: String) async throws -> Bool {
        let key = "onboarding_completed_\(userId)"
        return UserDefaults.standard.bool(forKey: key)
    }
}