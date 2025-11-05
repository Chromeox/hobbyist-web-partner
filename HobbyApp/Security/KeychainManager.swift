import Foundation
import Security
import LocalAuthentication

// MARK: - Keychain Manager for Secure Data Storage

/// Enterprise-grade keychain management with biometric authentication
public class KeychainManager {
    public static let shared = KeychainManager()
    
    private let service = Bundle.main.bundleIdentifier ?? "com.hobbyapp.secure"
    private let accessGroup: String?
    
    private init() {
        // Configure keychain access group for app group sharing if needed
        self.accessGroup = nil // Set to app group identifier if using shared keychain
    }
    
    // MARK: - Public API
    
    /// Store data securely in keychain with optional biometric protection
    public func store<T: Codable>(
        _ data: T,
        forKey key: String,
        requireBiometrics: Bool = false,
        accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly
    ) throws {
        let encodedData = try JSONEncoder().encode(data)
        try storeData(encodedData, forKey: key, requireBiometrics: requireBiometrics, accessibility: accessibility)
    }
    
    /// Retrieve data from keychain with automatic biometric authentication if required
    public func retrieve<T: Codable>(
        _ type: T.Type,
        forKey key: String,
        context: LAContext? = nil
    ) async throws -> T? {
        guard let data = try await retrieveData(forKey: key, context: context) else {
            return nil
        }
        return try JSONDecoder().decode(type, from: data)
    }
    
    /// Store string securely
    public func store(
        _ string: String,
        forKey key: String,
        requireBiometrics: Bool = false,
        accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly
    ) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try storeData(data, forKey: key, requireBiometrics: requireBiometrics, accessibility: accessibility)
    }
    
    /// Retrieve string from keychain
    public func retrieveString(forKey key: String, context: LAContext? = nil) async throws -> String? {
        guard let data = try await retrieveData(forKey: key, context: context) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    /// Delete item from keychain
    public func delete(forKey key: String) throws {
        let query = baseQuery(forKey: key)
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deletionFailed(status)
        }
    }
    
    /// Clear all keychain data for this app
    public func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.clearAllFailed(status)
        }
    }
    
    /// Check if item exists in keychain
    public func exists(forKey key: String) -> Bool {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanFalse
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Private Implementation
    
    private func storeData(
        _ data: Data,
        forKey key: String,
        requireBiometrics: Bool,
        accessibility: KeychainAccessibility
    ) throws {
        // Delete existing item first
        try? delete(forKey: key)
        
        var query = baseQuery(forKey: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = accessibility.rawValue
        
        if requireBiometrics {
            query[kSecAttrAccessControl as String] = try createAccessControl(requireBiometrics: true)
        }
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storageFailed(status)
        }
    }
    
    private func retrieveData(forKey key: String, context: LAContext?) async throws -> Data? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        if let context = context {
            query[kSecUseAuthenticationContext as String] = context
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        case errSecUserCancel:
            throw KeychainError.userCancelled
        case errSecAuthFailed:
            throw KeychainError.authenticationFailed
        default:
            throw KeychainError.retrievalFailed(status)
        }
    }
    
    private func baseQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
    
    private func createAccessControl(requireBiometrics: Bool) throws -> SecAccessControl {
        var flags: SecAccessControlCreateFlags = []
        
        if requireBiometrics {
            flags.insert(.biometryAny)
        }
        
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            flags,
            &error
        ) else {
            if let error = error?.takeRetainedValue() {
                throw KeychainError.accessControlCreationFailed(error)
            } else {
                throw KeychainError.accessControlCreationFailed(nil)
            }
        }
        
        return accessControl
    }
}

// MARK: - Keychain Configuration Types

public enum KeychainAccessibility {
    case whenUnlocked
    case whenUnlockedThisDeviceOnly
    case whenPasscodeSetThisDeviceOnly
    case afterFirstUnlock
    case afterFirstUnlockThisDeviceOnly
    
    var rawValue: CFString {
        switch self {
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
}

// MARK: - Keychain Errors

public enum KeychainError: Error, LocalizedError {
    case invalidData
    case storageFailed(OSStatus)
    case retrievalFailed(OSStatus)
    case deletionFailed(OSStatus)
    case clearAllFailed(OSStatus)
    case userCancelled
    case authenticationFailed
    case accessControlCreationFailed(CFError?)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .storageFailed(let status):
            return "Failed to store item in keychain: \(status)"
        case .retrievalFailed(let status):
            return "Failed to retrieve item from keychain: \(status)"
        case .deletionFailed(let status):
            return "Failed to delete item from keychain: \(status)"
        case .clearAllFailed(let status):
            return "Failed to clear keychain: \(status)"
        case .userCancelled:
            return "User cancelled authentication"
        case .authenticationFailed:
            return "Authentication failed"
        case .accessControlCreationFailed(let error):
            return "Failed to create access control: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}

// MARK: - Secure Data Models

/// Secure wrapper for sensitive user data
public struct SecureUserData: Codable {
    public let userID: String
    public let email: String
    public let sessionToken: String
    public let refreshToken: String
    public let encryptedPaymentMethods: Data?
    public let biometricHash: String?
    public let lastAuthTime: Date
    
    public init(
        userID: String,
        email: String,
        sessionToken: String,
        refreshToken: String,
        encryptedPaymentMethods: Data? = nil,
        biometricHash: String? = nil
    ) {
        self.userID = userID
        self.email = email
        self.sessionToken = sessionToken
        self.refreshToken = refreshToken
        self.encryptedPaymentMethods = encryptedPaymentMethods
        self.biometricHash = biometricHash
        self.lastAuthTime = Date()
    }
}

/// Secure app preferences
public struct SecureAppPreferences: Codable {
    public let enableBiometrics: Bool
    public let autoLockTimeout: TimeInterval
    public let encryptionLevel: EncryptionLevel
    public let allowScreenshots: Bool
    public let requirePinForPayments: Bool
    
    public init(
        enableBiometrics: Bool = true,
        autoLockTimeout: TimeInterval = 300, // 5 minutes
        encryptionLevel: EncryptionLevel = .high,
        allowScreenshots: Bool = false,
        requirePinForPayments: Bool = true
    ) {
        self.enableBiometrics = enableBiometrics
        self.autoLockTimeout = autoLockTimeout
        self.encryptionLevel = encryptionLevel
        self.allowScreenshots = allowScreenshots
        self.requirePinForPayments = requirePinForPayments
    }
}

public enum EncryptionLevel: String, Codable, CaseIterable {
    case standard = "standard"
    case high = "high"
    case maximum = "maximum"
    
    public var description: String {
        switch self {
        case .standard:
            return "Standard encryption for basic protection"
        case .high:
            return "High-level encryption for sensitive data"
        case .maximum:
            return "Maximum encryption with hardware security"
        }
    }
}

// MARK: - Keychain Keys Constants

public struct KeychainKeys {
    public static let userData = "secure_user_data"
    public static let appPreferences = "secure_app_preferences"
    public static let biometricTemplate = "biometric_template"
    public static let sessionToken = "session_token"
    public static let refreshToken = "refresh_token"
    public static let paymentMethods = "encrypted_payment_methods"
    public static let deviceTrust = "device_trust_token"
    public static let appPin = "app_pin_hash"
    
    private init() {} // Prevent instantiation
}