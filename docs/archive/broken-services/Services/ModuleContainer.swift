import Foundation
import Combine

// MARK: - Module Container for Isolated Dependency Injection

@MainActor
final class ModuleContainer: ObservableObject {

    // MARK: - Container State

    private var services: [String: Any] = [:]
    private var singletons: [String: Any] = [:]
    private let containerName: String

    // MARK: - Initialization

    init(name: String) {
        self.containerName = name
        print("📦 ModuleContainer '\(name)' initialized")
    }

    // MARK: - Service Registration

    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        services[key] = factory
        print("📝 Registered service: \(key) in container '\(containerName)'")
    }

    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        services[key] = factory
        print("📝 Registered singleton: \(key) in container '\(containerName)'")
    }

    func registerInstance<T>(_ instance: T, for type: T.Type) {
        let key = String(describing: type)
        singletons[key] = instance
        print("📝 Registered instance: \(key) in container '\(containerName)'")
    }

    // MARK: - Service Resolution

    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)

        // Check for existing singleton first
        if let singleton = singletons[key] as? T {
            return singleton
        }

        // Create new instance from factory
        guard let factory = services[key] as? () -> T else {
            print("⚠️ Service not found: \(key) in container '\(containerName)'")
            return nil
        }

        let instance = factory()

        // Store as singleton if this was registered as a singleton
        if services[key] != nil {
            singletons[key] = instance
        }

        return instance
    }

    func resolveRequired<T>(_ type: T.Type) -> T {
        guard let service = resolve(type) else {
            fatalError("Required service not found: \(String(describing: type)) in container '\(containerName)'")
        }
        return service
    }

    // MARK: - Container Management

    func clear() {
        services.removeAll()
        singletons.removeAll()
        print("🧹 Cleared container '\(containerName)'")
    }

    var debugDescription: String {
        var info = "ModuleContainer '\(containerName)':\n"
        info += "Registered Services: \(services.keys.joined(separator: ", "))\n"
        info += "Active Singletons: \(singletons.keys.joined(separator: ", "))\n"
        return info
    }
}

// MARK: - Inter-Module Communication Event Bus

@MainActor
final class ModuleEventBus: ObservableObject {
    static let shared = ModuleEventBus()

    // MARK: - Event System

    private var subscribers: [String: [(ModuleEvent) -> Void]] = [:]
    private let eventSubject = PassthroughSubject<ModuleEvent, Never>()

    private init() {
        print("📡 ModuleEventBus initialized")
    }

    // MARK: - Event Publishing

    func publish(_ event: ModuleEvent) {
        print("📤 Publishing event: \(event.type) from \(event.sourceModule)")

        // Notify direct subscribers
        if let eventSubscribers = subscribers[event.type] {
            for handler in eventSubscribers {
                handler(event)
            }
        }

        // Notify Combine subscribers
        eventSubject.send(event)
    }

    // MARK: - Event Subscription

    func subscribe(to eventType: String, handler: @escaping (ModuleEvent) -> Void) -> EventSubscription {
        if subscribers[eventType] == nil {
            subscribers[eventType] = []
        }

        subscribers[eventType]?.append(handler)
        print("📥 Subscribed to event type: \(eventType)")

        return EventSubscription(eventType: eventType, eventBus: self)
    }

    func unsubscribe(from eventType: String) {
        subscribers.removeValue(forKey: eventType)
        print("📤 Unsubscribed from event type: \(eventType)")
    }

    // MARK: - Combine Integration

    var publisher: AnyPublisher<ModuleEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func publisher(for eventType: String) -> AnyPublisher<ModuleEvent, Never> {
        eventSubject
            .filter { $0.type == eventType }
            .eraseToAnyPublisher()
    }
}

// MARK: - Event Subscription Management

class EventSubscription {
    private let eventType: String
    private weak var eventBus: ModuleEventBus?

    init(eventType: String, eventBus: ModuleEventBus) {
        self.eventType = eventType
        self.eventBus = eventBus
    }

    func cancel() {
        eventBus?.unsubscribe(from: eventType)
    }
}

// MARK: - Module Event Definition

struct ModuleEvent {
    let type: String
    let sourceModule: String
    let data: [String: Any]
    let timestamp: Date

    init(type: String, sourceModule: String, data: [String: Any] = [:]) {
        self.type = type
        self.sourceModule = sourceModule
        self.data = data
        self.timestamp = Date()
    }
}

// MARK: - Common Event Types

extension ModuleEvent {
    // Onboarding Events
    static func onboardingStarted(from module: String) -> ModuleEvent {
        ModuleEvent(type: "onboarding.started", sourceModule: module)
    }

    static func onboardingCompleted(from module: String, userData: [String: Any]) -> ModuleEvent {
        ModuleEvent(type: "onboarding.completed", sourceModule: module, data: userData)
    }

    // Profile Events
    static func profileUpdated(from module: String, userId: String) -> ModuleEvent {
        ModuleEvent(type: "profile.updated", sourceModule: module, data: ["userId": userId])
    }

    // Discovery Events
    static func searchPerformed(from module: String, query: String, results: Int) -> ModuleEvent {
        ModuleEvent(type: "discovery.search", sourceModule: module, data: ["query": query, "resultCount": results])
    }

    // Settings Events
    static func settingChanged(from module: String, key: String, value: Any) -> ModuleEvent {
        ModuleEvent(type: "settings.changed", sourceModule: module, data: ["key": key, "value": value])
    }

    // Gamification Events
    static func achievementUnlocked(from module: String, achievementId: String) -> ModuleEvent {
        ModuleEvent(type: "gamification.achievement", sourceModule: module, data: ["achievementId": achievementId])
    }
}

// MARK: - Data Isolation Layer

protocol DataIsolationLayer {
    associatedtype DataType

    func store(_ data: DataType, key: String) async throws
    func retrieve(key: String) async throws -> DataType?
    func delete(key: String) async throws
    func clearAll() async throws
}

// MARK: - Module-Specific Data Store

@MainActor
class ModuleDataStore<T: Codable>: DataIsolationLayer {
    typealias DataType = T

    private let moduleId: String
    private var cache: [String: T] = [:]

    init(moduleId: String) {
        self.moduleId = moduleId
    }

    // MARK: - DataIsolationLayer Implementation

    func store(_ data: T, key: String) async throws {
        let fullKey = "\(moduleId).\(key)"
        cache[fullKey] = data

        // Persist to UserDefaults for simple data
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: fullKey)
        }

        print("💾 Stored data for key: \(fullKey)")
    }

    func retrieve(key: String) async throws -> T? {
        let fullKey = "\(moduleId).\(key)"

        // Check cache first
        if let cachedData = cache[fullKey] {
            return cachedData
        }

        // Try to load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: fullKey),
           let decoded = try? JSONDecoder().decode(T.self, from: data) {
            cache[fullKey] = decoded
            return decoded
        }

        return nil
    }

    func delete(key: String) async throws {
        let fullKey = "\(moduleId).\(key)"
        cache.removeValue(forKey: fullKey)
        UserDefaults.standard.removeObject(forKey: fullKey)
        print("🗑️ Deleted data for key: \(fullKey)")
    }

    func clearAll() async throws {
        let prefix = "\(moduleId)."
        let keysToRemove = cache.keys.filter { $0.hasPrefix(prefix) }

        for key in keysToRemove {
            cache.removeValue(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }

        print("🧹 Cleared all data for module: \(moduleId)")
    }
}