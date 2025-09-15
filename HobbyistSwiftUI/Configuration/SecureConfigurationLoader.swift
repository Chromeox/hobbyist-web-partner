import Foundation
import Security

/// Secure configuration loader with fallback mechanisms
final class SecureConfigurationLoader {
    
    static func loadConfiguration(for environment: AppConfiguration.Environment) -> AppConfiguration.Configuration? {
        // Try loading from multiple sources in order of preference
        
        // 1. Try Keychain (most secure)
        if let config = loadFromKeychain(environment: environment) {
            print("✅ Configuration loaded from Keychain")
            return config
        }
        
        // 2. Try local plist file (development only)
        if environment == .development {
            if let config = loadFromPlist(environment: environment) {
                print("✅ Configuration loaded from plist")
                // Save to Keychain for next time
                saveToKeychain(config, environment: environment)
                return config
            }
        }
        
        // 3. Try environment variables (CI/CD)
        if let config = loadFromEnvironment(environment: environment) {
            print("✅ Configuration loaded from environment variables")
            // Save to Keychain for next time
            saveToKeychain(config, environment: environment)
            return config
        }
        
        // 4. Fallback to secure defaults (with warnings)
        if environment == .development {
            print("⚠️ Using fallback configuration - some features may not work")
            return createFallbackConfiguration(environment: environment)
        }
        
        // Production must have valid configuration
        print("❌ No valid configuration found for \(environment)")
        return nil
    }
    
    // MARK: - Keychain Loading
    
    private static func loadFromKeychain(environment: AppConfiguration.Environment) -> AppConfiguration.Configuration? {
        let keychain = KeychainService.shared
        let key = keychainKey(for: environment)
        
        do {
            let data = try keychain.getData(for: key)
            let decoder = JSONDecoder()
            return try decoder.decode(AppConfiguration.Configuration.self, from: data)
        } catch {
            // Silent fail - try other sources
            return nil
        }
    }
    
