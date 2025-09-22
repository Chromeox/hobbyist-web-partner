import Foundation
import Combine

// MARK: - Service Health Monitor with Circuit Breaker Pattern

@MainActor
final class ServiceHealthMonitor: ObservableObject {
    static let shared = ServiceHealthMonitor()

    // MARK: - Published State

    @Published private(set) var circuitStates: [String: CircuitState] = [:]
    @Published private(set) var performanceMetrics: [String: PerformanceMetrics] = [:]
    @Published private(set) var systemHealth: SystemHealthStatus = .unknown

    // MARK: - Configuration

    private let failureThreshold: Int = 5
    private let recoveryTimeout: TimeInterval = 30.0
    private let performanceWindow: TimeInterval = 300.0 // 5 minutes

    // MARK: - Monitoring State

    private var healthCheckTimer: Timer?
    private var failureCounts: [String: Int] = [:]
    private var lastFailureTimes: [String: Date] = [:]

    private init() {
        startHealthMonitoring()
        print("🏥 ServiceHealthMonitor initialized")
    }

    deinit {
        stopHealthMonitoring()
    }

    // MARK: - Circuit Breaker Pattern

    enum CircuitState {
        case closed       // Normal operation
        case open         // Failing, blocking requests
        case halfOpen     // Testing recovery

        var isOperational: Bool {
            return self == .closed
        }
    }

    func isServiceAvailable(_ moduleId: String) -> Bool {
        let circuitState = circuitStates[moduleId] ?? .closed
        return circuitState.isOperational
    }

    func recordSuccess(_ moduleId: String) {
        failureCounts[moduleId] = 0

        // If circuit was open or half-open, move to closed
        if circuitStates[moduleId] != .closed {
            circuitStates[moduleId] = .closed
            print("🟢 Circuit closed for \(moduleId) - service recovered")
        }

        updatePerformanceMetrics(moduleId, operationSucceeded: true)
    }

    func recordFailure(_ moduleId: String, error: Error) {
        let currentCount = failureCounts[moduleId] ?? 0
        failureCounts[moduleId] = currentCount + 1
        lastFailureTimes[moduleId] = Date()

        print("🔴 Service failure recorded for \(moduleId): \(error.localizedDescription)")

        // Check if we should open the circuit
        if currentCount + 1 >= failureThreshold {
            circuitStates[moduleId] = .open
            print("⚠️ Circuit opened for \(moduleId) - failure threshold reached")

            // Schedule recovery attempt
            scheduleRecoveryAttempt(moduleId)
        }

        updatePerformanceMetrics(moduleId, operationSucceeded: false)
    }

    // MARK: - Fallback Mechanisms

    func executeWithFallback<T>(
        _ moduleId: String,
        operation: () async throws -> T,
        fallback: () async -> T
    ) async -> T {
        // Check circuit state
        guard isServiceAvailable(moduleId) else {
            print("🔄 Using fallback for \(moduleId) - circuit is open")
            return await fallback()
        }

        do {
            let result = try await operation()
            recordSuccess(moduleId)
            return result
        } catch {
            recordFailure(moduleId, error: error)
            print("🔄 Operation failed for \(moduleId), using fallback")
            return await fallback()
        }
    }

    // MARK: - Performance Monitoring

    private func updatePerformanceMetrics(_ moduleId: String, operationSucceeded: Bool) {
        let now = Date()
        var metrics = performanceMetrics[moduleId] ?? PerformanceMetrics()

        metrics.totalOperations += 1
        if operationSucceeded {
            metrics.successfulOperations += 1
        }
        metrics.lastOperationTime = now

        // Clean old entries (older than performanceWindow)
        let cutoff = now.addingTimeInterval(-performanceWindow)
        metrics.operationTimes = metrics.operationTimes.filter { $0 > cutoff }
        metrics.operationTimes.append(now)

        performanceMetrics[moduleId] = metrics
    }

    // MARK: - Health Monitoring

    private func startHealthMonitoring() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performSystemHealthCheck()
            }
        }
    }

    private func stopHealthMonitoring() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }

    private func performSystemHealthCheck() async {
        let registry = ServiceModuleRegistry.shared
        await registry.performHealthChecks()

        // Calculate overall system health
        let modules = registry.getAllModules()
        let healthyCount = modules.filter { $0.isHealthy }.count
        let totalCount = modules.count

        if totalCount == 0 {
            systemHealth = .unknown
        } else if healthyCount == totalCount {
            systemHealth = .healthy
        } else if healthyCount > totalCount / 2 {
            systemHealth = .degraded
        } else {
            systemHealth = .unhealthy
        }

        print("🏥 System health check: \(healthyCount)/\(totalCount) modules healthy")
    }

    // MARK: - Recovery Logic

    private func scheduleRecoveryAttempt(_ moduleId: String) {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(recoveryTimeout * 1_000_000_000))

            await attemptRecovery(moduleId)
        }
    }

    private func attemptRecovery(_ moduleId: String) async {
        guard circuitStates[moduleId] == .open else { return }

        print("🔄 Attempting recovery for \(moduleId)")
        circuitStates[moduleId] = .halfOpen

        // Get the service and perform a health check
        if let service = ServiceModuleRegistry.shared.getModule(moduleId) as? ModularServiceProtocol {
            let healthStatus = await service.healthCheck()

            switch healthStatus {
            case .healthy:
                recordSuccess(moduleId)
                print("✅ Recovery successful for \(moduleId)")
            case .degraded, .unhealthy:
                // Recovery failed, go back to open
                circuitStates[moduleId] = .open
                print("❌ Recovery failed for \(moduleId), circuit remains open")

                // Schedule another recovery attempt
                scheduleRecoveryAttempt(moduleId)
            }
        }
    }

    // MARK: - Debug Information

    var debugDescription: String {
        var info = "Service Health Monitor:\n"
        info += "System Health: \(systemHealth)\n\n"

        for (moduleId, state) in circuitStates {
            let stateIcon = state.isOperational ? "🟢" : "🔴"
            info += "\(stateIcon) \(moduleId): \(state)\n"

            if let metrics = performanceMetrics[moduleId] {
                let successRate = metrics.successRate
                info += "   Success Rate: \(String(format: "%.1f", successRate * 100))%\n"
                info += "   Operations: \(metrics.totalOperations)\n"
            }

            if let failureCount = failureCounts[moduleId], failureCount > 0 {
                info += "   Failures: \(failureCount)\n"
            }
        }

        return info
    }
}

// MARK: - Supporting Types

enum SystemHealthStatus {
    case healthy
    case degraded
    case unhealthy
    case unknown
}

struct PerformanceMetrics {
    var totalOperations: Int = 0
    var successfulOperations: Int = 0
    var operationTimes: [Date] = []
    var lastOperationTime: Date?

    var successRate: Double {
        guard totalOperations > 0 else { return 1.0 }
        return Double(successfulOperations) / Double(totalOperations)
    }

    var operationsPerMinute: Double {
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        let recentOperations = operationTimes.filter { $0 > oneMinuteAgo }
        return Double(recentOperations.count)
    }
}