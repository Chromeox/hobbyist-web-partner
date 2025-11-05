import Foundation
import SwiftUI
import Combine
import os.log

// MARK: - Comprehensive Performance Monitor

/// Enterprise-grade performance monitoring and analytics service
@MainActor
public class PerformanceMonitor: ObservableObject {
    public static let shared = PerformanceMonitor()
    
    @Published public var isMonitoring: Bool = false
    @Published public var currentMetrics: PerformanceMetrics = PerformanceMetrics()
    @Published public var performanceScore: Double = 100.0
    @Published public var healthStatus: PerformanceHealth = .excellent
    @Published public var alerts: [PerformanceAlert] = []
    
    private let logger = Logger(subsystem: "com.hobbyapp.performance", category: "monitor")
    private var metricsCollectionTimer: Timer?
    private var alertCheckTimer: Timer?
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    
    // Performance tracking
    private var frameRateTracker = FrameRateTracker()
    private var memoryTracker = MemoryTracker()
    private var networkTracker = NetworkPerformanceTracker()
    private var crashDetector = CrashDetector()
    private var thermalStateMonitor = ThermalStateMonitor()
    
    // Metrics storage
    private var metricsHistory: [PerformanceSnapshot] = []
    private let maxHistoryCount = 1000
    
    private init() {
        setupPerformanceMonitoring()
    }
    
    // MARK: - Public API
    
    /// Start comprehensive performance monitoring
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        logger.info("Performance monitoring started")
        
        // Start all tracking systems
        frameRateTracker.start()
        memoryTracker.start()
        networkTracker.start()
        crashDetector.start()
        thermalStateMonitor.start()
        
        // Start metrics collection
        startMetricsCollection()
        startAlertMonitoring()
        setupMemoryPressureMonitoring()
        
