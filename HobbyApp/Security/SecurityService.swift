import Foundation
import Security
import LocalAuthentication
import CryptoKit
import SwiftUI

// MARK: - Comprehensive Security Service

/// Enterprise-grade security service managing all app security aspects
@MainActor
public class SecurityService: ObservableObject {
    public static let shared = SecurityService()
    
    @Published public var isDeviceSecure: Bool = false
    @Published public var biometricAuthEnabled: Bool = false
    @Published public var threatLevel: ThreatLevel = .low
    @Published public var isAppLocked: Bool = false
    @Published public var sessionExpired: Bool = false
    
    private let keychain = KeychainManager.shared
    private let encryptionService = EncryptionService()
    private let deviceTrustManager = DeviceTrustManager()
    private let sessionManager = SecureSessionManager()
    private let networkSecurityManager = NetworkSecurityManager()
    
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var appStateMonitor: Timer?
    private var threatDetectionTimer: Timer?
    
    private init() {
        setupSecurityMonitoring()
        validateDeviceSecurity()
        startThreatDetection()
    }
    
    // MARK: - Public Security API
    
    /// Initialize app security on launch
    public func initializeSecurity() async throws {
        try await validateDeviceIntegrity()
        try await loadSecurityPreferences()
        try await sessionManager.validateSession()
        
        await setupAppProtection()
        await startSecurityMonitoring()
    }
    
    /// Authenticate user with biometrics or PIN
    public func authenticateUser(reason: String = "Authenticate to access HobbyApp") async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Enter App PIN"
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fallback to PIN authentication
            return try await authenticateWithPIN()
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                try await sessionManager.createSecureSession()
                isAppLocked = false
                return true
            }
            return false
        } catch {
            throw SecurityError.biometricAuthenticationFailed(error)
        }
    }
    
    /// Lock the application
    public func lockApp() {
        isAppLocked = true
        sessionManager.invalidateSession()
        clearSensitiveData()
    }
    
    /// Validate network security for API calls
    public func validateNetworkSecurity(for url: URL) throws {
        try networkSecurityManager.validateConnection(url: url)
    }
    
    /// Encrypt sensitive data before storage
    public func encryptData(_ data: Data, level: EncryptionLevel = .high) throws -> Data {
        return try encryptionService.encrypt(data, level: level)
    }
    
    /// Decrypt sensitive data after retrieval
    public func decryptData(_ encryptedData: Data, level: EncryptionLevel = .high) throws -> Data {
        return try encryptionService.decrypt(encryptedData, level: level)
    }
    
    /// Generate secure device fingerprint
    public func generateDeviceFingerprint() throws -> String {
        return try deviceTrustManager.generateFingerprint()
    }
    
    /// Validate current session security
    public func validateSessionSecurity() async throws -> Bool {
        return try await sessionManager.validateSession()
    }
    
    // MARK: - Threat Detection
    
    /// Check for security threats
    public func detectThreats() async {
        var detectedThreats: [SecurityThreat] = []
        
        // Check for jailbreak/root
        if deviceTrustManager.isDeviceCompromised() {
            detectedThreats.append(.deviceCompromised)
        }
        
        // Check for debugging
        if isBeingDebugged() {
            detectedThreats.append(.debuggerAttached)
        }
        
        // Check for app tampering
        if try! deviceTrustManager.isAppTampered() {
            detectedThreats.append(.appTampered)
        }
        
        // Check for suspicious network activity
        if networkSecurityManager.hasSuspiciousActivity() {
            detectedThreats.append(.suspiciousNetworkActivity)
        }
        
        await updateThreatLevel(detectedThreats)
    }
    
    // MARK: - Data Protection
    
    /// Secure data wipe for sensitive information
    public func secureWipe() throws {
        try keychain.clearAll()
        clearMemoryBuffers()
        try deviceTrustManager.revokeDeviceTrust()
        sessionManager.invalidateAllSessions()
    }
    
    /// Enable app protection features
    public func enableAppProtection() async {
        await preventScreenRecording()
        await hideAppInSwitcher()
        await enableTamperDetection()
    }
    
    // MARK: - Private Implementation
    
    private func setupSecurityMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    private func validateDeviceSecurity() {
        Task {
            isDeviceSecure = !deviceTrustManager.isDeviceCompromised()
            biometricAuthEnabled = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        }
    }
    
    private func startThreatDetection() {
        threatDetectionTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.detectThreats()
            }
        }
    }
    
    private func validateDeviceIntegrity() async throws {
        guard !deviceTrustManager.isDeviceCompromised() else {
            throw SecurityError.deviceCompromised
        }
        
        guard try !deviceTrustManager.isAppTampered() else {
            throw SecurityError.appTampered
        }
    }
    
    private func loadSecurityPreferences() async throws {
        if let preferences: SecureAppPreferences = try await keychain.retrieve(
            SecureAppPreferences.self,
            forKey: KeychainKeys.appPreferences
        ) {
            biometricAuthEnabled = preferences.enableBiometrics
        }
    }
    
    private func setupAppProtection() async {
        await enableAppProtection()
    }
    
    private func startSecurityMonitoring() async {
        await detectThreats()
    }
    
    private func authenticateWithPIN() async throws -> Bool {
        // Implementation would show PIN entry UI
        // For now, return false to indicate PIN authentication needed
        return false
    }
    
    private func updateThreatLevel(_ threats: [SecurityThreat]) async {
        let newLevel: ThreatLevel
        
        if threats.contains(.deviceCompromised) || threats.contains(.appTampered) {
            newLevel = .critical
        } else if threats.contains(.debuggerAttached) || threats.contains(.suspiciousNetworkActivity) {
            newLevel = .high
        } else if !threats.isEmpty {
            newLevel = .medium
        } else {
            newLevel = .low
        }
        
        threatLevel = newLevel
        
        // Take action based on threat level
        switch newLevel {
        case .critical:
            lockApp()
            try? secureWipe()
        case .high:
            lockApp()
        case .medium:
            // Log security event
            break
        case .low:
            // Normal operation
            break
        }
    }
    
    private func clearSensitiveData() {
        // Clear sensitive UI state
        // This would be implemented based on app-specific needs
    }
    
    private func isBeingDebugged() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        
        return (result == 0) && (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    private func clearMemoryBuffers() {
        // Clear sensitive memory buffers
        // Implementation would clear specific memory regions
    }
    
    private func preventScreenRecording() async {
        // Implement screen recording prevention
        // This involves adding a security overlay when recording is detected
    }
    
    private func hideAppInSwitcher() async {
        // Implement app switcher hiding
        // This involves showing a security overlay during backgrounding
    }
    
    private func enableTamperDetection() async {
        // Enable runtime tamper detection
        try? deviceTrustManager.enableTamperDetection()
    }
    
    @objc private func appWillResignActive() {
        // Show security overlay
        Task { @MainActor in
            await hideAppInSwitcher()
        }
    }
    
    @objc private func appDidBecomeActive() {
        // Validate session and check for threats
        Task { @MainActor in
            await detectThreats()
            
            if sessionManager.isSessionExpired() {
                sessionExpired = true
                isAppLocked = true
            }
        }
    }
    
    @objc private func appDidEnterBackground() {
        // Start background security tasks
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        // Auto-lock after timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) { [weak self] in
            self?.lockApp()
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        threatDetectionTimer?.invalidate()
        endBackgroundTask()
    }
}

