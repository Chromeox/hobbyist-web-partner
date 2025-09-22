import Foundation
import os.log
import CryptoKit

/// Comprehensive security monitoring and alerting system
final class SecurityMonitor {
    
    static let shared = SecurityMonitor()
    
    private let logger = OSLog(subsystem: "com.hobbyist.app", category: "Security")
    private let securityQueue = DispatchQueue(label: "com.hobbyist.security.monitor", attributes: .concurrent)
    private let keychain = KeychainService.shared
    
    // MARK: - Security Event Types
    
    enum EventType: String, CaseIterable {
        // Authentication Events
        case loginSuccess = "auth.login.success"
        case loginFailed = "auth.login.failed"
        case logoutSuccess = "auth.logout.success"
        case passwordReset = "auth.password.reset"
        case accountLocked = "auth.account.locked"
        case suspiciousLogin = "auth.suspicious.login"
        
        // Authorization Events
        case unauthorizedAccess = "authz.unauthorized"
        case privilegeEscalation = "authz.privilege.escalation"
        case permissionDenied = "authz.permission.denied"
        
        // Data Access Events
        case sensitiveDataAccess = "data.sensitive.access"
        case bulkDataExport = "data.bulk.export"
        case dataModification = "data.modification"
        case dataDelection = "data.deletion"
        
        // Payment Events
        case paymentSuccess = "payment.success"
        case paymentFailed = "payment.failed"
        case fraudulentPayment = "payment.fraudulent"
        case chargebackInitiated = "payment.chargeback"
        
        // Rate Limiting
        case rateLimitExceeded = "ratelimit.exceeded"
        case rateLimitWarning = "ratelimit.warning"
        
        // Security Violations
        case invalidToken = "security.invalid.token"
        case expiredToken = "security.expired.token"
        case tamperingDetected = "security.tampering"
        case jailbreakDetected = "security.jailbreak"
        case debuggerDetected = "security.debugger"
        
        // Network Security
        case certificatePinningFailed = "network.cert.pinning.failed"
        case insecureConnection = "network.insecure"
        case mitm_detected = "network.mitm"
        
        // Webhook Events
        case webhookValidationFailed = "webhook.validation.failed"
        case webhookReplayAttempt = "webhook.replay"
        
        // System Events
        case configurationChanged = "system.config.changed"
        case securityPatchApplied = "system.patch.applied"
        case anomalyDetected = "system.anomaly"
    }
    
    enum Severity: Int, Comparable {
        case info = 0
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4
        
        static func < (lhs: Severity, rhs: Severity) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
        var emoji: String {
            switch self {
            case .info: return "ℹ️"
            case .low: return "📝"
            case .medium: return "⚠️"
            case .high: return "🚨"
            case .critical: return "🔴"
            }
        }
    }
    
    // MARK: - Security Event Model
    
    struct SecurityEvent: Codable {
        let id: UUID
        let timestamp: Date
        let type: String
        let severity: Int
        let userId: String?
        let sessionId: String?
        let ipAddress: String?
        let userAgent: String?
        let metadata: [String: String]
        let stackTrace: String?
        let deviceInfo: DeviceInfo
        
        struct DeviceInfo: Codable {
            let model: String
            let osVersion: String
            let appVersion: String
            let isJailbroken: Bool
        }
    }
    
    // MARK: - Event Storage
    
    private var recentEvents: [SecurityEvent] = []
    private let maxStoredEvents = 1000
    private var eventCounts: [String: Int] = [:]
    private var lastAlertTime: [String: Date] = [:]
    
    // MARK: - Initialization
    
    private init() {
        setupMonitoring()
        performSecurityChecks()
    }
    
