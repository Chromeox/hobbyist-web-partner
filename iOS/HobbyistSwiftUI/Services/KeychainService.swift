import Foundation
import Security

/// Secure storage service using iOS Keychain for sensitive data
final class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case invalidData
        case unhandledError(status: OSStatus)
        
        var localizedDescription: String {
            switch self {
            case .itemNotFound:
                return "Item not found in keychain"
            case .duplicateItem:
                return "Item already exists in keychain"
            case .invalidData:
                return "Invalid data format"
            case .unhandledError(let status):
                return "Keychain error: \(status)"
            }
        }
    }
    
    enum KeychainKey: String {
        case authToken = "com.hobbyist.auth.token"
        case refreshToken = "com.hobbyist.auth.refreshToken"
        case userCredentials = "com.hobbyist.auth.credentials"
        case apiKey = "com.hobbyist.api.key"
        case encryptionKey = "com.hobbyist.encryption.key"
        case sessionId = "com.hobbyist.session.id"
        case biometricCredentials = "com.hobbyist.biometric.credentials"
    }
    
    // MARK: - String Storage
    
    func save(_ string: String, for key: KeychainKey) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try save(data, for: key)
    }
    
    func getString(for key: KeychainKey) throws -> String {
        let data = try getData(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }
    
    // MARK: - Data Storage
    
    func save(_ data: Data, for key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: bundleIdentifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Try to delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.duplicateItem
            }
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func getData(for key: KeychainKey) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: bundleIdentifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = item as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    // MARK: - Codable Storage
    
    func save<T: Codable>(_ object: T, for key: KeychainKey) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try save(data, for: key)
    }
    
    func getObject<T: Codable>(_ type: T.Type, for key: KeychainKey) throws -> T {
        let data = try getData(for: key)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
    
    // MARK: - Deletion
    
    func delete(key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: bundleIdentifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: bundleIdentifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Biometric Protection
    
    func saveBiometricProtected(_ data: Data, for key: KeychainKey) throws {
        let context = LAContext()
        context.localizedReason = "Authenticate to access your secure data"
        
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            nil
        )
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: bundleIdentifier,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: access as Any,
            kSecUseAuthenticationContext as String: context
        ]
        
        // Try to delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func getBiometricProtected(for key: KeychainKey) throws -> Data {
        let context = LAContext()
        context.localizedReason = "Authenticate to access your secure data"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: bundleIdentifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = item as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    // MARK: - Helpers
    
    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.hobbyist.app"
    }
    
    func isAvailable() -> Bool {
        // Test keychain availability
        let testKey = KeychainKey.sessionId
        let testData = "test".data(using: .utf8)!
        
        do {
            try save(testData, for: testKey)
            _ = try getData(for: testKey)
            try delete(key: testKey)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - LocalAuthentication import for biometric support
import LocalAuthentication

// MARK: - Secure Token Manager

/// Manager for handling authentication tokens securely
final class SecureTokenManager {
    static let shared = SecureTokenManager()
    private let keychain = KeychainService.shared
    
    private init() {}
    
    struct AuthTokens: Codable {
        let accessToken: String
        let refreshToken: String?
        let expiresAt: Date
        let tokenType: String
        
        var isExpired: Bool {
            Date() >= expiresAt
        }
    }
    
    func saveTokens(_ tokens: AuthTokens) {
        do {
            try keychain.save(tokens, for: .authToken)
            print("✅ Tokens securely saved to Keychain")
        } catch {
            print("❌ Failed to save tokens: \(error)")
        }
    }
    
    func getTokens() -> AuthTokens? {
        do {
            return try keychain.getObject(AuthTokens.self, for: .authToken)
        } catch {
            print("❌ Failed to retrieve tokens: \(error)")
            return nil
        }
    }
    
    func getAccessToken() -> String? {
        guard let tokens = getTokens() else { return nil }
        
        if tokens.isExpired {
            // Token expired, should refresh
            return nil
        }
        
        return tokens.accessToken
    }
    
    func clearTokens() {
        do {
            try keychain.delete(key: .authToken)
            print("✅ Tokens cleared from Keychain")
        } catch {
            print("❌ Failed to clear tokens: \(error)")
        }
    }
    
    func saveAPIKey(_ apiKey: String) {
        do {
            try keychain.save(apiKey, for: .apiKey)
        } catch {
            print("❌ Failed to save API key: \(error)")
        }
    }
    
    func getAPIKey() -> String? {
        do {
            return try keychain.getString(for: .apiKey)
        } catch {
            return nil
        }
    }
}