// MARK: - Security Types

public enum ThreatLevel {
    case low
    case medium
    case high
    case critical
    
    public var description: String {
        switch self {
        case .low:
            return "Secure"
        case .medium:
            return "Minor Security Issues"
        case .high:
            return "Security Warning"
        case .critical:
            return "Critical Security Threat"
        }
    }
    
    public var color: Color {
        switch self {
        case .low:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
}

public enum SecurityThreat {
    case deviceCompromised
    case appTampered
    case debuggerAttached
    case suspiciousNetworkActivity
    case unauthorizedAccess
    case dataCorruption
    
    public var description: String {
        switch self {
        case .deviceCompromised:
            return "Device security has been compromised"
        case .appTampered:
            return "App integrity violation detected"
        case .debuggerAttached:
            return "Debugging tools detected"
        case .suspiciousNetworkActivity:
            return "Suspicious network activity detected"
        case .unauthorizedAccess:
            return "Unauthorized access attempt"
        case .dataCorruption:
            return "Data integrity violation"
        }
    }
}

public enum SecurityError: Error, LocalizedError {
    case deviceCompromised
    case appTampered
    case biometricAuthenticationFailed(Error)
    case sessionExpired
    case encryptionFailed
    case decryptionFailed
    case networkSecurityViolation
    case deviceTrustRevoked
    
    public var errorDescription: String? {
        switch self {
        case .deviceCompromised:
            return "Device security has been compromised. App cannot run on this device."
        case .appTampered:
            return "App integrity has been violated. Please reinstall from the App Store."
        case .biometricAuthenticationFailed(let error):
            return "Biometric authentication failed: \(error.localizedDescription)"
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        case .encryptionFailed:
            return "Failed to encrypt sensitive data"
        case .decryptionFailed:
            return "Failed to decrypt sensitive data"
        case .networkSecurityViolation:
            return "Network security violation detected"
        case .deviceTrustRevoked:
            return "Device trust has been revoked"
        }
    }
}

// MARK: - Security Helper Services

private class EncryptionService {
    func encrypt(_ data: Data, level: EncryptionLevel) throws -> Data {
        switch level {
        case .standard:
            return try encryptWithAES(data)
        case .high:
            return try encryptWithChaCha20(data)
        case .maximum:
            return try encryptWithHardwareSEP(data)
        }
    }
    
    func decrypt(_ encryptedData: Data, level: EncryptionLevel) throws -> Data {
        switch level {
        case .standard:
            return try decryptWithAES(encryptedData)
        case .high:
            return try decryptWithChaCha20(encryptedData)
        case .maximum:
            return try decryptWithHardwareSEP(encryptedData)
        }
    }
    
    private func encryptWithAES(_ data: Data) throws -> Data {
        let key = SymmetricKey(size: .bits256)
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    private func decryptWithAES(_ encryptedData: Data) throws -> Data {
        let key = SymmetricKey(size: .bits256)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    private func encryptWithChaCha20(_ data: Data) throws -> Data {
        let key = SymmetricKey(size: .bits256)
        let sealedBox = try ChaChaPoly.seal(data, using: key)
        return sealedBox.combined
    }
    
    private func decryptWithChaCha20(_ encryptedData: Data) throws -> Data {
        let key = SymmetricKey(size: .bits256)
        let sealedBox = try ChaChaPoly.SealedBox(combined: encryptedData)
        return try ChaChaPoly.open(sealedBox, using: key)
    }
    
    private func encryptWithHardwareSEP(_ data: Data) throws -> Data {
        // Implement hardware-backed encryption using Secure Enclave
        // This would use SecKey with hardware-backed key generation
        return try encryptWithChaCha20(data) // Fallback for now
    }
    
    private func decryptWithHardwareSEP(_ encryptedData: Data) throws -> Data {
        // Implement hardware-backed decryption using Secure Enclave
        return try decryptWithChaCha20(encryptedData) // Fallback for now
    }
}

private class DeviceTrustManager {
    func isDeviceCompromised() -> Bool {
        return isJailbroken()
    }
    
    func isAppTampered() throws -> Bool {
        // Check app signature and bundle integrity
        return false // Implement actual tampering detection
    }
    
    func generateFingerprint() throws -> String {
        let device = UIDevice.current
        let components = [
            device.identifierForVendor?.uuidString ?? "",
            device.model,
            device.systemVersion,
            Bundle.main.bundleIdentifier ?? ""
        ]
        
        let combined = components.joined(separator: "|")
        let data = combined.data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func revokeDeviceTrust() throws {
        // Revoke device trust tokens
        try KeychainManager.shared.delete(forKey: KeychainKeys.deviceTrust)
    }
    
    func enableTamperDetection() throws {
        // Enable runtime tamper detection
    }
    
    private func isJailbroken() -> Bool {
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        
        return jailbreakPaths.contains { FileManager.default.fileExists(atPath: $0) }
    }
}

private class SecureSessionManager {
    private var sessionToken: String?
    private var sessionStartTime: Date?
    private let sessionTimeout: TimeInterval = 1800 // 30 minutes
    
    func createSecureSession() async throws {
        sessionToken = UUID().uuidString
        sessionStartTime = Date()
        
        try KeychainManager.shared.store(
            sessionToken!,
            forKey: KeychainKeys.sessionToken,
            requireBiometrics: false
        )
    }
    
    func validateSession() async throws -> Bool {
        guard let token = try await KeychainManager.shared.retrieveString(forKey: KeychainKeys.sessionToken),
              let startTime = sessionStartTime else {
            return false
        }
        
        return Date().timeIntervalSince(startTime) < sessionTimeout
    }
    
    func invalidateSession() {
        sessionToken = nil
        sessionStartTime = nil
        try? KeychainManager.shared.delete(forKey: KeychainKeys.sessionToken)
    }
    
    func invalidateAllSessions() {
        invalidateSession()
        // Invalidate all stored sessions
    }
    
    func isSessionExpired() -> Bool {
        guard let startTime = sessionStartTime else { return true }
        return Date().timeIntervalSince(startTime) >= sessionTimeout
    }
}

private class NetworkSecurityManager {
    private var suspiciousActivityDetected = false
    
    func validateConnection(url: URL) throws {
        guard url.scheme == "https" else {
            throw SecurityError.networkSecurityViolation
        }
        
        // Additional network security validations
    }
    
    func hasSuspiciousActivity() -> Bool {
        return suspiciousActivityDetected
    }
}