import Foundation
import os.log
import CryptoKit

/// Comprehensive security event logging and monitoring system
final class SecurityEventLogger {
    static let shared = SecurityEventLogger()
    
    // OSLog for security events (encrypted in production)
    private let securityLog = OSLog(subsystem: "com.hobbyist.security", category: "SecurityEvents")
    
    // Event storage for analysis
    private var eventQueue: [SecurityEvent] = []
    private let queueLock = NSLock()
    private let maxQueueSize = 1000
    
    // Monitoring thresholds
    private var alertThresholds = SecurityThresholds()
    
    // Event listeners
    private var eventHandlers: [(SecurityEvent) -> Void] = []
    
    private init() {
        setupEventMonitoring()
        startPeriodicAnalysis()
    }
    
    // MARK: - Security Event Structure
    
    struct SecurityEvent: Codable {
        let id: String = UUID().uuidString
        let timestamp: Date = Date()
        let type: EventType
        let severity: Severity
        let message: String
        let metadata: [String: String]
        let userId: String?
        let deviceInfo: DeviceInfo
        let stackTrace: String?
        
        enum EventType: String, Codable {
            // Authentication events
            case loginAttempt = "login_attempt"
            case loginSuccess = "login_success"
            case loginFailure = "login_failure"
            case logoutSuccess = "logout_success"
            case sessionExpired = "session_expired"
            case passwordReset = "password_reset"
            
            // Security violations
            case jailbreakDetected = "jailbreak_detected"
            case debuggerDetected = "debugger_detected"
            case codeInjection = "code_injection"
            case certificatePinningFailure = "cert_pinning_failure"
            case screenRecording = "screen_recording"
            case suspiciousActivity = "suspicious_activity"
            
            // Access control
            case unauthorizedAccess = "unauthorized_access"
            case privilegeEscalation = "privilege_escalation"
            case dataExfiltration = "data_exfiltration"
            
            // Network security
            case rateLimitExceeded = "rate_limit_exceeded"
            case ddosAttempt = "ddos_attempt"
            case mitm_attempt = "mitm_attempt"
            case invalidRequest = "invalid_request"
            
            // Data protection
            case encryptionFailure = "encryption_failure"
            case decryptionFailure = "decryption_failure"
            case keychainAccessDenied = "keychain_denied"
            case biometricFailure = "biometric_failure"
        }
        
        enum Severity: String, Codable, Comparable {
            case debug = "DEBUG"
            case info = "INFO"
            case warning = "WARNING"
            case error = "ERROR"
            case critical = "CRITICAL"
            
            static func < (lhs: Severity, rhs: Severity) -> Bool {
                let order: [Severity] = [.debug, .info, .warning, .error, .critical]
                guard let lhsIndex = order.firstIndex(of: lhs),
                      let rhsIndex = order.firstIndex(of: rhs) else {
                    return false
                }
                return lhsIndex < rhsIndex
            }
        }
        
        struct DeviceInfo: Codable {
            let deviceId: String
            let model: String
            let osVersion: String
            let appVersion: String
            let ipAddress: String?
            let location: String?
        }
    }
    
    // MARK: - Logging Methods
    
    /// Log security event
    func log(
        _ type: SecurityEvent.EventType,
        severity: SecurityEvent.Severity,
        message: String,
        metadata: [String: String] = [:],
        error: Error? = nil
    ) {
        let event = SecurityEvent(
            type: type,
            severity: severity,
            message: message,
            metadata: metadata,
            userId: getCurrentUserId(),
            deviceInfo: getDeviceInfo(),
            stackTrace: severity >= .error ? Thread.callStackSymbols.joined(separator: "\n") : nil
        )
        
        // Store event
        storeEvent(event)
        
        // Log to OSLog
        logToOSLog(event)
        
        // Check thresholds
        checkThresholds(event)
        
        // Notify handlers
        notifyHandlers(event)
        
        // Send to remote if critical
        if severity >= .error {
            sendToRemote(event)
        }
    }
    
    /// Log authentication event
    func logAuthentication(
        success: Bool,
        userId: String? = nil,
        metadata: [String: String] = [:]
    ) {
        log(
            success ? .loginSuccess : .loginFailure,
            severity: success ? .info : .warning,
            message: success ? "User authenticated successfully" : "Authentication failed",
            metadata: metadata
        )
        
        // Track failed attempts
        if !success {
            trackFailedAttempt(userId: userId)
        }
    }
    
    /// Log security violation
    func logSecurityViolation(
        type: SecurityEvent.EventType,
        message: String,
        metadata: [String: String] = [:]
    ) {
        log(
            type,
            severity: .critical,
            message: message,
            metadata: metadata
        )
        
        // Immediate alert for violations
        sendSecurityAlert(type: type, message: message)
    }
    