        logPerformanceEvent(.monitoringStarted, details: [:])
    }
    
    /// Stop performance monitoring
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        logger.info("Performance monitoring stopped")
        
        // Stop all tracking systems
        frameRateTracker.stop()
        memoryTracker.stop()
        networkTracker.stop()
        crashDetector.stop()
        thermalStateMonitor.stop()
        
        // Stop timers
        metricsCollectionTimer?.invalidate()
        alertCheckTimer?.invalidate()
        memoryPressureSource?.cancel()
        
        logPerformanceEvent(.monitoringStopped, details: [:])
    }
    
    /// Track specific operation performance
    public func trackOperation<T>(
        name: String,
        category: PerformanceCategory = .general,
        operation: () async throws -> T
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = memoryTracker.currentMemoryUsage
        
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            let memoryDelta = memoryTracker.currentMemoryUsage - startMemory
            
            Task { @MainActor in
                self.recordOperationMetrics(
                    name: name,
                    category: category,
                    duration: duration,
                    memoryDelta: memoryDelta
                )
            }
        }
        
        return try await operation()
    }
    
    /// Get performance report
    public func generatePerformanceReport() -> PerformanceReport {
        let report = PerformanceReport(
            generatedAt: Date(),
            overallScore: performanceScore,
            healthStatus: healthStatus,
            metrics: currentMetrics,
            alerts: alerts,
            history: Array(metricsHistory.suffix(100)), // Last 100 snapshots
            recommendations: generateRecommendations()
        )
        
        logger.info("Performance report generated with score: \(performanceScore)")
        return report
    }
    
    /// Export metrics for external analysis
    public func exportMetrics(format: ExportFormat = .json) -> Data? {
        let exportData = PerformanceExport(
            timestamp: Date(),
            metrics: currentMetrics,
            history: metricsHistory,
            alerts: alerts,
            deviceInfo: collectDeviceInfo()
        )
        
        switch format {
        case .json:
            return try? JSONEncoder().encode(exportData)
        case .csv:
            return exportToCSV(exportData)
        }
    }
    
    // MARK: - Private Implementation
    
    private func setupPerformanceMonitoring() {
        // Configure performance logging
        logger.info("Initializing performance monitoring system")
        
        // Setup notification observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(memoryWarningReceived),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    private func startMetricsCollection() {
        metricsCollectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.collectMetrics()
            }
        }
    }
    
    private func startAlertMonitoring() {
        alertCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForPerformanceAlerts()
            }
        }
    }
    
    private func setupMemoryPressureMonitoring() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .urgent, .critical],
            queue: .main
        )
        
        memoryPressureSource?.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.handleMemoryPressure()
            }
        }
        
        memoryPressureSource?.resume()
    }
    
    private func collectMetrics() async {
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            frameRate: frameRateTracker.currentFPS,
            memoryUsage: memoryTracker.currentMemoryUsage,
            memoryPeak: memoryTracker.peakMemoryUsage,
            cpuUsage: getCurrentCPUUsage(),
            networkLatency: networkTracker.averageLatency,
            networkThroughput: networkTracker.currentThroughput,
            thermalState: thermalStateMonitor.currentState,
            diskUsage: getDiskUsage(),
            batteryLevel: UIDevice.current.batteryLevel,
            batteryState: UIDevice.current.batteryState
        )
        
        // Update current metrics
        currentMetrics = PerformanceMetrics(from: snapshot)
        
        // Store in history
        metricsHistory.append(snapshot)
        if metricsHistory.count > maxHistoryCount {
            metricsHistory.removeFirst()
        }
        
        // Update performance score and health
        updatePerformanceScore()
        updateHealthStatus()
    }
    
    private func recordOperationMetrics(
        name: String,
        category: PerformanceCategory,
        duration: CFTimeInterval,
        memoryDelta: Int64
    ) {
        let operation = OperationMetrics(
            name: name,
            category: category,
            duration: duration,
            memoryDelta: memoryDelta,
            timestamp: Date()
        )
        
        currentMetrics.operations.append(operation)
        
        // Keep only recent operations
        if currentMetrics.operations.count > 100 {
            currentMetrics.operations.removeFirst()
        }
        
        // Check for performance issues
        if duration > 1.0 { // Operations taking more than 1 second
            addAlert(.slowOperation(name: name, duration: duration))
        }
        
        if memoryDelta > 50 * 1024 * 1024 { // Memory increase of 50MB+
            addAlert(.memoryLeak(operation: name, memoryDelta: memoryDelta))
        }
        
        logger.debug("Operation '\(name)' completed in \(duration)s, memory delta: \(memoryDelta) bytes")
    }
    
    private func updatePerformanceScore() {
        var score: Double = 100.0
        
        // Frame rate score (0-30 points)
        let frameRateScore = min(30, (currentMetrics.frameRate / 60.0) * 30)
        
        // Memory score (0-25 points)
        let memoryPressure = Double(currentMetrics.memoryUsage) / Double(ProcessInfo.processInfo.physicalMemory)
        let memoryScore = max(0, 25 - (memoryPressure * 25))
        
        // CPU score (0-20 points)
        let cpuScore = max(0, 20 - (currentMetrics.cpuUsage * 20))
        
        // Network score (0-15 points)
        let networkScore = min(15, max(0, 15 - (currentMetrics.networkLatency / 100)))
        
        // Thermal score (0-10 points)
        let thermalScore = thermalStateScore()
        
        score = frameRateScore + memoryScore + cpuScore + networkScore + thermalScore
        performanceScore = max(0, min(100, score))
    }
    
    private func updateHealthStatus() {
        switch performanceScore {
        case 90...100:
            healthStatus = .excellent
        case 75..<90:
            healthStatus = .good
        case 60..<75:
            healthStatus = .fair
        case 40..<60:
            healthStatus = .poor
        default:
            healthStatus = .critical
        }
    }
    
    private func thermalStateScore() -> Double {
        switch currentMetrics.thermalState {
        case .nominal:
            return 10.0
        case .fair:
            return 7.5
        case .serious:
            return 5.0
        case .critical:
            return 0.0
        @unknown default:
            return 5.0
        }
    }
    
    private func checkForPerformanceAlerts() {
        var newAlerts: [PerformanceAlert] = []
        
        // Check frame rate
        if currentMetrics.frameRate < 30 {
            newAlerts.append(.lowFrameRate(fps: currentMetrics.frameRate))
        }
        
        // Check memory usage
        let memoryThreshold = ProcessInfo.processInfo.physicalMemory / 2 // 50% of total RAM
        if currentMetrics.memoryUsage > Int64(memoryThreshold) {
            newAlerts.append(.highMemoryUsage(usage: currentMetrics.memoryUsage))
        }
        
        // Check CPU usage
        if currentMetrics.cpuUsage > 0.8 {
            newAlerts.append(.highCPUUsage(usage: currentMetrics.cpuUsage))
        }
        
        // Check thermal state
        if currentMetrics.thermalState == .critical {
            newAlerts.append(.thermalWarning(state: currentMetrics.thermalState))
        }
        
        // Check network latency
        if currentMetrics.networkLatency > 1000 { // > 1 second
            newAlerts.append(.highNetworkLatency(latency: currentMetrics.networkLatency))
        }
        
        // Update alerts array
        alerts = newAlerts
    }
    
    private func addAlert(_ alert: PerformanceAlert) {
        alerts.append(alert)
        
        // Keep only recent alerts (last 50)
        if alerts.count > 50 {
            alerts.removeFirst()
        }
        
        logger.warning("Performance alert: \(alert.description)")
    }
    
    private func generateRecommendations() -> [PerformanceRecommendation] {
        var recommendations: [PerformanceRecommendation] = []
        
        if currentMetrics.frameRate < 45 {
            recommendations.append(.optimizeAnimations)
        }
        
        if currentMetrics.memoryUsage > Int64(ProcessInfo.processInfo.physicalMemory / 3) {
            recommendations.append(.reduceMemoryUsage)
        }
        
        if currentMetrics.cpuUsage > 0.7 {
            recommendations.append(.optimizeCPUUsage)
        }
        
        if currentMetrics.networkLatency > 500 {
            recommendations.append(.improveNetworkPerformance)
        }
        
        return recommendations
    }
    
    private func getCurrentCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        return Double(info.resident_size) / Double(ProcessInfo.processInfo.physicalMemory)
    }
    
    private func getDiskUsage() -> Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let totalSpace = systemAttributes[.systemSize] as? NSNumber {
                return totalSpace.int64Value
            }
        } catch {
            logger.error("Failed to get disk usage: \(error.localizedDescription)")
        }
        return 0
    }
    
    private func collectDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current
        return DeviceInfo(
            model: device.model,
            systemVersion: device.systemVersion,
            identifierForVendor: device.identifierForVendor?.uuidString,
            batteryLevel: device.batteryLevel,
            batteryState: device.batteryState,
            thermalState: ProcessInfo.processInfo.thermalState,
            processorCount: ProcessInfo.processInfo.processorCount,
            physicalMemory: ProcessInfo.processInfo.physicalMemory
        )
    }
    
    private func exportToCSV(_ exportData: PerformanceExport) -> Data? {
        var csvContent = "timestamp,frameRate,memoryUsage,cpuUsage,networkLatency,thermalState\n"
        
        for snapshot in exportData.history {
            csvContent += "\(snapshot.timestamp.timeIntervalSince1970),"
            csvContent += "\(snapshot.frameRate),"
            csvContent += "\(snapshot.memoryUsage),"
            csvContent += "\(snapshot.cpuUsage),"
            csvContent += "\(snapshot.networkLatency),"
            csvContent += "\(snapshot.thermalState.rawValue)\n"
        }
        
        return csvContent.data(using: .utf8)
    }
    
    private func logPerformanceEvent(_ event: PerformanceEvent, details: [String: Any]) {
        logger.info("Performance event: \(event.rawValue) - \(details)")
    }
    
    private func handleMemoryPressure() {
        addAlert(.memoryPressure(level: .warning))
        logger.warning("Memory pressure detected")
        
        // Notify other services to reduce memory usage
        NotificationCenter.default.post(name: .memoryPressureDetected, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        logger.debug("App became active - resuming performance monitoring")
    }
    
    @objc private func appWillResignActive() {
        logger.debug("App will resign active - pausing performance monitoring")
    }
    
    @objc private func memoryWarningReceived() {
        addAlert(.memoryWarning)
        logger.warning("Memory warning received from iOS")
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Performance Tracking Components

private class FrameRateTracker {
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var lastTimestamp: CFTimeInterval = 0
    
    var currentFPS: Double = 60.0
    
    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(frame))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func frame() {
        frameCount += 1
        
        let timestamp = displayLink?.timestamp ?? 0
        if lastTimestamp == 0 {
            lastTimestamp = timestamp
            return
        }
        
        let elapsed = timestamp - lastTimestamp
        if elapsed >= 1.0 {
            currentFPS = Double(frameCount) / elapsed
            frameCount = 0
            lastTimestamp = timestamp
        }
    }
}

private class MemoryTracker {
    var currentMemoryUsage: Int64 = 0
    var peakMemoryUsage: Int64 = 0
    private var timer: Timer?
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
        updateMemoryUsage()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return }
        
        currentMemoryUsage = Int64(info.resident_size)
        peakMemoryUsage = max(peakMemoryUsage, currentMemoryUsage)
    }
}