    private func setupMonitoring() {
        // Monitor for jailbreak
        checkForJailbreak()
        
        // Monitor for debugger
        checkForDebugger()
        
        // Setup periodic security checks
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.performSecurityChecks()
        }
    }
    
    // MARK: - Event Logging
    
    func logEvent(
        type: EventType,
        severity: Severity,
        userId: String? = nil,
        metadata: [String: String] = [:],
        stackTrace: String? = nil
    ) {
        let event = createEvent(
            type: type,
            severity: severity,
            userId: userId,
            metadata: metadata,
            stackTrace: stackTrace
        )
        
        // Store event
        storeEvent(event)
        
        // Log to system
        logToSystem(event)
        
        // Check for alerts
        checkAlertThresholds(event)
        
        // Send to backend if critical
        if severity >= .high {
            sendToBackend(event)
        }
    }
    
    private func createEvent(
        type: EventType,
        severity: Severity,
        userId: String?,
        metadata: [String: String],
        stackTrace: String?
    ) -> SecurityEvent {
        let deviceInfo = SecurityEvent.DeviceInfo(
            model: getDeviceModel(),
            osVersion: getOSVersion(),
            appVersion: getAppVersion(),
            isJailbroken: isJailbroken()
        )
        
        return SecurityEvent(
            id: UUID(),
            timestamp: Date(),
            type: type.rawValue,
            severity: severity.rawValue,
            userId: userId ?? getCurrentUserId(),
            sessionId: getSessionId(),
            ipAddress: getIPAddress(),
            userAgent: getUserAgent(),
            metadata: metadata,
            stackTrace: stackTrace,
            deviceInfo: deviceInfo
        )
    }
    
    private func storeEvent(_ event: SecurityEvent) {
        securityQueue.async(flags: .barrier) {
            self.recentEvents.append(event)
            
            // Maintain size limit
            if self.recentEvents.count > self.maxStoredEvents {
                self.recentEvents.removeFirst(self.recentEvents.count - self.maxStoredEvents)
            }
            
            // Update counters
            self.eventCounts[event.type, default: 0] += 1
        }
    }
    
    private func logToSystem(_ event: SecurityEvent) {
        let severity = Severity(rawValue: event.severity) ?? .info
        let message = "\(severity.emoji) [\(event.type)] \(event.metadata)"
        
        switch severity {
        case .critical:
            os_log(.fault, log: logger, "%{public}@", message)
        case .high:
            os_log(.error, log: logger, "%{public}@", message)
        case .medium:
            os_log(.info, log: logger, "%{public}@", message)
        case .low, .info:
            os_log(.debug, log: logger, "%{public}@", message)
        }
    }
    
    // MARK: - Alert Thresholds
    
    private func checkAlertThresholds(_ event: SecurityEvent) {
        let type = event.type
        let severity = Severity(rawValue: event.severity) ?? .info
        
        // Immediate alerts for critical events
        if severity == .critical {
            triggerAlert(for: event, reason: "Critical security event")
            return
        }
        
        // Check for rapid occurrence of events
        securityQueue.sync {
            let count = eventCounts[type] ?? 0
            let lastAlert = lastAlertTime[type] ?? Date.distantPast
            let timeSinceLastAlert = Date().timeIntervalSince(lastAlert)
            
            // Alert if too many events in short time
            let threshold = getThreshold(for: type)
            if count > threshold && timeSinceLastAlert > 300 { // 5 minute cooldown
                triggerAlert(for: event, reason: "Threshold exceeded: \(count) events")
                lastAlertTime[type] = Date()
            }
        }
    }
    
    private func getThreshold(for eventType: String) -> Int {
        // Define thresholds for different event types
        switch eventType {
        case EventType.loginFailed.rawValue:
            return 5 // Alert after 5 failed logins
        case EventType.rateLimitExceeded.rawValue:
            return 10 // Alert after 10 rate limit hits
        case EventType.unauthorizedAccess.rawValue:
            return 3 // Alert after 3 unauthorized attempts
        default:
            return 20 // Default threshold
        }
    }
    
    private func triggerAlert(for event: SecurityEvent, reason: String) {
        print("🚨 SECURITY ALERT: \(reason)")
        print("   Event: \(event.type)")
        print("   User: \(event.userId ?? "unknown")")
        
        // In production, this would:
        // - Send push notification to admins
        // - Send email alerts
        // - Trigger incident response workflow
        // - Log to SIEM system
    }
    
    // MARK: - Backend Communication
    
    private func sendToBackend(_ event: SecurityEvent) {
        Task {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(event)
                
                // Send to Supabase security_audit_log table
                _ = try await SupabaseService.shared.request(
                    "security_audit_log",
                    method: .post,
                    body: data
                ) as [String: Any]
                
            } catch {
                print("Failed to send security event to backend: \(error)")
            }
        }
    }
    
    // MARK: - Security Checks
    
    private func performSecurityChecks() {
        checkForJailbreak()
        checkForDebugger()
        checkCertificateValidity()
        checkForTampering()
        analyzeAnomalies()
    }
    
    private func checkForJailbreak() {
        if isJailbroken() {
            logEvent(
                type: .jailbreakDetected,
                severity: .high,
                metadata: ["detection_method": "file_system_check"]
            )
        }
    }
    
    private func isJailbroken() -> Bool {
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
            "/private/var/lib/apt/"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check if app can write to system directories
        let testPath = "/private/test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true // Should not be able to write
        } catch {
            // Expected behavior
        }
        
        return false
        #endif
    }
    
    private func checkForDebugger() {
        #if !DEBUG
        if isDebuggerAttached() {
            logEvent(
                type: .debuggerDetected,
                severity: .critical,
                metadata: ["action": "app_termination_pending"]
            )
            
            // In production, terminate the app
            // fatalError("Security violation detected")
        }
        #endif
    }
    
    private func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        
        return result == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    private func checkCertificateValidity() {
        // This would validate SSL certificates
        // Implementation depends on network layer
    }
    
    private func checkForTampering() {
        // Check app signature
        if !verifyAppSignature() {
            logEvent(
                type: .tamperingDetected,
                severity: .critical,
                metadata: ["check": "signature_verification_failed"]
            )
        }
    }
    
    private func verifyAppSignature() -> Bool {
        // In production, verify the app's code signature
        // This is a simplified check
        guard let bundleURL = Bundle.main.bundleURL as CFURL? else {
            return false
        }
        
        var staticCode: SecStaticCode?
        let result = SecStaticCodeCreateWithPath(bundleURL, [], &staticCode)
        
        guard result == errSecSuccess, let code = staticCode else {
            return false
        }
        
        let requirement = "anchor apple generic" // Basic Apple signature check
        var requirementRef: SecRequirement?
        SecRequirementCreateWithString(requirement as CFString, [], &requirementRef)
        
        if let req = requirementRef {
            let verifyResult = SecStaticCodeCheckValidity(code, [], req)
            return verifyResult == errSecSuccess
        }
        
        return false
    }
    
    // MARK: - Anomaly Detection
    
    private func analyzeAnomalies() {
        securityQueue.sync {
            // Check for unusual patterns
            checkLoginPatterns()
            checkAPIUsagePatterns()
            checkPaymentPatterns()
        }
    }
    
    private func checkLoginPatterns() {
        // Analyze recent login events for anomalies
        let recentLogins = recentEvents.filter { $0.type == EventType.loginSuccess.rawValue }
        
        // Check for rapid logins from different locations
        let uniqueIPs = Set(recentLogins.compactMap { $0.ipAddress })
        if uniqueIPs.count > 3 && recentLogins.count > 5 {
            logEvent(
                type: .anomalyDetected,
                severity: .medium,
                metadata: [
                    "pattern": "multiple_ip_logins",
                    "ip_count": String(uniqueIPs.count)
                ]
            )
        }
    }
    
    private func checkAPIUsagePatterns() {
        // Check for unusual API usage
        let rateLimitEvents = eventCounts[EventType.rateLimitExceeded.rawValue] ?? 0
        if rateLimitEvents > 50 {
            logEvent(
                type: .anomalyDetected,
                severity: .high,
                metadata: [
                    "pattern": "excessive_api_usage",
                    "count": String(rateLimitEvents)
                ]
            )
        }
    }
    
    private func checkPaymentPatterns() {
        // Check for suspicious payment patterns
        let failedPayments = recentEvents.filter { $0.type == EventType.paymentFailed.rawValue }
        if failedPayments.count > 3 {
            logEvent(
                type: .fraudulentPayment,
                severity: .high,
                metadata: [
                    "pattern": "multiple_payment_failures",
                    "count": String(failedPayments.count)
                ]
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> String? {
        // Get from authentication service
        return nil
    }
    
    private func getSessionId() -> String? {
        // Get current session ID
        return UUID().uuidString
    }
    
    private func getIPAddress() -> String? {
        // Get device IP address
        return "0.0.0.0"
    }
    
    private func getUserAgent() -> String {
        return "HobbyistApp/\(getAppVersion()) iOS/\(getOSVersion())"
    }
    
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
        return modelCode ?? "Unknown"
    }
    
    private func getOSVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - Security Reporting

extension SecurityMonitor {
    
    func generateSecurityReport() -> SecurityReport {
        securityQueue.sync {
            let eventsByType = Dictionary(grouping: recentEvents) { $0.type }
            let eventsBySeverity = Dictionary(grouping: recentEvents) { Severity(rawValue: $0.severity) ?? .info }
            
            return SecurityReport(
                generatedAt: Date(),
                totalEvents: recentEvents.count,
                eventsByType: eventsByType.mapValues { $0.count },
                eventsBySeverity: eventsBySeverity.mapValues { $0.count },
                criticalEvents: recentEvents.filter { $0.severity == Severity.critical.rawValue },
                recommendations: generateRecommendations()
            )
        }
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if eventCounts[EventType.loginFailed.rawValue] ?? 0 > 10 {
            recommendations.append("Consider implementing CAPTCHA for login")
        }
        
        if eventCounts[EventType.rateLimitExceeded.rawValue] ?? 0 > 20 {
            recommendations.append("Review API rate limits and usage patterns")
        }
        
        if eventCounts[EventType.jailbreakDetected.rawValue] ?? 0 > 0 {
            recommendations.append("Enhance jailbreak detection and response")
        }
        
        return recommendations
    }
}

struct SecurityReport {
    let generatedAt: Date
    let totalEvents: Int
    let eventsByType: [String: Int]
    let eventsBySeverity: [SecurityMonitor.Severity: Int]
    let criticalEvents: [SecurityMonitor.SecurityEvent]
    let recommendations: [String]
}

// Required import for sysctl
import Darwin

// Flags for process tracing
private let P_TRACED = Int32(0x00000800)
private let CTL_KERN = Int32(1)
private let KERN_PROC = Int32(14)
private let KERN_PROC_PID = Int32(1)

// UIKit import for device info
#if canImport(UIKit)
import UIKit
#endif