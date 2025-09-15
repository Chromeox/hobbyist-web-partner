import Foundation
import UIKit
import LocalAuthentication
import CryptoKit

/// Comprehensive security manager for iOS app protection
final class SecurityManager {
    static let shared = SecurityManager()
    
    private init() {}
    
    // MARK: - Jailbreak Detection
    
    /// Check if device is jailbroken using multiple detection methods
    var isJailbroken: Bool {
        #if targetEnvironment(simulator)
        return false // Skip on simulator
        #else
        return checkJailbreakFiles() ||
               checkJailbreakLinks() ||
               checkSuspiciousFiles() ||
               checkDynamicLibraries() ||
               checkSystemIntegrity()
        #endif
    }
    
    private func checkJailbreakFiles() -> Bool {
        let jailbreakFiles = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt",
            "/private/var/lib/cydia",
            "/private/var/stash",
            "/usr/libexec/cydia",
            "/usr/bin/cycript",
            "/usr/local/bin/cycript",
            "/usr/lib/libcycript.dylib",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/Snoop-itConfig.app",
            "/Applications/WinterBoard.app",
            "/Applications/blackra1n.app"
        ]
        
        for file in jailbreakFiles {
            if FileManager.default.fileExists(atPath: file) {
                return true
            }
        }
        
