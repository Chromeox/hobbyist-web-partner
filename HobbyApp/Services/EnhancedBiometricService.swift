import Foundation
import LocalAuthentication
import SwiftUI
import CryptoKit

// MARK: - Enhanced Biometric Authentication Service

/// Enterprise-grade biometric authentication with advanced security features
@MainActor
public class EnhancedBiometricService: ObservableObject {
    public static let shared = EnhancedBiometricService()
    
    @Published public var biometricsAvailable = false
    @Published public var biometricType: LABiometryType = .none
    @Published public var authenticationState: AuthenticationState = .unauthenticated
    @Published public var lastAuthenticationTime: Date?
    @Published public var authenticationAttempts: Int = 0
    @Published public var isTemporarilyLocked: Bool = false
    @Published public var lockoutTimeRemaining: TimeInterval = 0
    
    // Security configuration
    private let maxFailedAttempts = 5
    private let lockoutDuration: TimeInterval = 300 // 5 minutes
    private let sessionTimeout: TimeInterval = 900 // 15 minutes
    private let requireReauthenticationAfter: TimeInterval = 3600 // 1 hour
    
    // Security services
    private let keychain = KeychainManager.shared
    private let securityService = SecurityService.shared
    private let performanceMonitor = PerformanceMonitor.shared
    
    // State management
    private var lockoutTimer: Timer?
    private var sessionValidationTimer: Timer?
    private var biometricTemplate: Data?
    private var deviceTrustScore: Double = 0.0
    
    private init() {
        checkBiometricAvailability()
        loadAuthenticationState()
        setupSessionValidation()
        generateBiometricTemplate()
    }
    
    // MARK: - Public API
    
    /// Perform biometric authentication with enhanced security
    public func authenticateWithBiometrics(
        reason: String = "Authenticate to access your account",
        allowFallback: Bool = true,
        context: AuthenticationContext = .login
    ) async -> AuthenticationResult {
        return await performanceMonitor.trackOperation(
            name: "BiometricAuthentication",
            category: .authentication
        ) {
            await performBiometricAuthentication(
                reason: reason,
                allowFallback: allowFallback,
                context: context
            )
        }
    }
    
    /// Validate current authentication status
    public func validateCurrentAuthentication() async -> Bool {
        guard case .authenticated = authenticationState else {
            return false
        }
        
        guard let lastAuth = lastAuthenticationTime else {
            authenticationState = .unauthenticated
            return false
        }
        
        // Check if session has expired
        if Date().timeIntervalSince(lastAuth) > sessionTimeout {
            authenticationState = .sessionExpired
            return false
        }
        
        // Check if reauthentication is required
        if Date().timeIntervalSince(lastAuth) > requireReauthenticationAfter {
            authenticationState = .reauthenticationRequired
            return false
        }
        
        return true
    }
    
    /// Force reauthentication
    public func requireReauthentication() {
        authenticationState = .reauthenticationRequired
        print("🔄 Reauthentication required")
    }
    
    /// Check if biometric authentication is available and secure
    public func canUseBiometricsSecurely() -> Bool {
        return biometricsAvailable && 
               !isTemporarilyLocked && 
               deviceTrustScore > 0.7 &&
               isDeviceSecure()
    }
    
    /// Get detailed authentication status
    public func getAuthenticationStatus() -> AuthenticationStatus {
        return AuthenticationStatus(
            state: authenticationState,
            biometricType: biometricType,
            isAvailable: biometricsAvailable,
            isLocked: isTemporarilyLocked,
            lockoutTimeRemaining: lockoutTimeRemaining,
            failedAttempts: authenticationAttempts,
            deviceTrustScore: deviceTrustScore,
            lastAuthenticationTime: lastAuthenticationTime
        )
    }
    
