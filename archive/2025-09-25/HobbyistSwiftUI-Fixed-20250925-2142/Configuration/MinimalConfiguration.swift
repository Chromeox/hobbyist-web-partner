import Foundation

// MARK: - Minimal Configuration
// Bare minimum configuration to satisfy service dependencies
// Replaces complex configuration system that was causing build failures

class Configuration {
    static let shared = Configuration()

    // Basic app configuration
    let appleMerchantId = "merchant.com.hobbyist.app"
    let supabaseURL = "https://mcjqvdzdhtcvbrejvrtp.supabase.co"
    let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1janF2ZHpkaHRjdmJyZWp2cnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5MDIzNzksImV4cCI6MjA2NDQ3ODM3OX0.puthoId8ElCgYzuyKJTTyzR9FeXmVA-Tkc8RV1rqdkc"

    private init() {}
}

class AppConfiguration {
    static let shared = AppConfiguration()
    var current: AppConfig? = AppConfig()

    private init() {}

    func getCertificatePins() -> [String]? {
        // Return nil for development - no certificate pinning
        return nil
    }
}

struct AppConfig {
    let environment: Environment = .development
    let apiBaseURL = "https://mcjqvdzdhtcvbrejvrtp.supabase.co"
    let enableLogging = true
}

enum Environment {
    case development
    case staging
    case production
}

// MARK: - Feature Flags
class FeatureFlagManager: ObservableObject {
    static let shared = FeatureFlagManager()

    private init() {}

    func isEnabled(_ feature: FeatureFlag) -> Bool {
        // All features enabled for MVP
        return true
    }
}

enum FeatureFlag {
    case onboardingModule
    case profileModule
    case paymentProcessing
    case pushNotifications
}

