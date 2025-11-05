import Foundation
import LocalAuthentication
import SwiftUI

@MainActor
class BiometricAuthenticationService: ObservableObject {
    static let shared = BiometricAuthenticationService()

    @Published var biometricsAvailable = false
    @Published var biometricType: LABiometryType = .none

    private let keychain = KeychainHelper()

    private init() {
        checkBiometricAvailability()
    }

    // MARK: - Biometric Availability

    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        print("🔍 Checking biometric availability...")
        print("🔍 Device biometry type: \(context.biometryType.description)")

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricsAvailable = true
            biometricType = context.biometryType
            print("✅ Biometrics available: \(biometricType.description)")
            print("✅ canUseBiometrics() will return: \(canUseBiometrics())")
        } else {
            biometricsAvailable = false
            biometricType = .none
            print("❌ Biometrics not available: \(error?.localizedDescription ?? "Unknown error")")
            print("❌ Error code: \(error?.code ?? -1)")
            print("❌ canUseBiometrics() will return: \(canUseBiometrics())")
        }
    }

    // MARK: - Session Storage

    func saveLastUserSession(email: String, sessionToken: String) -> Bool {
        print("💾 Saving session for biometric authentication")
        let success1 = keychain.save(email, forKey: "last_user_email")
        let success2 = keychain.save(sessionToken, forKey: "last_user_session_\(email)")
        return success1 && success2
    }

    func getLastUserEmail() -> String? {
        return keychain.load(forKey: "last_user_email")
    }

    func getStoredSessionToken(for email: String) -> String? {
        return keychain.load(forKey: "last_user_session_\(email)")
    }
    
    // MARK: - Last Authentication Method Storage
    
    func saveLastAuthenticationMethod(_ method: String) {
        keychain.save(method, forKey: "last_auth_method")
        print("💾 Saved last auth method: \(method)")
    }
    
    func getLastAuthenticationMethod() -> String? {
        return keychain.load(forKey: "last_auth_method")
    }

    func deleteStoredSession(for email: String) {
        keychain.delete(forKey: "last_user_session_\(email)")
        keychain.delete(forKey: "last_user_email")
        print("🗑️ Deleted stored session for: \(email)")
    }

    // MARK: - Credential Storage (Legacy Support)

    func saveCredentials(email: String, password: String) -> Bool {
        print("💾 Saving credentials for biometric authentication")
        return keychain.save(password, forKey: "user_password_\(email)")
    }

    func getStoredCredentials(for email: String) -> String? {
        return keychain.load(forKey: "user_password_\(email)")
    }

    func deleteStoredCredentials(for email: String) {
        keychain.delete(forKey: "user_password_\(email)")
        print("🗑️ Deleted stored credentials for: \(email)")
    }

    // MARK: - Biometric Authentication

    func authenticateWithBiometrics(reason: String = "Use Face ID to sign in quickly") async -> Bool {
        guard biometricsAvailable else {
            print("❌ Biometrics not available")
            return false
        }

        let context = LAContext()
        context.localizedFallbackTitle = "Use Password"

        do {
            print("🔐 Requesting biometric authentication...")
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            if success {
                print("✅ Biometric authentication successful")
                return true
            } else {
                print("❌ Biometric authentication failed")
                return false
            }
        } catch {
            print("❌ Biometric authentication error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Convenience Methods

    func canUseBiometrics() -> Bool {
        return biometricsAvailable && biometricType != .none
    }

    func hasStoredUser() -> Bool {
        return getLastUserEmail() != nil
    }

    func canUseBiometricsIndependently() -> Bool {
        return canUseBiometrics() && hasStoredUser()
    }

    func biometricTypeDescription() -> String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "None"
        @unknown default:
            return "Biometric Authentication"
        }
    }
}

// MARK: - LABiometryType Extension

extension LABiometryType {
    var description: String {
        switch self {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        @unknown default:
            return "Unknown"
        }
    }
}

// MARK: - Keychain Helper

class KeychainHelper {
    func save(_ data: String, forKey key: String) -> Bool {
        guard let data = data.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            if let data = dataTypeRef as? Data,
               let string = String(data: data, encoding: .utf8) {
                return string
            }
        }

        return nil
    }

    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}