    /// Enable biometric authentication for user
    public func enableBiometricAuthentication(for userID: String) async throws -> Bool {
        guard biometricsAvailable else {
            throw BiometricError.biometricsNotAvailable
        }
        
        // Authenticate to enable biometrics
        let result = await authenticateWithBiometrics(
            reason: "Enable biometric authentication for faster sign-in",
            context: .enrollment
        )
        
        guard case .success = result else {
            throw BiometricError.enrollmentFailed
        }
        
        // Generate and store biometric template
        let template = try generateSecureBiometricTemplate()
        try keychain.store(
            template,
            forKey: KeychainKeys.biometricTemplate + "_\(userID)",
            requireBiometrics: false // Template itself doesn't need biometric protection
        )
        
        // Store user preferences
        let preferences = SecureAppPreferences(enableBiometrics: true)
        try keychain.store(preferences, forKey: KeychainKeys.appPreferences)
        
        print("✅ Biometric authentication enabled for user: \(userID)")
        return true
    }
    
    /// Disable biometric authentication
    public func disableBiometricAuthentication(for userID: String) throws {
        try keychain.delete(forKey: KeychainKeys.biometricTemplate + "_\(userID)")
        
        var preferences = SecureAppPreferences(enableBiometrics: false)
        try keychain.store(preferences, forKey: KeychainKeys.appPreferences)
        
        authenticationState = .unauthenticated
        print("🔒 Biometric authentication disabled for user: \(userID)")
    }
    
    /// Store secure session after successful authentication
    public func storeSecureSession(userID: String, sessionData: SecureUserData) async throws {
        guard case .authenticated = authenticationState else {
            throw BiometricError.notAuthenticated
        }
        
        // Encrypt session data
        let encryptedData = try securityService.encryptData(
            try JSONEncoder().encode(sessionData),
            level: .maximum
        )
        
        try keychain.store(
            encryptedData,
            forKey: KeychainKeys.userData + "_\(userID)",
            requireBiometrics: true,
            accessibility: .whenUnlockedThisDeviceOnly
        )
        
        lastAuthenticationTime = Date()
        print("💾 Secure session stored for user: \(userID)")
    }
    
    /// Retrieve secure session data
    public func retrieveSecureSession(for userID: String) async throws -> SecureUserData? {
        let context = LAContext()
        context.localizedReason = "Access your secure session data"
        
        guard let encryptedData: Data = try await keychain.retrieve(
            Data.self,
            forKey: KeychainKeys.userData + "_\(userID)",
            context: context
        ) else {
            return nil
        }
        
        let decryptedData = try securityService.decryptData(encryptedData, level: .maximum)
        let sessionData = try JSONDecoder().decode(SecureUserData.self, from: decryptedData)
        
        // Validate session is still valid
        if Date().timeIntervalSince(sessionData.lastAuthTime) > sessionTimeout {
            try keychain.delete(forKey: KeychainKeys.userData + "_\(userID)")
            return nil
        }
        
        return sessionData
    }
    
    // MARK: - Private Implementation
    
