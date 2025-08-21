import Foundation

struct Configuration {
    static let shared = Configuration()
    
    // MARK: - API Keys
    
    var stripePublishableKey: String {
        // In production, use a more secure method like fetching from a secure backend
        #if DEBUG
        // Development key (starts with pk_test_)
        return ProcessInfo.processInfo.environment["STRIPE_PUBLISHABLE_KEY"] ?? "pk_test_YOUR_TEST_KEY_HERE"
        #else
        // Production key (starts with pk_live_)
        return ProcessInfo.processInfo.environment["STRIPE_PUBLISHABLE_KEY"] ?? "pk_live_YOUR_LIVE_KEY_HERE"
        #endif
    }
    
    var supabaseURL: String {
        #if DEBUG
        return ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://mcjqvdzdhtcvbrejvrtp.supabase.co"
        #else
        return ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        #endif
    }
    
    var supabaseAnonKey: String {
        #if DEBUG
        // This is the anon key (safe for client-side)
        return ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "YOUR_SUPABASE_ANON_KEY_HERE"
        #else
        return ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
        #endif
    }
    
    var appleMerchantId: String {
        return "merchant.com.hobbyist.app"
    }
    
    // MARK: - Feature Flags
    
    var isApplePayEnabled: Bool {
        return true
    }
    
    var isGamificationEnabled: Bool {
        return true
    }
    
    var isDebugMenuEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - URLs
    
    var termsOfServiceURL: String {
        return "https://hobbyist.app/terms"
    }
    
    var privacyPolicyURL: String {
        return "https://hobbyist.app/privacy"
    }
    
    var supportEmailAddress: String {
        return "support@hobbyist.app"
    }
    
    private init() {}
}