private class NetworkPerformanceTracker {
    var averageLatency: Double = 0.0
    var currentThroughput: Double = 0.0
    
    func start() {
        // Start network monitoring
    }
    
    func stop() {
        // Stop network monitoring
    }
}

private class CrashDetector {
    func start() {
        // Setup crash detection
        setupCrashHandler()
    }
    
    func stop() {
        // Clean up crash detection
    }
    
    private func setupCrashHandler() {
        NSSetUncaughtExceptionHandler { exception in
            // Handle uncaught exceptions
            let crashInfo = CrashInfo(
                timestamp: Date(),
                exception: exception.description,
                stackTrace: exception.callStackSymbols
            )
            // Log crash info
        }
        
        signal(SIGABRT) { signal in
            // Handle signals
        }
    }
}

private class ThermalStateMonitor {
    var currentState: ProcessInfo.ThermalState = .nominal
    
    func start() {
        currentState = ProcessInfo.processInfo.thermalState
        
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.currentState = ProcessInfo.processInfo.thermalState
        }
    }
    
    func stop() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Performance Data Models

public struct PerformanceMetrics {
    public let frameRate: Double
    public let memoryUsage: Int64
    public let memoryPeak: Int64
    public let cpuUsage: Double
    public let networkLatency: Double
    public let networkThroughput: Double
    public let thermalState: ProcessInfo.ThermalState
    public let diskUsage: Int64
    public let batteryLevel: Float
    public let batteryState: UIDevice.BatteryState
    public var operations: [OperationMetrics]
    
