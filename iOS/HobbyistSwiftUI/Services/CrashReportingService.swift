import Foundation
import FirebaseCrashlytics
import os.log

// MARK: - Crash Reporting Service

final class CrashReportingService: CrashReportingServiceProtocol {
    private let crashlytics = Crashlytics.crashlytics()
    private let logger = Logger(subsystem: "com.hobbyist.app", category: "CrashReporting")
    private var breadcrumbs: [Breadcrumb] = []
    private let maxBreadcrumbs = 100
    
    struct Breadcrumb {
        let timestamp: Date
        let message: String
        let metadata: [String: Any]?
    }
    
    init() {
        initialize()
    }
    
    func initialize() {
        // Enable crash collection
        crashlytics.setCrashlyticsCollectionEnabled(true)
        
        // Set initial custom keys
        setCustomValue(UIDevice.current.systemVersion, forKey: "ios_version")
        setCustomValue(UIDevice.current.modelName, forKey: "device_model")
        setCustomValue(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown", forKey: "app_version")
        setCustomValue(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown", forKey: "build_number")
        
        // Set environment
        #if DEBUG
        setCustomValue("debug", forKey: "environment")
        #else
        setCustomValue(isTestFlight() ? "testflight" : "production", forKey: "environment")
        #endif
        
        logger.info("Crash reporting service initialized")
    }
    
    func recordError(_ error: Error, context: [String: Any]? = nil) {
        // Log to system
        logger.error("Error recorded: \(error.localizedDescription)")
        
        // Add context as custom keys
        context?.forEach { key, value in
            setCustomValue(value, forKey: key)
        }
        
        // Record breadcrumb
        recordBreadcrumb("Error: \(error.localizedDescription)", metadata: context)
        
        // Send to Crashlytics
        crashlytics.record(error: error)
        
        // Track in analytics
        ServiceContainer.shared.analyticsService?.trackError(error, context: context)
    }
    
    func recordFatalError(_ error: Error, context: [String: Any]? = nil) {
        // Log critical error
        logger.critical("Fatal error recorded: \(error.localizedDescription)")
        
        // Add all breadcrumbs to crash report
        var crashContext = context ?? [:]
        crashContext["breadcrumbs"] = breadcrumbs.map { breadcrumb in
            return [
                "timestamp": ISO8601DateFormatter().string(from: breadcrumb.timestamp),
                "message": breadcrumb.message,
                "metadata": breadcrumb.metadata ?? [:]
            ]
        }
        
        // Add context
        crashContext.forEach { key, value in
            setCustomValue(value, forKey: key)
        }
        
        // Record the error
        crashlytics.record(error: error)
        
        // Force send crash report
        crashlytics.sendUnsentReports()
        
        // In production, this would typically trigger app termination
        #if !DEBUG
        fatalError(error.localizedDescription)
        #endif
    }
    
    func logMessage(_ message: String, level: LogLevel) {
        // System logging
        switch level {
        case .verbose:
            logger.debug("\(message)")
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .fatal:
            logger.critical("\(message)")
        }
        
        // Crashlytics logging
        crashlytics.log(formatLogMessage(message, level: level))
        
        // Add to breadcrumbs for context
        if level.rawValue >= LogLevel.warning.rawValue {
            recordBreadcrumb(message, metadata: ["level": level.rawValue])
        }
    }
    
    func setUserIdentifier(_ userId: String?) {
        if let userId = userId {
            crashlytics.setUserID(userId)
            logger.info("User identifier set: \(userId)")
        } else {
            crashlytics.setUserID("")
            logger.info("User identifier cleared")
        }
    }
    
    func setCustomValue(_ value: Any, forKey key: String) {
        crashlytics.setCustomValue(value, forKey: key)
    }
    
    func recordBreadcrumb(_ breadcrumb: String, metadata: [String: Any]? = nil) {
        let newBreadcrumb = Breadcrumb(
            timestamp: Date(),
            message: breadcrumb,
            metadata: metadata
        )
        
        breadcrumbs.append(newBreadcrumb)
        
        // Maintain max breadcrumbs limit
        if breadcrumbs.count > maxBreadcrumbs {
            breadcrumbs.removeFirst()
        }
        
        // Log to Crashlytics
        var logMessage = "📍 \(breadcrumb)"
        if let metadata = metadata {
            logMessage += " | \(metadata)"
        }
        crashlytics.log(logMessage)
    }
    
    // MARK: - Alpha Testing Specific Methods
    
    func recordAlphaTestEvent(_ event: String, metadata: [String: Any]? = nil) {
        var eventData = metadata ?? [:]
        eventData["event_type"] = "alpha_test"
        eventData["timestamp"] = ISO8601DateFormatter().string(from: Date())
        
        recordBreadcrumb("Alpha Test: \(event)", metadata: eventData)
        
        // Track in analytics for alpha metrics
        ServiceContainer.shared.analyticsService?.trackEvent(
            AnalyticsEvent(
                name: "alpha_test_event",
                category: "testing",
                action: event,
                label: nil,
                value: nil
            ),
            parameters: eventData
        )
    }
    
    func recordPerformanceMetric(name: String, value: Double, unit: String) {
        let metadata: [String: Any] = [
            "metric_name": name,
            "value": value,
            "unit": unit,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        setCustomValue(value, forKey: "perf_\(name)")
        recordBreadcrumb("Performance: \(name) = \(value)\(unit)", metadata: metadata)
    }
    
    func recordMemoryWarning() {
        let metadata: [String: Any] = [
            "available_memory": ProcessInfo.processInfo.physicalMemory,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        recordBreadcrumb("Memory Warning Received", metadata: metadata)
        logMessage("Memory warning received", level: .warning)
    }
    
    // MARK: - Helper Methods
    
    private func formatLogMessage(_ message: String, level: LogLevel) -> String {
        let emoji: String
        switch level {
        case .verbose: emoji = "🔍"
        case .debug: emoji = "🐛"
        case .info: emoji = "ℹ️"
        case .warning: emoji = "⚠️"
        case .error: emoji = "❌"
        case .fatal: emoji = "💀"
        }
        
        return "\(emoji) [\(level.rawValue.uppercased())] \(message)"
    }
    
    private func isTestFlight() -> Bool {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
            return false
        }
        return appStoreReceiptURL.lastPathComponent == "sandboxReceipt"
    }
}

// MARK: - Mock Crash Reporting Service

final class MockCrashReportingService: CrashReportingServiceProtocol {
    private var recordedErrors: [(error: Error, context: [String: Any]?)] = []
    private var logMessages: [(message: String, level: LogLevel)] = []
    private var customValues: [String: Any] = [:]
    private var breadcrumbs: [(message: String, metadata: [String: Any]?)] = []
    private var currentUserId: String?
    
    func initialize() {
        print("🧪 Mock Crash Reporting Service initialized")
    }
    
    func recordError(_ error: Error, context: [String: Any]?) {
        recordedErrors.append((error, context))
        print("🧪 Mock Error Recorded: \(error.localizedDescription)")
        if let context = context {
            print("   Context: \(context)")
        }
    }
    
    func recordFatalError(_ error: Error, context: [String: Any]?) {
        recordedErrors.append((error, context))
        print("🧪 Mock Fatal Error Recorded: \(error.localizedDescription)")
        if let context = context {
            print("   Context: \(context)")
        }
    }
    
    func logMessage(_ message: String, level: LogLevel) {
        logMessages.append((message, level))
        print("🧪 Mock Log [\(level.rawValue)]: \(message)")
    }
    
    func setUserIdentifier(_ userId: String?) {
        currentUserId = userId
        print("🧪 Mock User ID Set: \(userId ?? "nil")")
    }
    
    func setCustomValue(_ value: Any, forKey key: String) {
        customValues[key] = value
        print("🧪 Mock Custom Value Set: \(key) = \(value)")
    }
    
    func recordBreadcrumb(_ breadcrumb: String, metadata: [String: Any]?) {
        breadcrumbs.append((breadcrumb, metadata))
        print("🧪 Mock Breadcrumb: \(breadcrumb)")
        if let metadata = metadata {
            print("   Metadata: \(metadata)")
        }
    }
    
    // Test helper methods
    func getRecordedErrors() -> [(error: Error, context: [String: Any]?)] {
        return recordedErrors
    }
    
    func getLogMessages() -> [(message: String, level: LogLevel)] {
        return logMessages
    }
    
    func getBreadcrumbs() -> [(message: String, metadata: [String: Any]?)] {
        return breadcrumbs
    }
    
    func reset() {
        recordedErrors.removeAll()
        logMessages.removeAll()
        customValues.removeAll()
        breadcrumbs.removeAll()
        currentUserId = nil
    }
}

// MARK: - UIDevice Extension

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        // Map identifier to model name
        switch identifier {
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,6": return "iPhone SE (3rd generation)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPad13,1", "iPad13,2": return "iPad Air (4th generation)"
        case "iPad13,16", "iPad13,17": return "iPad Air (5th generation)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th generation)"
        default:
            if identifier.hasPrefix("iPhone") { return "iPhone" }
            if identifier.hasPrefix("iPad") { return "iPad" }
            return identifier
        }
    }
}