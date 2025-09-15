import Foundation
import os.log

// MARK: - Crash Reporting Service Protocol

protocol CrashReportingServiceProtocol {
    func logError(_ error: Error, context: [String: Any]?)
    func logEvent(_ event: String, parameters: [String: Any]?)
    func setUserProperty(_ value: String?, forName name: String)
    func addBreadcrumb(_ message: String, metadata: [String: Any]?)
}

// MARK: - Simple Crash Reporting Service (No Firebase)

final class CrashReportingService: CrashReportingServiceProtocol {
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
        // Log app launch
        logger.info("CrashReportingService initialized")
        
        // Set initial device info
        let deviceInfo: [String: Any] = [
            "ios_version": UIDevice.current.systemVersion,
            "device_model": UIDevice.current.model,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]
        
        logger.info("Device info: \(deviceInfo)")
    }
    
    func logError(_ error: Error, context: [String: Any]? = nil) {
        var errorInfo = "Error: \(error.localizedDescription)"
        
        if let context = context {
            errorInfo += " | Context: \(context)"
        }
        
        logger.error("\(errorInfo)")
        
        // Add to breadcrumbs
        addBreadcrumb("Error: \(error.localizedDescription)", metadata: context)
        
        // In production, this would send to a crash reporting service
        #if DEBUG
        print("🔴 Error logged: \(errorInfo)")
        #endif
    }
    
    func logEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventInfo = "Event: \(event)"
        
        if let parameters = parameters {
            eventInfo += " | Parameters: \(parameters)"
        }
        
        logger.info("\(eventInfo)")
        
        // Add to breadcrumbs
        addBreadcrumb(event, metadata: parameters)
    }
    
    func setUserProperty(_ value: String?, forName name: String) {
        if let value = value {
            logger.info("User property set: \(name) = \(value)")
        } else {
            logger.info("User property cleared: \(name)")
        }
    }
    
    func addBreadcrumb(_ message: String, metadata: [String: Any]? = nil) {
        let breadcrumb = Breadcrumb(
            timestamp: Date(),
            message: message,
            metadata: metadata
        )
        
        breadcrumbs.append(breadcrumb)
        
        // Keep only the last maxBreadcrumbs
        if breadcrumbs.count > maxBreadcrumbs {
            breadcrumbs.removeFirst(breadcrumbs.count - maxBreadcrumbs)
        }
    }
    
    // MARK: - Helper Methods
    
    func getBreadcrumbs() -> [Breadcrumb] {
        return breadcrumbs
    }
    
    func clearBreadcrumbs() {
        breadcrumbs.removeAll()
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
        return identifier
    }
}