    public init() {
        self.frameRate = 60.0
        self.memoryUsage = 0
        self.memoryPeak = 0
        self.cpuUsage = 0.0
        self.networkLatency = 0.0
        self.networkThroughput = 0.0
        self.thermalState = .nominal
        self.diskUsage = 0
        self.batteryLevel = 1.0
        self.batteryState = .unknown
        self.operations = []
    }
    
    public init(from snapshot: PerformanceSnapshot) {
        self.frameRate = snapshot.frameRate
        self.memoryUsage = snapshot.memoryUsage
        self.memoryPeak = snapshot.memoryPeak
        self.cpuUsage = snapshot.cpuUsage
        self.networkLatency = snapshot.networkLatency
        self.networkThroughput = snapshot.networkThroughput
        self.thermalState = snapshot.thermalState
        self.diskUsage = snapshot.diskUsage
        self.batteryLevel = snapshot.batteryLevel
        self.batteryState = snapshot.batteryState
        self.operations = []
    }
}

public struct PerformanceSnapshot: Codable {
    public let timestamp: Date
    public let frameRate: Double
    public let memoryUsage: Int64
    public let memoryPeak: Int64
    public let cpuUsage: Double
    public let networkLatency: Double
    public let networkThroughput: Double
    public let thermalState: ProcessInfo.ThermalState
    public let diskUsage: Int64
    public let batteryLevel: Float
    public let batteryState: UIDevice.BatteryState
}