    // MARK: - Event Storage
    
    private func storeEvent(_ event: SecurityEvent) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        eventQueue.append(event)
        
        // Maintain queue size
        if eventQueue.count > maxQueueSize {
            eventQueue.removeFirst()
        }
        
        // Persist critical events
        if event.severity >= .error {
            persistEvent(event)
        }
    }
    
    private func persistEvent(_ event: SecurityEvent) {
        do {
            // Encrypt event data
            let encoder = JSONEncoder()
            let eventData = try encoder.encode(event)
            
            if let encryptedData = SecurityManager.shared.encryptString(
                String(data: eventData, encoding: .utf8)!,
                with: "SecurityEventKey"
            ) {
                // Store in secure location
                try KeychainService.shared.save(
                    encryptedData,
                    for: .sessionId // Using sessionId key for demo
                )
            }
        } catch {
            os_log("Failed to persist security event: %@", log: securityLog, type: .error, error.localizedDescription)
        }
    }
    
    // MARK: - Threshold Monitoring
    
    private struct SecurityThresholds {
        var maxFailedLogins: Int = 5
        var maxFailedLoginsTimeWindow: TimeInterval = 300 // 5 minutes
        var maxRateLimitViolations: Int = 10
        var maxSecurityViolations: Int = 3
        var analysisInterval: TimeInterval = 60 // 1 minute
    }
    
    private func checkThresholds(_ event: SecurityEvent) {
        queueLock.lock()
        let recentEvents = eventQueue.filter {
            Date().timeIntervalSince($0.timestamp) < alertThresholds.maxFailedLoginsTimeWindow
        }
        queueLock.unlock()
        
        // Check failed login attempts
        let failedLogins = recentEvents.filter { $0.type == .loginFailure }
        if failedLogins.count >= alertThresholds.maxFailedLogins {
            handleBruteForceAttempt(attempts: failedLogins)
        }
        
        // Check rate limit violations
        let rateLimitViolations = recentEvents.filter { $0.type == .rateLimitExceeded }
        if rateLimitViolations.count >= alertThresholds.maxRateLimitViolations {
            handleDDoSAttempt(violations: rateLimitViolations)
        }
        
        // Check security violations
        let securityViolations = recentEvents.filter { $0.severity == .critical }
        if securityViolations.count >= alertThresholds.maxSecurityViolations {
            handleSecurityBreach(violations: securityViolations)
        }
    }
    
    // MARK: - Attack Response
    
    private func handleBruteForceAttempt(attempts: [SecurityEvent]) {
        log(
            .suspiciousActivity,
            severity: .critical,
            message: "Possible brute force attack detected",
            metadata: ["attempts": "\(attempts.count)"]
        )
        
        // Implement account lockout
        if let userId = attempts.first?.userId {
            lockAccount(userId: userId)
        }
    }
    
    private func handleDDoSAttempt(violations: [SecurityEvent]) {
        log(
            .ddosAttempt,
            severity: .critical,
            message: "Possible DDoS attack detected",
            metadata: ["violations": "\(violations.count)"]
        )
        
        // Increase rate limiting
        RateLimitingService.shared.updateRateLimit(
            for: "default",
            maxRequests: 10,
            windowDuration: 60
        )
    }
    
    private func handleSecurityBreach(violations: [SecurityEvent]) {
        log(
            .suspiciousActivity,
            severity: .critical,
            message: "Multiple security violations detected - possible breach",
            metadata: ["violations": "\(violations.count)"]
        )
        
        // Emergency response
        emergencyShutdown()
    }
    
    private func lockAccount(userId: String) {
        // Implement account lockout logic
        NotificationCenter.default.post(
            name: Notification.Name("AccountLocked"),
            object: userId
        )
    }
    
    private func emergencyShutdown() {
        // Clear sensitive data
        SecurityManager.shared.clearSensitiveData()
        
        // Notify user
        NotificationCenter.default.post(
            name: Notification.Name("EmergencyShutdown"),
            object: nil
        )
    }
    
    // MARK: - Failed Attempt Tracking
    
    private var failedAttempts: [String: [Date]] = [:]
    
    private func trackFailedAttempt(userId: String?) {
        let key = userId ?? "unknown"
        
        queueLock.lock()
        defer { queueLock.unlock() }
        
        if failedAttempts[key] == nil {
            failedAttempts[key] = []
        }
        
        failedAttempts[key]?.append(Date())
        
        // Clean old attempts
        failedAttempts[key] = failedAttempts[key]?.filter {
            Date().timeIntervalSince($0) < alertThresholds.maxFailedLoginsTimeWindow
        }
    }
    
    // MARK: - Remote Logging
    
    private func sendToRemote(_ event: SecurityEvent) {
        Task {
            do {
                // Send to remote logging service
                let encoder = JSONEncoder()
                let eventData = try encoder.encode(event)
                
                // Use rate-limited network manager
                // In production, send to your logging service
                print("📤 Sending security event to remote: \(event.type.rawValue)")
            } catch {
                os_log("Failed to send event to remote: %@", log: securityLog, type: .error, error.localizedDescription)
            }
        }
    }
    
    private func sendSecurityAlert(type: SecurityEvent.EventType, message: String) {
        // Send immediate alert for critical events
        // In production, this could trigger:
        // - Push notification to security team
        // - Email alert
        // - SMS alert
        // - Slack/Discord webhook
        
        print("🚨 SECURITY ALERT: \(type.rawValue) - \(message)")
    }
    
    // MARK: - Event Analysis
    
    private func startPeriodicAnalysis() {
        Timer.scheduledTimer(withTimeInterval: alertThresholds.analysisInterval, repeats: true) { _ in
            self.analyzeSecurityTrends()
        }
    }
    
    private func analyzeSecurityTrends() {
        queueLock.lock()
        let events = eventQueue
        queueLock.unlock()
        
        // Analyze patterns
        let analysis = SecurityAnalysis(events: events)
        
        if analysis.riskLevel == .high {
            log(
                .suspiciousActivity,
                severity: .warning,
                message: "High risk level detected",
                metadata: analysis.summary
            )
        }
    }
    
    // MARK: - Event Handlers
    
    func addEventHandler(_ handler: @escaping (SecurityEvent) -> Void) {
        eventHandlers.append(handler)
    }
    
    private func notifyHandlers(_ event: SecurityEvent) {
        eventHandlers.forEach { handler in
            handler(event)
        }
    }
    
    // MARK: - OSLog Integration
    
    private func logToOSLog(_ event: SecurityEvent) {
        let type: OSLogType
        switch event.severity {
        case .debug: type = .debug
        case .info: type = .info
        case .warning: type = .default
        case .error: type = .error
        case .critical: type = .fault
        }
        
        os_log(
            "[%@] %@ - %@",
            log: securityLog,
            type: type,
            event.severity.rawValue,
            event.type.rawValue,
            event.message
        )
    }
    
    // MARK: - Helpers
    
    private func getCurrentUserId() -> String? {
        // Get from authentication service
        return nil // AuthenticationService.shared.currentUser?.id
    }
    
    private func getDeviceInfo() -> SecurityEvent.DeviceInfo {
        SecurityEvent.DeviceInfo(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            model: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            ipAddress: getIPAddress(),
            location: nil // Would need location permission
        )
    }
    
    private func getIPAddress() -> String? {
        // Get device IP address
        // Implementation would go here
        return nil
    }
    
    private func setupEventMonitoring() {
        // Monitor for security-related notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSecurityNotification(_:)),
            name: Notification.Name("CriticalSecurityIssue"),
            object: nil
        )
    }
    
    @objc private func handleSecurityNotification(_ notification: Notification) {
        if let issue = notification.object as? SecurityIssue {
            logSecurityViolation(
                type: mapIssueToEventType(issue),
                message: issue.message
            )
        }
    }
    
    private func mapIssueToEventType(_ issue: SecurityIssue) -> SecurityEvent.EventType {
        switch issue {
        case .jailbreakDetected: return .jailbreakDetected
        case .debuggerDetected: return .debuggerDetected
        case .codeInjectionDetected: return .codeInjection
        case .invalidSignature: return .suspiciousActivity
        case .screenRecordingDetected: return .screenRecording
        }
    }
}

// MARK: - Security Analysis

private struct SecurityAnalysis {
    let events: [SecurityEventLogger.SecurityEvent]
    
    var riskLevel: RiskLevel {
        let criticalCount = events.filter { $0.severity == .critical }.count
        let errorCount = events.filter { $0.severity == .error }.count
        
        if criticalCount > 0 { return .high }
        if errorCount > 5 { return .medium }
        return .low
    }
    
    var summary: [String: String] {
        [
            "total_events": "\(events.count)",
            "critical_events": "\(events.filter { $0.severity == .critical }.count)",
            "error_events": "\(events.filter { $0.severity == .error }.count)",
            "risk_level": riskLevel.rawValue
        ]
    }
    
    enum RiskLevel: String {
        case low = "LOW"
        case medium = "MEDIUM"
        case high = "HIGH"
    }
}

// Import required
import UIKit