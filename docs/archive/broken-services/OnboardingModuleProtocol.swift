import Foundation

// MARK: - Onboarding Module Protocol and Models

/// Protocol defining all onboarding operations for the modular architecture
protocol OnboardingModuleProtocol: ModularServiceProtocol {
    /// Current onboarding state
    var currentState: OnboardingState { get }

    /// Available onboarding steps
    var availableSteps: [OnboardingStep] { get }

    /// Start the onboarding flow
    func startOnboarding() async throws

    /// Move to the next step in onboarding
    func nextStep() async throws -> Bool

    /// Move to the previous step in onboarding
    func previousStep() async throws -> Bool

    /// Skip the current step (if allowed)
    func skipCurrentStep() async throws -> Bool

    /// Complete the entire onboarding flow
    func completeOnboarding() async throws

    /// Resume onboarding from a saved state
    func resumeOnboarding() async throws

    /// Check if onboarding is required for current user
    func isOnboardingRequired() async -> Bool

    /// Save user preferences collected during onboarding
    func saveUserPreferences(_ preferences: [String: Any]) async throws

    /// Get completion progress (0.0 to 1.0)
    func getProgress() -> Double
}

// MARK: - Onboarding State Model

struct OnboardingState: Codable, Equatable {
    let userId: String?
    let currentStep: OnboardingStep
    let completedSteps: Set<OnboardingStep>
    let userPreferences: [String: AnyCodable]
    let startedAt: Date
    let lastUpdatedAt: Date
    let isCompleted: Bool

    init(
        userId: String? = nil,
        currentStep: OnboardingStep = .welcome,
        completedSteps: Set<OnboardingStep> = [],
        userPreferences: [String: AnyCodable] = [:],
        startedAt: Date = Date(),
        lastUpdatedAt: Date = Date(),
        isCompleted: Bool = false
    ) {
        self.userId = userId
        self.currentStep = currentStep
        self.completedSteps = completedSteps
        self.userPreferences = userPreferences
        self.startedAt = startedAt
        self.lastUpdatedAt = lastUpdatedAt
        self.isCompleted = isCompleted
    }

    /// Calculate completion progress
    var progress: Double {
        guard !OnboardingStep.allCases.isEmpty else { return 1.0 }
        return Double(completedSteps.count) / Double(OnboardingStep.allCases.count)
    }

    /// Check if a step can be accessed
    func canAccessStep(_ step: OnboardingStep) -> Bool {
        // Welcome is always accessible
        if step == .welcome { return true }

        // Check if prerequisites are completed
        return step.prerequisites.allSatisfy { completedSteps.contains($0) }
    }

    /// Get next available step
    var nextAvailableStep: OnboardingStep? {
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep) else { return nil }

        for index in (currentIndex + 1)..<allSteps.count {
            let step = allSteps[index]
            if canAccessStep(step) && !completedSteps.contains(step) {
                return step
            }
        }

        return nil
    }

    /// Get previous accessible step
    var previousAvailableStep: OnboardingStep? {
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep) else { return nil }

        for index in (0..<currentIndex).reversed() {
            let step = allSteps[index]
            if canAccessStep(step) {
                return step
            }
        }

        return nil
    }
}

// MARK: - Onboarding Steps Enumeration

enum OnboardingStep: String, Codable, CaseIterable, Hashable {
    case welcome = "welcome"
    case userProfile = "user_profile"
    case preferences = "preferences"
    case interests = "interests"
    case notifications = "notifications"
    case location = "location"
    case completion = "completion"

    /// Display name for the step
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
            return "Location Access"
        case .completion:
            return "Complete Setup"
        }
    }

    /// Description of what happens in this step
    var description: String {
        switch self {
        case .welcome:
            return "Welcome to Hobbyist! Let's get you set up."
        case .userProfile:
            return "Tell us a bit about yourself to personalize your experience."
        case .preferences:
            return "Set your preferences for class types and schedule."
        case .interests:
            return "Choose activities you're interested in exploring."
        case .notifications:
            return "Stay updated with class reminders and new activities."
        case .location:
            return "Find classes and activities near you."
        case .completion:
            return "You're all set! Welcome to the Hobbyist community."
        }
    }

    /// Icon for the step
    var iconName: String {
        switch self {
        case .welcome:
            return "hand.wave"
        case .userProfile:
            return "person.circle"
        case .preferences:
            return "slider.horizontal.3"
        case .interests:
            return "heart.circle"
        case .notifications:
            return "bell.circle"
        case .location:
            return "location.circle"
        case .completion:
            return "checkmark.circle"
        }
    }

    /// Whether this step can be skipped
    var isSkippable: Bool {
        switch self {
        case .welcome, .completion:
            return false
        case .userProfile, .preferences, .interests, .notifications, .location:
            return true
        }
    }

    /// Prerequisites that must be completed before this step
    var prerequisites: Set<OnboardingStep> {
        switch self {
        case .welcome:
            return []
        case .userProfile:
            return [.welcome]
        case .preferences:
            return [.welcome, .userProfile]
        case .interests:
            return [.welcome, .userProfile]
        case .notifications:
            return [.welcome, .userProfile]
        case .location:
            return [.welcome, .userProfile]
        case .completion:
            return [.welcome, .userProfile]
        }
    }

    /// Validation requirements for step completion
    func validateCompletion(with preferences: [String: Any]) -> ValidationResult {
        switch self {
        case .welcome:
            return .valid

        case .userProfile:
            let hasName = preferences["fullName"] as? String != nil
            return hasName ? .valid : .invalid("Full name is required")

        case .preferences:
            // Preferences are optional, always valid
            return .valid

        case .interests:
            let interests = preferences["selectedInterests"] as? [String] ?? []
            return interests.isEmpty ? .warning("Consider selecting at least one interest") : .valid

        case .notifications:
            // Notification preferences are optional
            return .valid

        case .location:
            // Location access is optional
            return .valid

        case .completion:
            return .valid
        }
    }
}

// MARK: - Validation Result

enum ValidationResult {
    case valid
    case warning(String)
    case invalid(String)

    var isValid: Bool {
        switch self {
        case .valid, .warning:
            return true
        case .invalid:
            return false
        }
    }

    var message: String? {
        switch self {
        case .valid:
            return nil
        case .warning(let message), .invalid(let message):
            return message
        }
    }
}

// MARK: - Onboarding Data Service Interface

protocol OnboardingDataServiceProtocol {
    /// Save onboarding state
    func saveOnboardingState(_ state: OnboardingState) async throws

    /// Load onboarding state for user
    func loadOnboardingState(for userId: String) async throws -> OnboardingState?

    /// Clear onboarding state
    func clearOnboardingState(for userId: String) async throws

    /// Save user preferences
    func saveUserPreferences(_ preferences: [String: Any], for userId: String) async throws

    /// Load user preferences
    func loadUserPreferences(for userId: String) async throws -> [String: Any]

    /// Mark onboarding as completed
    func markOnboardingCompleted(for userId: String) async throws

    /// Check if user has completed onboarding
    func hasCompletedOnboarding(userId: String) async throws -> Bool
}

// MARK: - Helper Type for Codable Any Values

struct AnyCodable: Codable, Equatable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simple equality check - could be enhanced
        return String(describing: lhs.value) == String(describing: rhs.value)
    }
}