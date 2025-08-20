// CRITICAL_SECURITY_FIXES.swift
// Immediate security fixes required for HobbyistSwiftUI
// Priority: CRITICAL - Implement before production deployment

import Foundation
import Security
import CryptoKit
import LocalAuthentication

// MARK: - 1. Secure Token Storage with iOS Keychain

/// Secure keychain wrapper for sensitive data storage
class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
        case itemNotFound
        case invalidData
    }
    
    /// Securely save authentication token to keychain
    func saveAuthToken(_ token: String, account: String = "com.hobbyist.authtoken") throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false
        ]
        
        // Try to save
        var status = SecItemAdd(query as CFDictionary, nil)
        
        // If duplicate, update instead
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account
            ]
            
            let attributes: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            status = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    /// Retrieve authentication token from keychain
    func getAuthToken(account: String = "com.hobbyist.authtoken") throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }
        
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return token
    }
    
    /// Delete authentication token from keychain
    func deleteAuthToken(account: String = "com.hobbyist.authtoken") throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
    
    /// Save API key with biometric protection
    func saveAPIKey(_ key: String, requiresBiometric: Bool = true) throws {
        var context: LAContext?
        
        if requiresBiometric {
            context = LAContext()
            context?.localizedReason = "Access API credentials"
        }
        
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "com.hobbyist.apikey",
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: false
        ]
        
        if requiresBiometric, let context = context {
            query[kSecAttrAccessControl as String] = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                nil
            )
            query[kSecUseAuthenticationContext as String] = context
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            throw KeychainError.unknown(status)
        }
    }
}

// MARK: - 2. Secure Configuration Management

/// Environment-based configuration without hardcoded values
struct SecureConfiguration {
    enum Environment: String {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
    }
    
    /// Get Supabase URL from secure configuration
    static func getSupabaseURL() -> String? {
        // Never hardcode URLs - always load from environment or configuration
        return ProcessInfo.processInfo.environment["SUPABASE_URL"]
    }
    
    /// Get Supabase API key from keychain
    static func getSupabaseAPIKey() async throws -> String {
        return try KeychainService.shared.getAuthToken(account: "com.hobbyist.supabase.apikey")
    }
    
    /// Validate configuration at startup
    static func validateConfiguration() throws {
        guard getSupabaseURL() != nil else {
            throw ConfigurationError.missingSupabaseURL
        }
        
        // Additional validation as needed
    }
    
    enum ConfigurationError: LocalizedError {
        case missingSupabaseURL
        case missingAPIKey
        case invalidEnvironment
        
        var errorDescription: String? {
            switch self {
            case .missingSupabaseURL:
                return "Supabase URL not configured"
            case .missingAPIKey:
                return "API key not found in secure storage"
            case .invalidEnvironment:
                return "Invalid environment configuration"
            }
        }
    }
}

// MARK: - 3. Request Signing & Validation

/// Secure request signing for API calls
class RequestSigner {
    private let signingKey: SymmetricKey
    
    init(key: Data) {
        self.signingKey = SymmetricKey(data: key)
    }
    
    /// Sign request with HMAC-SHA256
    func signRequest(_ request: inout URLRequest) {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce = UUID().uuidString
        
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(nonce, forHTTPHeaderField: "X-Nonce")
        
        // Create signature payload
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path ?? ""
        let payload = "\(method):\(path):\(timestamp):\(nonce)"
        
        // Sign with HMAC
        let signature = HMAC<SHA256>.authenticationCode(
            for: Data(payload.utf8),
            using: signingKey
        )
        
        let signatureString = Data(signature).base64EncodedString()
        request.setValue(signatureString, forHTTPHeaderField: "X-Signature")
    }
    
    /// Validate request freshness (5-minute window)
    static func validateRequestTimestamp(_ timestamp: String) -> Bool {
        guard let requestTime = TimeInterval(timestamp) else { return false }
        
        let currentTime = Date().timeIntervalSince1970
        let timeDifference = abs(currentTime - requestTime)
        
        return timeDifference <= 300 // 5 minutes
    }
}

// MARK: - 4. Certificate Pinning

/// SSL Certificate pinning for secure connections
class CertificatePinner: NSObject, URLSessionDelegate {
    private let pinnedCertificates: [String: SecCertificate]
    
    override init() {
        var certificates: [String: SecCertificate] = [:]
        
        // Load pinned certificates from bundle
        if let supabaseCertPath = Bundle.main.path(forResource: "supabase", ofType: "cer"),
           let supabaseCertData = try? Data(contentsOf: URL(fileURLWithPath: supabaseCertPath)),
           let supabaseCert = SecCertificateCreateWithData(nil, supabaseCertData as CFData) {
            certificates["supabase.co"] = supabaseCert
        }
        
        if let stripeCertPath = Bundle.main.path(forResource: "stripe", ofType: "cer"),
           let stripeCertData = try? Data(contentsOf: URL(fileURLWithPath: stripeCertPath)),
           let stripeCert = SecCertificateCreateWithData(nil, stripeCertData as CFData) {
            certificates["api.stripe.com"] = stripeCert
        }
        
        self.pinnedCertificates = certificates
        super.init()
    }
    
    func urlSession(_ session: URLSession, 
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host.components(separatedBy: ".").suffix(2).joined(separator: "."),
              let pinnedCertificate = pinnedCertificates[host] else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Validate server trust
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)
        
        guard isValid else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Compare certificates
        let serverCertificateCount = SecTrustGetCertificateCount(serverTrust)
        
        for index in 0..<serverCertificateCount {
            guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, index) else {
                continue
            }
            