public struct OperationMetrics: Identifiable, Codable {
    public let id = UUID()
    public let name: String
    public let category: PerformanceCategory
    public let duration: CFTimeInterval
    public let memoryDelta: Int64
    public let timestamp: Date
}

public enum PerformanceCategory: String, Codable, CaseIterable {
    case general = "General"
    case networking = "Networking"
    case database = "Database"
    case ui = "User Interface"
    case animation = "Animation"
    case imageProcessing = "Image Processing"
    case authentication = "Authentication"
    case payment = "Payment"
    case search = "Search"
    case booking = "Booking"
}

public enum PerformanceHealth: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case critical = "Critical"
    
    public var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return Color(red: 0.6, green: 0.8, blue: 0.2)
        case .fair:
            return .yellow
        case .poor:
            return .orange
        case .critical:
            return .red
        }
    }
}

public enum PerformanceAlert: Identifiable, Equatable {
    case lowFrameRate(fps: Double)
    case highMemoryUsage(usage: Int64)
    case highCPUUsage(usage: Double)
    case thermalWarning(state: ProcessInfo.ThermalState)
    case highNetworkLatency(latency: Double)
    case slowOperation(name: String, duration: CFTimeInterval)
    case memoryLeak(operation: String, memoryDelta: Int64)
    case memoryPressure(level: MemoryPressureLevel)
    case memoryWarning
    case crash(info: String)
    
    public var id: String {
        switch self {
        case .lowFrameRate:
            return "lowFrameRate"
        case .highMemoryUsage:
            return "highMemoryUsage"
        case .highCPUUsage:
            return "highCPUUsage"
        case .thermalWarning:
            return "thermalWarning"
        case .highNetworkLatency:
            return "highNetworkLatency"
        case .slowOperation(let name, _):
            return "slowOperation_\(name)"
        case .memoryLeak(let operation, _):
            return "memoryLeak_\(operation)"
        case .memoryPressure:
            return "memoryPressure"
        case .memoryWarning:
            return "memoryWarning"
        case .crash:
            return "crash"
        }
    }
    
    public var description: String {
        switch self {
        case .lowFrameRate(let fps):
            return "Low frame rate detected: \(String(format: "%.1f", fps)) FPS"
        case .highMemoryUsage(let usage):
            return "High memory usage: \(ByteCountFormatter.string(fromByteCount: usage, countStyle: .memory))"
        case .highCPUUsage(let usage):
            return "High CPU usage: \(String(format: "%.1f", usage * 100))%"
        case .thermalWarning(let state):
            return "Thermal warning: \(state)"
        case .highNetworkLatency(let latency):
            return "High network latency: \(String(format: "%.0f", latency))ms"
        case .slowOperation(let name, let duration):
            return "Slow operation '\(name)': \(String(format: "%.2f", duration))s"
        case .memoryLeak(let operation, let delta):
            return "Potential memory leak in '\(operation)': +\(ByteCountFormatter.string(fromByteCount: delta, countStyle: .memory))"
        case .memoryPressure(let level):
            return "Memory pressure: \(level.rawValue)"
        case .memoryWarning:
            return "System memory warning received"
        case .crash(let info):
            return "Application crash: \(info)"
        }
    }
    
    public var severity: AlertSeverity {
        switch self {
        case .crash, .thermalWarning:
            return .critical
        case .highMemoryUsage, .highCPUUsage, .memoryPressure, .memoryWarning:
            return .high
        case .slowOperation, .memoryLeak, .highNetworkLatency:
            return .medium
        case .lowFrameRate:
            return .low
        }
    }
}

public enum MemoryPressureLevel: String, Codable {
    case normal = "Normal"
    case warning = "Warning"
    case urgent = "Urgent"
    case critical = "Critical"
}

