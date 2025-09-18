import Foundation

// MARK: - Modular Service Architecture

/// Protocol defining common patterns for all modular services
protocol ModularServiceProtocol: AnyObject {
    /// Unique identifier for the service module
    var moduleId: String { get }

    /// Display name for the service module
    var moduleName: String { get }

    /// Current health status of the service
    var isHealthy: Bool { get }

    /// Dependencies required by this service
    var dependencies: [String] { get }

    /// Initialize the service module
    func initialize() async throws

    /// Start the service module
    func start() async throws

    /// Stop the service module
    func stop() async

    /// Cleanup resources used by the service
    func cleanup() async

    /// Health check for the service
    func healthCheck() async -> ServiceHealthStatus
}

// MARK: - Service Health Status

enum ServiceHealthStatus {
    case healthy
    case degraded(reason: String)
    case unhealthy(error: Error)

    var isOperational: Bool {
        switch self {
        case .healthy, .degraded:
            return true
        case .unhealthy:
            return false
        }
    }
}

// MARK: - Base Module Service

/// Base class for all modular services, extending the proven SimpleSupabaseService pattern
@MainActor
class BaseModuleService: ObservableObject, ModularServiceProtocol {

    // MARK: - ModularServiceProtocol

    let moduleId: String
    let moduleName: String
    @Published private(set) var isHealthy: Bool = false
    let dependencies: [String]

    // MARK: - Shared Infrastructure

    /// Access to the proven SimpleSupabaseService for data operations
    protected let supabaseService = SimpleSupabaseService.shared

    /// Feature flag manager for module control
    protected let featureFlagManager = FeatureFlagManager.shared

    /// Error handling and logging
    @Published private(set) var lastError: Error?
    @Published private(set) var isLoading: Bool = false

    // MARK: - Initialization

    init(moduleId: String, moduleName: String, dependencies: [String] = []) {
        self.moduleId = moduleId
        self.moduleName = moduleName
        self.dependencies = dependencies
    }

    // MARK: - ModularServiceProtocol Implementation

    func initialize() async throws {
        print("🚀 Initializing module: \(moduleName)")

        // Check dependencies
        for dependency in dependencies {
            guard ServiceModuleRegistry.shared.isModuleAvailable(dependency) else {
                throw ModuleError.dependencyUnavailable(dependency)
            }
        }

        // Perform module-specific initialization
        try await initializeModule()

        print("✅ Module initialized: \(moduleName)")
    }

    func start() async throws {
        print("▶️ Starting module: \(moduleName)")

        // Perform module-specific startup
        try await startModule()

        isHealthy = true
        print("✅ Module started: \(moduleName)")
    }

    func stop() async {
        print("⏹️ Stopping module: \(moduleName)")

        isHealthy = false

        // Perform module-specific shutdown
        await stopModule()

        print("✅ Module stopped: \(moduleName)")
    }

    func cleanup() async {
        print("🧹 Cleaning up module: \(moduleName)")

        // Perform module-specific cleanup
        await cleanupModule()

        print("✅ Module cleaned up: \(moduleName)")
    }

    func healthCheck() async -> ServiceHealthStatus {
        do {
            // Perform module-specific health check
            try await performHealthCheck()
            return .healthy
        } catch {
            lastError = error
            return .unhealthy(error: error)
        }
    }

    // MARK: - Override Points for Subclasses

    /// Override this method to perform module-specific initialization
    func initializeModule() async throws {
        // Default implementation does nothing
    }

    /// Override this method to perform module-specific startup
    func startModule() async throws {
        // Default implementation does nothing
    }

    /// Override this method to perform module-specific shutdown
    func stopModule() async {
        // Default implementation does nothing
    }

    /// Override this method to perform module-specific cleanup
    func cleanupModule() async {
        // Default implementation does nothing
    }

    /// Override this method to perform module-specific health checks
    func performHealthCheck() async throws {
        // Default implementation checks basic connectivity
        guard supabaseService.isAuthenticated else {
            throw ModuleError.authenticationRequired
        }
    }

    // MARK: - Error Handling

    protected func handleError(_ error: Error) {
        lastError = error
        isHealthy = false
        print("❌ Module error in \(moduleName): \(error.localizedDescription)")
    }
}

// MARK: - Module Errors

enum ModuleError: LocalizedError {
    case dependencyUnavailable(String)
    case authenticationRequired
    case initializationFailed(String)
    case healthCheckFailed(String)

    var errorDescription: String? {
        switch self {
        case .dependencyUnavailable(let dependency):
            return "Required dependency '\(dependency)' is not available"
        case .authenticationRequired:
            return "User authentication is required for this module"
        case .initializationFailed(let reason):
            return "Module initialization failed: \(reason)"
        case .healthCheckFailed(let reason):
            return "Health check failed: \(reason)"
        }
    }
}