            if CFEqual(serverCertificate, pinnedCertificate) {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }
        
        // No matching certificate found
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}

// MARK: - 5. Secure Session Management

/// Secure session manager with timeout and validation
class SecureSessionManager {
    static let shared = SecureSessionManager()
    
    private var sessionTimer: Timer?
    private let sessionTimeout: TimeInterval = 900 // 15 minutes
    private var lastActivityTime: Date = Date()
    
    private init() {
        setupSessionMonitoring()
    }
    
    /// Setup session monitoring
    private func setupSessionMonitoring() {
        // Monitor app lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Start inactivity timer
        startInactivityTimer()
    }
    
    /// Track user activity
    func trackActivity() {
        lastActivityTime = Date()
    }
    
    /// Start inactivity timer
    private func startInactivityTimer() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.checkSessionTimeout()
        }
    }
    
    /// Check for session timeout
    private func checkSessionTimeout() {
        let timeSinceLastActivity = Date().timeIntervalSince(lastActivityTime)
        
        if timeSinceLastActivity > sessionTimeout {
            invalidateSession(reason: .timeout)
        }
    }
    
    /// Handle app entering background
    @objc private func appDidEnterBackground() {
        // Clear sensitive data from memory
        clearSensitiveData()
        
        // Optionally invalidate session for high-security apps
        if shouldInvalidateOnBackground() {
            invalidateSession(reason: .backgrounded)
        }
    }
    
    /// Handle app entering foreground
    @objc private func appWillEnterForeground() {
        // Check for jailbreak
        if JailbreakDetector.isJailbroken() {
            invalidateSession(reason: .jailbreakDetected)
            return
        }
        
        // Require re-authentication if needed
        if requiresReauthentication() {
            presentAuthenticationChallenge()
        }
    }
    
    /// Invalidate current session
    func invalidateSession(reason: SessionInvalidationReason) {
        // Clear tokens
        try? KeychainService.shared.deleteAuthToken()
        
        // Clear sensitive data
        clearSensitiveData()
        
        // Log security event
        logSecurityEvent(reason: reason)
        
        // Navigate to login
        navigateToLogin()
    }
    
    private func clearSensitiveData() {
        // Implementation to clear sensitive data from memory
    }
    
    private func shouldInvalidateOnBackground() -> Bool {
        // Determine based on security requirements
        return false
    }
    
    private func requiresReauthentication() -> Bool {
        // Check time since last authentication
        return false
    }
    
    private func presentAuthenticationChallenge() {
        // Present biometric or passcode authentication
    }
    
    private func logSecurityEvent(reason: SessionInvalidationReason) {
        // Log to security monitoring service
    }
    
    private func navigateToLogin() {
        // Navigate to login screen
    }
    
    enum SessionInvalidationReason {
        case timeout
        case backgrounded
        case jailbreakDetected
        case userLogout
        case securityEvent
    }
}

// MARK: - 6. Jailbreak Detection

/// Jailbreak detection utility
struct JailbreakDetector {
    /// Check if device is jailbroken
    static func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        
        // Check for common jailbreak files
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/usr/bin/ssh"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check if app can write outside sandbox
        let testPath = "/private/test_jailbreak.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            // Expected behavior on non-jailbroken device
        }
        
        // Check for suspicious URL schemes
        if UIApplication.shared.canOpenURL(URL(string: "cydia://")!) {
            return true
        }
        
        // Check dynamic library injection
        let suspiciousLibraries = [
            "SubstrateLoader.dylib",
            "SSLKillSwitch2.dylib",
            "SSLKillSwitch.dylib",
            "MobileSubstrate.dylib"
        ]
        
        for library in suspiciousLibraries {
            if dlopen(library, RTLD_NOW) != nil {
                return true
            }
        }
        
        return false
        #endif
    }
    
    /// Enable anti-debugging protection
    static func enableAntiDebugging() {
        #if !DEBUG
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        
        let result = sysctl(&mib, 4, &info, &size, nil, 0)
        
        if result == 0 && (info.kp_proc.p_flag & P_TRACED) != 0 {
            // Debugger detected, terminate app
            fatalError()
        }
        
        // Prevent debugging attachment
        ptrace(PT_DENY_ATTACH, 0, 0, 0)
        #endif
    }
}

// MARK: - 7. Secure String Handling

/// Secure string class that automatically zeros memory
class SecureString {
    private var data: Data
    
    init(_ string: String) {
        self.data = Data(string.utf8)
    }
    
    var string: String? {
        return String(data: data, encoding: .utf8)
    }
    
    deinit {
        // Securely zero memory
        data.withUnsafeMutableBytes { bytes in
            memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
        }
    }
}

// MARK: - Usage Examples

/*
// Replace insecure token storage:
// OLD:
UserDefaults.standard.set(token, forKey: "supabase_auth_token")

// NEW:
try KeychainService.shared.saveAuthToken(token)

// Replace hardcoded URLs:
// OLD:
self.baseURL = "https://mcjqvdzdhtcvbrejvrtp.supabase.co"

// NEW:
guard let baseURL = SecureConfiguration.getSupabaseURL() else {
    throw ConfigurationError.missingSupabaseURL
}
self.baseURL = baseURL

// Add request signing:
var request = URLRequest(url: url)
requestSigner.signRequest(&request)

// Enable certificate pinning:
let session = URLSession(configuration: .default, delegate: CertificatePinner(), delegateQueue: nil)

// Track user activity for session management:
SecureSessionManager.shared.trackActivity()

// Check for jailbreak on app launch:
if JailbreakDetector.isJailbroken() {
    // Show security warning and exit
    showSecurityAlert()
    exit(0)
}
*/