    private func performBiometricAuthentication(
        reason: String,
        allowFallback: Bool,
        context: AuthenticationContext
    ) async -> AuthenticationResult {
        // Check if temporarily locked
        if isTemporarilyLocked {
            return .failure(.temporarilyLocked(timeRemaining: lockoutTimeRemaining))
        }
        
        // Check availability
        guard biometricsAvailable else {
            return .failure(.biometricsNotAvailable)
        }
        
        // Check device security
        guard isDeviceSecure() else {
            return .failure(.deviceNotSecure)
        }
        
        let authContext = LAContext()
        authContext.localizedFallbackTitle = allowFallback ? "Use App PIN" : ""
        authContext.localizedReason = reason
        
        // Set evaluation context
        authContext.localizedCancelTitle = "Cancel"
        authContext.touchIDAuthenticationAllowableReuseDuration = 30 // 30 seconds
        
        do {
            print("🔐 Requesting biometric authentication for \(context.rawValue)...")
            
            let success = try await authContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                // Successful authentication
                authenticationAttempts = 0
                authenticationState = .authenticated
                lastAuthenticationTime = Date()
                
                // Validate biometric template if available
                if let template = biometricTemplate {
                    let isValidTemplate = await validateBiometricTemplate(template, context: authContext)
                    if !isValidTemplate {
                        print("⚠️ Biometric template validation failed")
                        return .failure(.templateValidationFailed)
                    }
                }
                
                print("✅ Biometric authentication successful")
                
                // Log successful authentication
                await logAuthenticationEvent(
                    type: .biometricSuccess,
                    context: context,
                    deviceInfo: collectDeviceInfo()
                )
                
                return .success(AuthenticationDetails(
                    method: .biometric(biometricType),
                    timestamp: Date(),
                    context: context,
                    deviceTrustScore: deviceTrustScore
                ))
                
            } else {
                return await handleAuthenticationFailure(context: context)
            }
            
        } catch let error as LAError {
            return await handleLAError(error, context: context)
        } catch {
            print("❌ Unexpected biometric authentication error: \(error)")
            return .failure(.unknown(error))
        }
    }
    
    private func handleAuthenticationFailure(context: AuthenticationContext) async -> AuthenticationResult {
        authenticationAttempts += 1
        
        print("❌ Biometric authentication failed (attempt \(authenticationAttempts)/\(maxFailedAttempts))")
        
        await logAuthenticationEvent(
            type: .biometricFailure,
            context: context,
            deviceInfo: collectDeviceInfo()
        )
        
        if authenticationAttempts >= maxFailedAttempts {
            await lockTemporarily()
            return .failure(.tooManyAttempts)
        }
        
        authenticationState = .failed
        return .failure(.authenticationFailed(attemptsRemaining: maxFailedAttempts - authenticationAttempts))
    }
    
    private func handleLAError(_ error: LAError, context: AuthenticationContext) async -> AuthenticationResult {
        print("❌ LAError: \(error.localizedDescription) (Code: \(error.code.rawValue))")
        
        await logAuthenticationEvent(
            type: .biometricError,
            context: context,
            deviceInfo: collectDeviceInfo(),
            error: error.localizedDescription
        )
        
        switch error.code {
        case .userCancel:
            return .failure(.userCancelled)
        case .userFallback:
            return .failure(.userSelectedFallback)
        case .biometryNotAvailable:
            biometricsAvailable = false
            return .failure(.biometricsNotAvailable)
        case .biometryNotEnrolled:
            return .failure(.biometricsNotEnrolled)
        case .biometryLockout:
            await lockTemporarily()
            return .failure(.biometryLockout)
        case .authenticationFailed:
            return await handleAuthenticationFailure(context: context)
        default:
            return .failure(.unknown(error))
        }
    }
    
    private func lockTemporarily() async {
        isTemporarilyLocked = true
        lockoutTimeRemaining = lockoutDuration
        authenticationState = .temporarilyLocked
        
        print("🔒 Temporarily locked due to too many failed attempts")
        
        // Start countdown timer
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                self.lockoutTimeRemaining -= 1.0
                
                if self.lockoutTimeRemaining <= 0 {
                    await self.unlockAfterTimeout()
                    timer.invalidate()
                }
            }
        }
        
        // Reset failed attempts after lockout
        authenticationAttempts = 0
    }
    
    private func unlockAfterTimeout() async {
        isTemporarilyLocked = false
        lockoutTimeRemaining = 0
        authenticationState = .unauthenticated
        lockoutTimer?.invalidate()
        lockoutTimer = nil
        
        print("🔓 Lockout period expired, authentication available again")
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricsAvailable = true
            biometricType = context.biometryType
            print("✅ Biometrics available: \(biometricType.description)")
        } else {
            biometricsAvailable = false
            biometricType = .none
            print("❌ Biometrics not available: \(error?.localizedDescription ?? "Unknown error")")
        }
        
        // Update device trust score
        updateDeviceTrustScore()
    }
    
    private func loadAuthenticationState() {
        // Load previous authentication state if available
        if let lastAuth = UserDefaults.standard.object(forKey: "lastAuthenticationTime") as? Date {
            if Date().timeIntervalSince(lastAuth) < sessionTimeout {
                authenticationState = .authenticated
                lastAuthenticationTime = lastAuth
            }
        }
        
        authenticationAttempts = UserDefaults.standard.integer(forKey: "failedAuthAttempts")
    }
    
    private func setupSessionValidation() {
        // Check session validity every minute
        sessionValidationTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.validateCurrentAuthentication()
            }
        }
    }
    
    private func generateBiometricTemplate() {
        // Generate a unique template for this device/app combination
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let appID = Bundle.main.bundleIdentifier ?? "unknown"
        let timestamp = Date().timeIntervalSince1970
        
        let templateString = "\(deviceID)_\(appID)_\(timestamp)"
        biometricTemplate = Data(templateString.utf8)
    }
    
    private func generateSecureBiometricTemplate() throws -> Data {
        let deviceInfo = collectDeviceInfo()
        let templateData = try JSONEncoder().encode(deviceInfo)
        
        // Hash the template for security
        let hash = SHA256.hash(data: templateData)
        return Data(hash)
    }
    
    private func validateBiometricTemplate(_ template: Data, context: LAContext) async -> Bool {
        // Simplified template validation
        // In production, this would involve more sophisticated biometric template matching
        return template == biometricTemplate
    }
    
    private func isDeviceSecure() -> Bool {
        // Check if device has proper security measures
        let context = LAContext()
        var error: NSError?
        
        // Check if device has passcode
        let hasPasscode = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        
        // Additional security checks would go here
        return hasPasscode && biometricsAvailable
    }
    
    private func updateDeviceTrustScore() {
        var score: Double = 0.0
        
        // Base score for having biometrics
        if biometricsAvailable {
            score += 0.4
        }
        
        // Additional score for biometric type
        switch biometricType {
        case .faceID:
            score += 0.3
        case .touchID:
            score += 0.2
        case .opticID:
            score += 0.3
        default:
            break
        }
        
        // Score for device security
        if isDeviceSecure() {
            score += 0.3
        }
        
        deviceTrustScore = min(1.0, score)
        print("📊 Device trust score: \(String(format: "%.2f", deviceTrustScore))")
    }
    
    private func collectDeviceInfo() -> [String: Any] {
        return [
            "deviceModel": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion,
            "biometricType": biometricType.description,
            "timestamp": Date().timeIntervalSince1970,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
    }
    
    private func logAuthenticationEvent(
        type: AuthenticationEventType,
        context: AuthenticationContext,
        deviceInfo: [String: Any],
        error: String? = nil
    ) async {
        let event = AuthenticationEvent(
            type: type,
            context: context,
            timestamp: Date(),
            biometricType: biometricType,
            deviceInfo: deviceInfo,
            error: error
        )
        
        // Log to analytics service
        await performanceMonitor.trackOperation(
            name: "LogAuthenticationEvent",
            category: .authentication
        ) {
            // Implementation would send to analytics service
            print("📝 Logged authentication event: \(type.rawValue)")
        }
    }
    
    deinit {
        lockoutTimer?.invalidate()
        sessionValidationTimer?.invalidate()
    }
}