    private static func saveToKeychain(_ config: AppConfiguration.Configuration, environment: AppConfiguration.Environment) {
        let keychain = KeychainService.shared
        let key = keychainKey(for: environment)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(config)
            try keychain.save(data, for: key)
            print("💾 Configuration saved to Keychain")
        } catch {
            print("⚠️ Failed to save configuration to Keychain: \(error)")
        }
    }
    
    private static func keychainKey(for environment: AppConfiguration.Environment) -> KeychainService.KeychainKey {
        switch environment {
        case .development:
            return .apiKey // Reuse existing key for now
        case .staging, .production:
            return .apiKey
        }
    }
    
    // MARK: - Plist Loading
    
    private static func loadFromPlist(environment: AppConfiguration.Environment) -> AppConfiguration.Configuration? {
        let filename: String
        switch environment {
        case .development:
            filename = "Config-Dev"
        case .staging:
            filename = "Config-Staging"
        case .production:
            filename = "Config-Prod"
        }
        
        guard let path = Bundle.main.path(forResource: filename, ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("⚠️ Config file \(filename).plist not found")
            showConfigurationInstructions(filename: filename)
            return nil
        }
        
        // Validate required fields
        guard let supabaseURL = dict["SUPABASE_URL"] as? String,
              !supabaseURL.contains("YOUR_PROJECT_ID"),
              let supabaseKey = dict["SUPABASE_ANON_KEY"] as? String,
              !supabaseKey.contains("YOUR_") else {
            print("❌ Configuration file contains placeholder values")
            showConfigurationInstructions(filename: filename)
            return nil
        }
        
        // Certificate pins for production
        var certificatePins: [String] = []
        if environment != .development {
            certificatePins = dict["CERTIFICATE_PINS"] as? [String] ?? []
        }
        
        return AppConfiguration.Configuration(
            supabaseURL: supabaseURL,
            supabaseAnonKey: supabaseKey,
            environment: environment,
            apiVersion: dict["API_VERSION"] as? String ?? "v1",
            certificatePins: certificatePins
        )
    }
    
    // MARK: - Environment Variable Loading
    
    private static func loadFromEnvironment(environment: AppConfiguration.Environment) -> AppConfiguration.Configuration? {
        let processInfo = ProcessInfo.processInfo
        let env = processInfo.environment
        
        guard let supabaseURL = env["SUPABASE_URL"],
              let supabaseKey = env["SUPABASE_ANON_KEY"] else {
            return nil
        }
        
        // Parse certificate pins from comma-separated list
        let certificatePins = env["CERTIFICATE_PINS"]?.split(separator: ",").map(String.init) ?? []
        
        return AppConfiguration.Configuration(
            supabaseURL: supabaseURL,
            supabaseAnonKey: supabaseKey,
            environment: environment,
            apiVersion: env["API_VERSION"] ?? "v1",
            certificatePins: certificatePins
        )
    }
    
    // MARK: - Fallback Configuration
    
    private static func createFallbackConfiguration(environment: AppConfiguration.Environment) -> AppConfiguration.Configuration {
        // This should only be used in development for basic testing
        // Real values must be provided via proper configuration
        return AppConfiguration.Configuration(
            supabaseURL: "https://mcjqvdzdhtcvbrejvrtp.supabase.co",
            supabaseAnonKey: "placeholder_key_configure_properly",
            environment: environment,
            apiVersion: "v1",
            certificatePins: []
        )
    }
    
    // MARK: - Helper Methods
    
    private static func showConfigurationInstructions(filename: String) {
        print("""
        
        ============================================
        📋 CONFIGURATION SETUP REQUIRED
        ============================================
        
        1. Copy \(filename).plist.template to \(filename).plist
        2. Fill in your actual values:
           - SUPABASE_URL: Your Supabase project URL
           - SUPABASE_ANON_KEY: Your Supabase anon key
           - Other API keys as needed
        
        3. Make sure \(filename).plist is in .gitignore
        4. Never commit real API keys to version control
        
        For production, use:
        - Keychain storage (most secure)
        - Environment variables (CI/CD)
        - Remote configuration service
        
        ============================================
        
        """)
    }
    
    // MARK: - Validation
    
    static func validateConfiguration(_ config: AppConfiguration.Configuration) -> Bool {
        // Check URL format
        guard let url = URL(string: config.supabaseURL),
              url.scheme == "https" else {
            print("❌ Invalid Supabase URL format")
            return false
        }
        
        // Check key format (basic validation)
        guard !config.supabaseAnonKey.isEmpty,
              config.supabaseAnonKey.count > 20 else {
            print("❌ Invalid Supabase key format")
            return false
        }
        
        // Warn about placeholder values
        if config.supabaseAnonKey.contains("placeholder") {
            print("⚠️ Configuration contains placeholder values")
            return false
        }
        
        // Production requires certificate pins
        if config.environment == .production && config.certificatePins.isEmpty {
            print("⚠️ Production configuration missing certificate pins")
        }
        
        return true
    }
}

// MARK: - Configuration Migration

extension SecureConfigurationLoader {
    
    /// Migrate configuration from old storage to new secure storage
    static func migrateConfiguration() {
        // Check for old UserDefaults storage
        let defaults = UserDefaults.standard
        
        if let oldURL = defaults.string(forKey: "supabase_url"),
           let oldKey = defaults.string(forKey: "supabase_key") {
            
            print("🔄 Migrating old configuration to secure storage...")
            
            let config = AppConfiguration.Configuration(
                supabaseURL: oldURL,
                supabaseAnonKey: oldKey,
                environment: .production,
                apiVersion: "v1",
                certificatePins: []
            )
            
            saveToKeychain(config, environment: .production)
            
            // Remove old values
            defaults.removeObject(forKey: "supabase_url")
            defaults.removeObject(forKey: "supabase_key")
            
            print("✅ Configuration migrated successfully")
        }
    }
}