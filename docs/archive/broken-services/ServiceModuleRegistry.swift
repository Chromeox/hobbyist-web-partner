import Foundation

// MARK: - Service Module Registry for Dynamic Discovery and Registration

@MainActor
final class ServiceModuleRegistry: ObservableObject {
    static let shared = ServiceModuleRegistry()

    // MARK: - Registry State

    @Published private(set) var registeredModules: [String: ModularServiceProtocol] = [:]
    @Published private(set) var moduleStatus: [String: ServiceHealthStatus] = [:]

    private var moduleStartupOrder: [String] = []

    private init() {
        print("🗂️ ServiceModuleRegistry initialized")
    }

    // MARK: - Module Registration

    func registerModule(_ service: ModularServiceProtocol) {
        let moduleId = service.moduleId

        guard registeredModules[moduleId] == nil else {
            print("⚠️ Module '\(moduleId)' is already registered")
            return
        }

        registeredModules[moduleId] = service
        moduleStatus[moduleId] = .unhealthy(error: ModuleError.initializationFailed("Not initialized"))

        print("📝 Registered module: \(service.moduleName) (\(moduleId))")

        // Update startup order based on dependencies
        updateStartupOrder()
    }

    func unregisterModule(_ moduleId: String) {
        guard let service = registeredModules[moduleId] else {
            print("⚠️ Attempted to unregister unknown module: \(moduleId)")
            return
        }

        Task {
            await service.stop()
            await service.cleanup()
        }

        registeredModules.removeValue(forKey: moduleId)
        moduleStatus.removeValue(forKey: moduleId)

        print("📝 Unregistered module: \(moduleId)")

        updateStartupOrder()
    }

    // MARK: - Module Lifecycle Management

    func initializeAllModules() async {
        print("🚀 Initializing all registered modules...")

        for moduleId in moduleStartupOrder {
            guard let service = registeredModules[moduleId] else { continue }

            do {
                await service.initialize()
                moduleStatus[moduleId] = .healthy
                print("✅ Initialized: \(service.moduleName)")
            } catch {
                moduleStatus[moduleId] = .unhealthy(error: error)
                print("❌ Failed to initialize \(service.moduleName): \(error.localizedDescription)")
            }
        }

        print("🚀 Module initialization complete")
    }

    func startAllModules() async {
        print("▶️ Starting all initialized modules...")

        for moduleId in moduleStartupOrder {
            guard let service = registeredModules[moduleId] else { continue }

            // Only start modules that are healthy after initialization
            guard case .healthy = moduleStatus[moduleId] ?? .unhealthy(error: ModuleError.initializationFailed("Unknown")) else {
                print("⏭️ Skipping unhealthy module: \(service.moduleName)")
                continue
            }

            do {
                try await service.start()
                moduleStatus[moduleId] = .healthy
                print("✅ Started: \(service.moduleName)")
            } catch {
                moduleStatus[moduleId] = .unhealthy(error: error)
                print("❌ Failed to start \(service.moduleName): \(error.localizedDescription)")
            }
        }

        print("▶️ Module startup complete")
    }

    func stopAllModules() async {
        print("⏹️ Stopping all modules...")

        // Stop modules in reverse order
        for moduleId in moduleStartupOrder.reversed() {
            guard let service = registeredModules[moduleId] else { continue }

            await service.stop()
            moduleStatus[moduleId] = .degraded(reason: "Stopped")
            print("⏹️ Stopped: \(service.moduleName)")
        }

        print("⏹️ All modules stopped")
    }

    // MARK: - Module Discovery

    func isModuleAvailable(_ moduleId: String) -> Bool {
        guard let service = registeredModules[moduleId] else { return false }
        return service.isHealthy
    }

    func getModule<T: ModularServiceProtocol>(_ moduleId: String) -> T? {
        return registeredModules[moduleId] as? T
    }

    func getModuleStatus(_ moduleId: String) -> ServiceHealthStatus? {
        return moduleStatus[moduleId]
    }

    func getAllModules() -> [ModularServiceProtocol] {
        return Array(registeredModules.values)
    }

    // MARK: - Health Monitoring

    func performHealthChecks() async {
        print("🏥 Performing health checks on all modules...")

        for (moduleId, service) in registeredModules {
            let healthStatus = await service.healthCheck()
            moduleStatus[moduleId] = healthStatus

            switch healthStatus {
            case .healthy:
                print("✅ \(service.moduleName): Healthy")
            case .degraded(let reason):
                print("⚠️ \(service.moduleName): Degraded - \(reason)")
            case .unhealthy(let error):
                print("❌ \(service.moduleName): Unhealthy - \(error.localizedDescription)")
            }
        }

        print("🏥 Health checks complete")
    }

    // MARK: - Dependency Management

    private func updateStartupOrder() {
        // Simple topological sort for dependency resolution
        var visited: Set<String> = []
        var tempVisited: Set<String> = []
        var result: [String] = []

        func visit(_ moduleId: String) {
            guard !visited.contains(moduleId) else { return }
            guard !tempVisited.contains(moduleId) else {
                print("⚠️ Circular dependency detected involving: \(moduleId)")
                return
            }

            tempVisited.insert(moduleId)

            if let service = registeredModules[moduleId] {
                for dependency in service.dependencies {
                    visit(dependency)
                }
            }

            tempVisited.remove(moduleId)
            visited.insert(moduleId)
            result.append(moduleId)
        }

        for moduleId in registeredModules.keys {
            visit(moduleId)
        }

        moduleStartupOrder = result
        print("📋 Updated module startup order: \(moduleStartupOrder)")
    }

    // MARK: - Debug Information

    var debugDescription: String {
        var info = "Service Module Registry:\n"
        info += "Registered Modules: \(registeredModules.count)\n"
        info += "Startup Order: \(moduleStartupOrder.joined(separator: " → "))\n\n"

        for (moduleId, service) in registeredModules {
            let status = moduleStatus[moduleId] ?? .unhealthy(error: ModuleError.initializationFailed("Unknown"))
            let statusIcon = status.isOperational ? "✅" : "❌"
            info += "\(statusIcon) \(service.moduleName) (\(moduleId))\n"

            if !service.dependencies.isEmpty {
                info += "   Dependencies: \(service.dependencies.joined(separator: ", "))\n"
            }
        }

        return info
    }
}