// MARK: - Supporting Types

public enum AuthenticationState: String, CaseIterable {
    case unauthenticated = "Unauthenticated"
    case authenticating = "Authenticating"
    case authenticated = "Authenticated"
    case failed = "Failed"
    case sessionExpired = "Session Expired"
    case reauthenticationRequired = "Reauthentication Required"
    case temporarilyLocked = "Temporarily Locked"
    
    public var description: String {
        return rawValue
    }
    
    public var color: Color {
        switch self {
        case .authenticated:
            return .green
        case .authenticating:
            return .blue
        case .failed, .sessionExpired, .temporarilyLocked:
            return .red
        case .reauthenticationRequired:
            return .orange
        case .unauthenticated:
            return .gray
        }
    }
}

public enum AuthenticationContext: String {
    case login = "login"
    case enrollment = "enrollment"
    case verification = "verification"
    case payment = "payment"
    case sensitiveData = "sensitive_data"
    case settings = "settings"
}

public enum AuthenticationResult {
    case success(AuthenticationDetails)
    case failure(BiometricError)
}

public enum BiometricError: Error, LocalizedError {
    case biometricsNotAvailable
    case biometricsNotEnrolled
    case deviceNotSecure
    case notAuthenticated
    case enrollmentFailed
    case templateValidationFailed
    case authenticationFailed(attemptsRemaining: Int)
    case userCancelled
    case userSelectedFallback
    case temporarilyLocked(timeRemaining: TimeInterval)
    case tooManyAttempts
    case biometryLockout
    case sessionExpired
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .biometricsNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricsNotEnrolled:
            return "No biometric data is enrolled on this device"
        case .deviceNotSecure:
            return "Device security requirements not met"
        case .notAuthenticated:
            return "User is not currently authenticated"
        case .enrollmentFailed:
            return "Failed to enroll biometric authentication"
        case .templateValidationFailed:
            return "Biometric template validation failed"
        case .authenticationFailed(let remaining):
            return "Authentication failed. \(remaining) attempts remaining"
        case .userCancelled:
            return "Authentication was cancelled by user"
        case .userSelectedFallback:
            return "User selected fallback authentication method"
        case .temporarilyLocked(let timeRemaining):
            return "Authentication temporarily locked. Try again in \(Int(timeRemaining)) seconds"
        case .tooManyAttempts:
            return "Too many failed attempts. Please try again later"
        case .biometryLockout:
            return "Biometric authentication is locked. Use device passcode to unlock"
        case .sessionExpired:
            return "Authentication session has expired"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

public struct AuthenticationDetails {
    public let method: AuthenticationMethod
    public let timestamp: Date
    public let context: AuthenticationContext
    public let deviceTrustScore: Double
}

public enum AuthenticationMethod {
    case biometric(LABiometryType)
    case passcode
    case fallback
    