        return false
    }
    
    private func checkJailbreakLinks() -> Bool {
        let jailbreakLinks = [
            "/Applications",
            "/Library/Ringtones",
            "/Library/Wallpaper",
            "/usr/arm-apple-darwin9",
            "/usr/include",
            "/usr/libexec",
            "/usr/share"
        ]
        
        for link in jailbreakLinks {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: link)
                if let fileType = attributes[.type] as? FileAttributeType,
                   fileType == .typeSymbolicLink {
                    return true
                }
            } catch {
                continue
            }
        }
        
        return false
    }
    
    private func checkSuspiciousFiles() -> Bool {
        // Check if we can write to system directories (shouldn't be possible on non-jailbroken devices)
        let testPath = "/private/jailbreak_test_\(UUID().uuidString).txt"
        
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true // If we can write, device is jailbroken
        } catch {
            return false
        }
    }
    
    private func checkDynamicLibraries() -> Bool {
        let suspiciousLibraries = [
            "SubstrateLoader.dylib",
            "SSLKillSwitch2.dylib",
            "SSLKillSwitch.dylib",
            "MobileSubstrate.dylib",
            "TweakInject.dylib",
            "CydiaSubstrate",
            "cynject"
        ]
        
        for library in suspiciousLibraries {
            if dlopen(library, RTLD_LAZY) != nil {
                return true
            }
        }
        
        return false
    }
    
    private func checkSystemIntegrity() -> Bool {
        // Check if fork() is available (it shouldn't be on non-jailbroken devices)
        let pid = fork()
        if pid >= 0 {
            if pid > 0 {
                kill(pid, SIGTERM)
            }
            return true
        }
        
        return false
    }
    
    // MARK: - Anti-Debugging Protection
    
    /// Check if debugger is attached
    var isDebuggerAttached: Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        
        if result != 0 {
            return false
        }
        
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    /// Prevent debugging by terminating if debugger is detected
    func enableAntiDebugging() {
        #if !DEBUG
        // Check periodically for debugger
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.isDebuggerAttached {
                // Clear sensitive data
                self.clearSensitiveData()
                // Terminate app
                fatalError("Security violation detected")
            }
        }
        
        // Prevent ptrace
        disablePtrace()
        #endif
    }
    
    private func disablePtrace() {
        #if !DEBUG
        let PT_DENY_ATTACH: Int32 = 31
        ptrace(PT_DENY_ATTACH, 0, 0, 0)
        #endif
    }
    
    // MARK: - Runtime Protection
    
    /// Check for code injection or tampering
    func checkCodeIntegrity() -> Bool {
        // Check if common hooking frameworks are loaded
        let hookingFrameworks = [
            "FridaGadget",
            "frida-agent",
            "libcycript",
            "substrate",
            "SubstrateLoader"
        ]
        
        for framework in hookingFrameworks {
            if Bundle.allFrameworks.contains(where: { $0.bundlePath.contains(framework) }) {
                return false
            }
        }
        
        return true
    }
    
    /// Validate app signature
    func validateAppSignature() -> Bool {
        guard let bundleURL = Bundle.main.bundleURL as CFURL? else {
            return false
        }
        
        var staticCode: SecStaticCode?
        let result = SecStaticCodeCreateWithPath(bundleURL, [], &staticCode)
        
        guard result == errSecSuccess,
              let code = staticCode else {
            return false
        }
        
        let requirement = "anchor apple generic" // Require Apple signature
        var requirementRef: SecRequirement?
        
        SecRequirementCreateWithString(requirement as CFString, [], &requirementRef)
        
        let validationResult = SecStaticCodeCheckValidity(code, [], requirementRef)
        
        return validationResult == errSecSuccess
    }
    
    // MARK: - Biometric Authentication
    
    /// Check if biometric authentication is available
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Authenticate using biometrics
    func authenticateWithBiometrics(
        reason: String,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        let context = LAContext()
        context.localizedReason = reason
        
        // Customize messages
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passcode"
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    // MARK: - Screen Recording Protection
    
    /// Check if screen is being recorded
    var isScreenBeingRecorded: Bool {
        UIScreen.main.isCaptured
    }
    
    /// Enable screen recording protection
    func enableScreenRecordingProtection() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureChanged),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func screenCaptureChanged() {
        if isScreenBeingRecorded {
            // Hide sensitive content or show warning
            NotificationCenter.default.post(
                name: Notification.Name("ScreenRecordingDetected"),
                object: nil
            )
        }
    }
    
    // MARK: - Data Protection
    
    /// Clear all sensitive data from memory and storage
    func clearSensitiveData() {
        // Clear Keychain
        try? KeychainService.shared.deleteAll()
        
        // Clear UserDefaults
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
        
        // Clear cache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear cookies
        HTTPCookieStorage.shared.cookies?.forEach {
            HTTPCookieStorage.shared.deleteCookie($0)
        }
    }
    
    /// Encrypt sensitive string
    func encryptString(_ string: String, with key: String) -> Data? {
        guard let data = string.data(using: .utf8),
              let keyData = key.data(using: .utf8) else {
            return nil
        }
        
        let symmetricKey = SymmetricKey(data: SHA256.hash(data: keyData))
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    /// Decrypt sensitive data
    func decryptData(_ encryptedData: Data, with key: String) -> String? {
        guard let keyData = key.data(using: .utf8) else {
            return nil
        }
        
        let symmetricKey = SymmetricKey(data: SHA256.hash(data: keyData))
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Security Validation
    
    /// Perform comprehensive security check
    func performSecurityCheck() -> SecurityCheckResult {
        var issues: [SecurityIssue] = []
        
        if isJailbroken {
            issues.append(.jailbreakDetected)
        }
        
        if isDebuggerAttached {
            issues.append(.debuggerDetected)
        }
        
        if !checkCodeIntegrity() {
            issues.append(.codeInjectionDetected)
        }
        
        if !validateAppSignature() {
            issues.append(.invalidSignature)
        }
        
        if isScreenBeingRecorded {
            issues.append(.screenRecordingDetected)
        }
        
        return SecurityCheckResult(
            isSecure: issues.isEmpty,
            issues: issues,
            timestamp: Date()
        )
    }
}

// MARK: - Supporting Types

struct SecurityCheckResult {
    let isSecure: Bool
    let issues: [SecurityIssue]
    let timestamp: Date
}

enum SecurityIssue {
    case jailbreakDetected
    case debuggerDetected
    case codeInjectionDetected
    case invalidSignature
    case screenRecordingDetected
    
    var severity: SecuritySeverity {
        switch self {
        case .jailbreakDetected, .debuggerDetected, .codeInjectionDetected:
            return .critical
        case .invalidSignature:
            return .high
        case .screenRecordingDetected:
            return .medium
        }
    }
    
    var message: String {
        switch self {
        case .jailbreakDetected:
            return "Device appears to be jailbroken"
        case .debuggerDetected:
            return "Debugger detected"
        case .codeInjectionDetected:
            return "Code injection detected"
        case .invalidSignature:
            return "App signature validation failed"
        case .screenRecordingDetected:
            return "Screen recording detected"
        }
    }
}

enum SecuritySeverity {
    case low
    case medium
    case high
    case critical
}

// MARK: - Kernel Types

private let CTL_KERN: Int32 = 1
private let KERN_PROC: Int32 = 14
private let KERN_PROC_PID: Int32 = 1
private let P_TRACED: Int32 = 0x00000800

// Import for ptrace
@_silgen_name("ptrace")
private func ptrace(_ request: Int32, _ pid: pid_t, _ addr: UnsafeRawPointer?, _ data: Int) -> Int32