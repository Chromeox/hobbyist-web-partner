import Foundation
import Security

// MARK: - Keychain Keys

enum KeychainKeys {
    static let userToken = "user_token"
    static let refreshToken = "refresh_token"
    static let userId = "user_id"
    static let userEmail = "user_email"
    static let sessionToken = "session_token"
    static let lastAuthMethod = "last_auth_method"
    static let biometricEnabled = "biometric_enabled"
}

// MARK: - Secure User Data

struct SecureUserData: Codable {
    let id: String
    let email: String
    let sessionToken: String?
    let refreshToken: String?
    let createdAt: Date
    
    init(id: String, email: String, sessionToken: String? = nil, refreshToken: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.sessionToken = sessionToken
        self.refreshToken = refreshToken
        self.createdAt = createdAt
    }
}

// MARK: - Secure App Preferences

struct SecureAppPreferences: Codable {
    var biometricAuthEnabled: Bool
    var lastLoginDate: Date?
    var sessionExpiryDate: Date?
    
    init(biometricAuthEnabled: Bool = false, lastLoginDate: Date? = nil, sessionExpiryDate: Date? = nil) {
        self.biometricAuthEnabled = biometricAuthEnabled
        self.lastLoginDate = lastLoginDate
        self.sessionExpiryDate = sessionExpiryDate
    }
}

// MARK: - Keychain Manager

class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Save
    
    func save(_ data: String, forKey key: String) -> Bool {
        guard let data = data.data(using: .utf8) else { return false }
        return save(data, forKey: key)
    }
    
    func save(_ data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Load
    
    func load(forKey key: String) -> String? {
        guard let data = loadData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func loadData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return data
        }
        
        return nil
    }
    
    // MARK: - Delete
    
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Convenience Methods
    
    func saveSecureUserData(_ userData: SecureUserData) -> Bool {
        guard let encoded = try? JSONEncoder().encode(userData) else { return false }
        return save(encoded, forKey: KeychainKeys.userId)
    }
    
    func loadSecureUserData() -> SecureUserData? {
        guard let data = loadData(forKey: KeychainKeys.userId),
              let decoded = try? JSONDecoder().decode(SecureUserData.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    func deleteSecureUserData() -> Bool {
        return delete(forKey: KeychainKeys.userId)
    }
}

// MARK: - Security Service

class SecurityService {
    static let shared = SecurityService()
    
    private let keychainManager = KeychainManager.shared
    
    private init() {}
    
    // MARK: - Token Management
    
    func saveToken(_ token: String, forKey key: String) -> Bool {
        return keychainManager.save(token, forKey: key)
    }
    
    func loadToken(forKey key: String) -> String? {
        return keychainManager.load(forKey: key)
    }
    
    func deleteToken(forKey key: String) -> Bool {
        return keychainManager.delete(forKey: key)
    }
    
    // MARK: - User Data Management
    
    func saveUserData(_ userData: SecureUserData) -> Bool {
        return keychainManager.saveSecureUserData(userData)
    }
    
    func loadUserData() -> SecureUserData? {
        return keychainManager.loadSecureUserData()
    }
    
    func deleteUserData() -> Bool {
        return keychainManager.deleteSecureUserData()
    }
    
    // MARK: - Session Management
    
    func clearAllSecureData() {
        _ = keychainManager.delete(forKey: KeychainKeys.userToken)
        _ = keychainManager.delete(forKey: KeychainKeys.refreshToken)
        _ = keychainManager.delete(forKey: KeychainKeys.userId)
        _ = keychainManager.delete(forKey: KeychainKeys.userEmail)
        _ = keychainManager.delete(forKey: KeychainKeys.sessionToken)
        _ = keychainManager.deleteSecureUserData()
    }
}