    public var description: String {
        switch self {
        case .biometric(let type):
            return type.description
        case .passcode:
            return "Passcode"
        case .fallback:
            return "Fallback Authentication"
        }
    }
}

public struct AuthenticationStatus {
    public let state: AuthenticationState
    public let biometricType: LABiometryType
    public let isAvailable: Bool
    public let isLocked: Bool
    public let lockoutTimeRemaining: TimeInterval
    public let failedAttempts: Int
    public let deviceTrustScore: Double
    public let lastAuthenticationTime: Date?
    
    public var formattedLockoutTime: String {
        guard lockoutTimeRemaining > 0 else { return "" }
        let minutes = Int(lockoutTimeRemaining) / 60
        let seconds = Int(lockoutTimeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

public enum AuthenticationEventType: String {
    case biometricSuccess = "biometric_success"
    case biometricFailure = "biometric_failure"
    case biometricError = "biometric_error"
    case enrollment = "enrollment"
    case lockout = "lockout"
    case sessionExpired = "session_expired"
}

public struct AuthenticationEvent {
    public let type: AuthenticationEventType
    public let context: AuthenticationContext
    public let timestamp: Date
    public let biometricType: LABiometryType
    public let deviceInfo: [String: Any]
    public let error: String?
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
            return "Unknown Biometric Type"
        }
    }
}

// MARK: - SwiftUI Integration

public struct BiometricAuthenticationDebugView: View {
    @StateObject private var biometricService = EnhancedBiometricService.shared
    @State private var authenticationStatus: AuthenticationStatus?
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Biometric Authentication")
                .font(.headline)
            
            if let status = authenticationStatus {
                VStack(alignment: .leading, spacing: 8) {
                    statusRow("State", status.state.description)
                    statusRow("Type", status.biometricType.description)
                    statusRow("Available", status.isAvailable ? "Yes" : "No")
                    statusRow("Trust Score", String(format: "%.2f", status.deviceTrustScore))
                    statusRow("Failed Attempts", "\(status.failedAttempts)")
                    
                    if status.isLocked {
                        statusRow("Lockout Time", status.formattedLockoutTime)
                    }
                    
                    if let lastAuth = status.lastAuthenticationTime {
                        statusRow("Last Auth", RelativeDateTimeFormatter().localizedString(for: lastAuth, relativeTo: Date()))
                    }
                }
            }
            
            HStack {
                Button("Authenticate") {
                    Task {
                        let result = await biometricService.authenticateWithBiometrics(
                            reason: "Test biometric authentication"
                        )
                        
                        switch result {
                        case .success(let details):
                            print("✅ Authentication successful: \(details.method.description)")
                        case .failure(let error):
                            print("❌ Authentication failed: \(error.localizedDescription)")
                        }
                        
                        updateStatus()
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Refresh") {
                    updateStatus()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            updateStatus()
        }
    }
    
    private func statusRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
    
    private func updateStatus() {
        authenticationStatus = biometricService.getAuthenticationStatus()
    }
}

#Preview {
    BiometricAuthenticationDebugView()
        .padding()
}