public enum AlertSeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    public var color: Color {
        switch self {
        case .low:
            return .blue
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
}

public enum PerformanceRecommendation: String, CaseIterable {
    case optimizeAnimations = "Optimize animations and visual effects"
    case reduceMemoryUsage = "Reduce memory usage by implementing caching strategies"
    case optimizeCPUUsage = "Optimize CPU-intensive operations"
    case improveNetworkPerformance = "Improve network performance with caching and compression"
    case enablePerformanceMode = "Enable performance mode for better frame rates"
    case clearAppCache = "Clear application cache to free up memory"
    case restartApp = "Restart the application to reset performance state"
    case updateApp = "Update to the latest version for performance improvements"
}

public struct PerformanceReport: Codable {
    public let generatedAt: Date
    public let overallScore: Double
    public let healthStatus: PerformanceHealth
    public let metrics: PerformanceMetrics
    public let alerts: [PerformanceAlert]
    public let history: [PerformanceSnapshot]
    public let recommendations: [PerformanceRecommendation]
}

public struct PerformanceExport: Codable {
    public let timestamp: Date
    public let metrics: PerformanceMetrics
    public let history: [PerformanceSnapshot]
    public let alerts: [PerformanceAlert]
    public let deviceInfo: DeviceInfo
}

public struct DeviceInfo: Codable {
    public let model: String
    public let systemVersion: String
    public let identifierForVendor: String?
    public let batteryLevel: Float
    public let batteryState: UIDevice.BatteryState
    public let thermalState: ProcessInfo.ThermalState
    public let processorCount: Int
    public let physicalMemory: UInt64
}

public struct CrashInfo: Codable {
    public let timestamp: Date
    public let exception: String
    public let stackTrace: [String]
}

public enum ExportFormat {
    case json
    case csv
}

public enum PerformanceEvent: String {
    case monitoringStarted = "monitoring_started"
    case monitoringStopped = "monitoring_stopped"
    case alertTriggered = "alert_triggered"
    case performanceDegraded = "performance_degraded"
    case performanceImproved = "performance_improved"
}

// MARK: - Notification Extensions

public extension Notification.Name {
    static let memoryPressureDetected = Notification.Name("memoryPressureDetected")
    static let performanceAlertTriggered = Notification.Name("performanceAlertTriggered")
    static let performanceScoreChanged = Notification.Name("performanceScoreChanged")
}

// MARK: - Performance Debug View

public struct PerformanceDebugView: View {
    @StateObject private var monitor = PerformanceMonitor.shared
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Overall Health
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Health")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(monitor.healthStatus.color)
                            .frame(width: 12, height: 12)
                        
                        Text(monitor.healthStatus.rawValue)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(monitor.performanceScore))/100")
                            .fontWeight(.bold)
                    }
                }
                
                // Current Metrics
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Metrics")
                        .font(.headline)
                    
                    metricRow("Frame Rate", "\(String(format: "%.1f", monitor.currentMetrics.frameRate)) FPS")
                    metricRow("Memory", ByteCountFormatter.string(fromByteCount: monitor.currentMetrics.memoryUsage, countStyle: .memory))
                    metricRow("CPU", "\(String(format: "%.1f", monitor.currentMetrics.cpuUsage * 100))%")
                    metricRow("Network", "\(String(format: "%.0f", monitor.currentMetrics.networkLatency))ms")
                    metricRow("Thermal", "\(monitor.currentMetrics.thermalState)")
                }
                
                // Alerts
                if !monitor.alerts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Active Alerts")
                            .font(.headline)
                        
                        ForEach(monitor.alerts) { alert in
                            HStack {
                                Circle()
                                    .fill(alert.severity.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(alert.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Controls
                HStack {
                    Button(monitor.isMonitoring ? "Stop Monitoring" : "Start Monitoring") {
                        if monitor.isMonitoring {
                            monitor.stopMonitoring()
                        } else {
                            monitor.startMonitoring()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Generate Report") {
                        let report = monitor.generatePerformanceReport()
                        print("Performance Report Generated: \(report)")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func metricRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}

#Preview {
    PerformanceDebugView()
        .padding()
}