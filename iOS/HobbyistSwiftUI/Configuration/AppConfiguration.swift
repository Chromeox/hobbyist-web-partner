import Foundation

/// Secure application configuration management
final class AppConfiguration {
    static let shared = AppConfiguration()
    
    private let keychain = KeychainService.shared
    
    private init() {
        loadConfiguration()
    }
    
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            if isTestFlight {
                return .staging
            }
            return .production
            #endif
        }
        
        private static var isTestFlight: Bool {
            Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        }
    }
    
    struct Configuration {
        let supabaseURL: String
        let supabaseAnonKey: String
        let environment: Environment
        let apiVersion: String
        let certificatePins: [String]
    }
    
    private(set) var current: Configuration?
    
    // MARK: - Configuration Loading
    
    private func loadConfiguration() {
        switch Environment.current {
        case .development:
            loadDevelopmentConfig()
        case .staging:
            loadStagingConfig()
        case .production:
            loadProductionConfig()
        }
    }
    
    private func loadDevelopmentConfig() {
        // In development, we can use environment variables or a local config file
        // Never commit actual values to source control
        if let configPath = Bundle.main.path(forResource: "Config-Dev", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: configPath) {
            current = Configuration(
                supabaseURL: config["SUPABASE_URL"] as? String ?? "",
                supabaseAnonKey: config["SUPABASE_ANON_KEY"] as? String ?? "",
                environment: .development,
                apiVersion: "v1",
                certificatePins: []
            )
        }
    }
    
    private func loadStagingConfig() {
        // Load from secure storage or remote configuration service
        loadSecureConfiguration(for: .staging)
    }
    
    private func loadProductionConfig() {
        // Load from secure storage or remote configuration service
        loadSecureConfiguration(for: .production)
    }
    
    private func loadSecureConfiguration(for environment: Environment) {
        // Try to load from Keychain first
        if let savedConfig = loadFromKeychain(environment: environment) {
            current = savedConfig
            return
        }
        
        // If not in Keychain, fetch from secure remote configuration service
        fetchRemoteConfiguration(environment: environment)
    }
    
    private func loadFromKeychain(environment: Environment) -> Configuration? {
        do {
            let key = KeychainService.KeychainKey.apiKey
            if let configData = try? keychain.getData(for: key) {
                let decoder = JSONDecoder()
                return try decoder.decode(Configuration.self, from: configData)
            }
        } catch {
            print("Failed to load configuration from Keychain: \(error)")
        }
        return nil
    }
    
    private func fetchRemoteConfiguration(environment: Environment) {
        // In production, this would fetch from a secure configuration service
        // For now, we'll use placeholder values that must be replaced
        print("⚠️ Remote configuration not implemented. Please configure via provisioning.")
    }
    
    // MARK: - Configuration Updates
    
    func updateConfiguration(_ config: Configuration) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(config)
            try keychain.save(data, for: .apiKey)
            current = config
        } catch {
            print("Failed to save configuration: \(error)")
        }
    }
    
    // MARK: - Validation
    
    func validateConfiguration() -> Bool {
        guard let config = current else {
            print("❌ No configuration loaded")
            return false
        }
        
        guard !config.supabaseURL.isEmpty,
              config.supabaseURL.hasPrefix("https://"),
              !config.supabaseAnonKey.isEmpty else {
            print("❌ Invalid configuration values")
            return false
        }
        
        return true
    }
    
    // MARK: - Certificate Pinning
    
    func getCertificatePins() -> [String] {
        current?.certificatePins ?? []
    }
}

// MARK: - Codable Support

extension AppConfiguration.Configuration: Codable {
    enum CodingKeys: String, CodingKey {
        case supabaseURL
        case supabaseAnonKey
        case environment
        case apiVersion
        case certificatePins
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        supabaseURL = try container.decode(String.self, forKey: .supabaseURL)
        supabaseAnonKey = try container.decode(String.self, forKey: .supabaseAnonKey)
        let envString = try container.decode(String.self, forKey: .environment)
        environment = envString == "production" ? .production : envString == "staging" ? .staging : .development
        apiVersion = try container.decode(String.self, forKey: .apiVersion)
        certificatePins = try container.decode([String].self, forKey: .certificatePins)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(supabaseURL, forKey: .supabaseURL)
        try container.encode(supabaseAnonKey, forKey: .supabaseAnonKey)
        let envString = environment == .production ? "production" : environment == .staging ? "staging" : "development"
        try container.encode(envString, forKey: .environment)
        try container.encode(apiVersion, forKey: .apiVersion)
        try container.encode(certificatePins, forKey: .certificatePins)
    }
}

// MARK: - Configuration Helper

extension AppConfiguration {
    
    var supabaseURL: String? {
        current?.supabaseURL
    }
    
    var supabaseAnonKey: String? {
        current?.supabaseAnonKey
    }
    
    var isProduction: Bool {
        current?.environment == .production
    }
    
    var requiresCertificatePinning: Bool {
        current?.environment != .development
    }
}