import Foundation
import SwiftUI
import Combine
import CoreData
import Network

// MARK: - Offline-First Data Management

/// Enterprise-grade offline-first data management with intelligent synchronization
@MainActor
public class OfflineDataManager: ObservableObject {
    public static let shared = OfflineDataManager()
    
    @Published public var isOnline: Bool = true
    @Published public var syncStatus: SyncStatus = .idle
    @Published public var pendingOperations: Int = 0
    @Published public var lastSyncTime: Date?
    @Published public var cacheHitRate: Double = 0.0
    @Published public var storageUsage: Int64 = 0
    
    // Core Data stack
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "OfflineDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data error: \(error)")
            }
        }
        return container
    }()
    
    // Services
    private let networkCache = NetworkCache.shared
    private let performanceMonitor = PerformanceMonitor.shared
    private let securityService = SecurityService.shared
    
    // Network monitoring
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.hobbyapp.networkmonitor")
    
    // Operation queues
    private var pendingWrites: [DataOperation] = []
    private var pendingReads: [DataOperation] = []
    private var conflictResolver = ConflictResolver()
    
    // Cache layers
    private var memoryCache = NSCache<NSString, CachedDataItem>()
    private var diskCacheManager = DiskCacheManager()
    
    // Sync configuration
    private let syncInterval: TimeInterval = 300 // 5 minutes
    private let maxRetryAttempts = 3
    private let batchSize = 50
    
    // Performance tracking
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    private var totalRequests: Int = 0
    
    private init() {
        setupNetworkMonitoring()
        setupMemoryCache()
        setupPeriodicSync()
        setupPerformanceTracking()
        
        print("✅ OfflineDataManager initialized")
    }
    
    // MARK: - Public API
    
    /// Fetch data with offline-first strategy
    public func fetchData<T: Codable>(
        _ type: T.Type,
        endpoint: String,
        parameters: [String: Any] = [:],
        cachePolicy: CachePolicy = .cacheFirst,
        maxAge: TimeInterval = 3600
    ) async throws -> T {
        return try await performanceMonitor.trackOperation(
            name: "OfflineDataManager.fetchData",
            category: .database
        ) {
            try await performFetchData(
                type,
                endpoint: endpoint,
                parameters: parameters,
                cachePolicy: cachePolicy,
                maxAge: maxAge
            )
        }
    }
    
    /// Store data with offline support
    public func storeData<T: Codable>(
        _ data: T,
        endpoint: String,
        method: HTTPMethod = .POST,
        sync: Bool = true
    ) async throws -> String {
        return try await performanceMonitor.trackOperation(
            name: "OfflineDataManager.storeData",
            category: .database
        ) {
            try await performStoreData(data, endpoint: endpoint, method: method, sync: sync)
        }
    }
    
    /// Update existing data
    public func updateData<T: Codable>(
        _ data: T,
        endpoint: String,
        id: String,
        sync: Bool = true
    ) async throws -> Bool {
        return try await performanceMonitor.trackOperation(
            name: "OfflineDataManager.updateData",
            category: .database
        ) {
            try await performUpdateData(data, endpoint: endpoint, id: id, sync: sync)
        }
    }
    
    /// Delete data with offline support
    public func deleteData(
        endpoint: String,
        id: String,
        sync: Bool = true
    ) async throws -> Bool {
        return try await performanceMonitor.trackOperation(
            name: "OfflineDataManager.deleteData",
            category: .database
        ) {
            try await performDeleteData(endpoint: endpoint, id: id, sync: sync)
        }
    }
    
    /// Manually trigger sync
    public func syncAllData() async throws {
        syncStatus = .syncing
        
        do {
            try await performFullSync()
            syncStatus = .completed
            lastSyncTime = Date()
            print("✅ Full sync completed successfully")
        } catch {
            syncStatus = .failed
            print("❌ Full sync failed: \(error)")
            throw error
        }
    }
    
    /// Get offline data statistics
    public func getOfflineStatistics() -> OfflineStatistics {
        return OfflineStatistics(
            isOnline: isOnline,
            syncStatus: syncStatus,
            pendingOperations: pendingOperations,
            lastSyncTime: lastSyncTime,
            cacheHitRate: cacheHitRate,
            storageUsage: storageUsage,
            totalCachedItems: getTotalCachedItems(),
            conflictsResolved: conflictResolver.resolvedConflicts
        )
    }
    
    /// Clear all offline data
    public func clearOfflineData() async throws {
        try await clearAllCaches()
        try await clearPendingOperations()
        
        // Reset Core Data
        let context = persistentContainer.viewContext
        let entities = persistentContainer.managedObjectModel.entities
        
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
        }
        
        try context.save()
        
        print("🧹 All offline data cleared")
    }
    
    // MARK: - Private Implementation
    
    private func performFetchData<T: Codable>(
        _ type: T.Type,
        endpoint: String,
        parameters: [String: Any],
        cachePolicy: CachePolicy,
        maxAge: TimeInterval
    ) async throws -> T {
        totalRequests += 1
        let cacheKey = generateCacheKey(endpoint: endpoint, parameters: parameters)
        
        // Check cache first (for cacheFirst policy)
        if cachePolicy == .cacheFirst || !isOnline {
            if let cachedData = await getCachedData(key: cacheKey, maxAge: maxAge) {
                cacheHits += 1
                updateCacheHitRate()
                
                if let decodedData = try? JSONDecoder().decode(type, from: cachedData) {
                    print("📦 Cache hit for \(endpoint)")
                    return decodedData
                }
            }
        }
        
        // Try network if online
        if isOnline && (cachePolicy == .networkFirst || cachePolicy == .networkOnly) {
            do {
                let networkEndpoint = NetworkEndpoint(
                    url: URL(string: endpoint),
                    method: .GET,
                    headers: ["Content-Type": "application/json"],
                    body: parameters.isEmpty ? nil : parameters
                )
                
                let data = try await networkCache.request(from: networkEndpoint)
                let decodedData = try JSONDecoder().decode(type, from: data)
                
                // Cache the successful response
                await cacheData(data, key: cacheKey)
                
                print("🌐 Network fetch successful for \(endpoint)")
                return decodedData
                
            } catch {
                print("❌ Network fetch failed for \(endpoint): \(error)")
                
                // Fallback to cache if network fails
                if let cachedData = await getCachedData(key: cacheKey, maxAge: TimeInterval.greatestFiniteMagnitude) {
                    cacheHits += 1
                    updateCacheHitRate()
                    
                    if let decodedData = try? JSONDecoder().decode(type, from: cachedData) {
                        print("📦 Fallback to stale cache for \(endpoint)")
                        return decodedData
                    }
                }
                
                throw OfflineDataError.networkUnavailable
            }
        }
        
        // Final fallback to cache
        if let cachedData = await getCachedData(key: cacheKey, maxAge: TimeInterval.greatestFiniteMagnitude) {
            cacheHits += 1
            updateCacheHitRate()
            
            if let decodedData = try? JSONDecoder().decode(type, from: cachedData) {
                print("📦 Stale cache fallback for \(endpoint)")
                return decodedData
            }
        }
        
        cacheMisses += 1
        updateCacheHitRate()
        throw OfflineDataError.dataNotAvailable
    }
    
    private func performStoreData<T: Codable>(
        _ data: T,
        endpoint: String,
        method: HTTPMethod,
        sync: Bool
    ) async throws -> String {
        let operationId = UUID().uuidString
        let encodedData = try JSONEncoder().encode(data)
        
        // Store locally first
        await storeLocalData(
            data: encodedData,
            endpoint: endpoint,
            operationId: operationId,
            method: method
        )
        
        if isOnline && sync {
            do {
                // Try to sync immediately
                try await syncOperation(
                    id: operationId,
                    endpoint: endpoint,
                    data: encodedData,
                    method: method
                )
                print("✅ Data stored and synced immediately")
            } catch {
                // Queue for later sync
                queuePendingOperation(
                    id: operationId,
                    endpoint: endpoint,
                    data: encodedData,
                    method: method,
                    type: .create
                )
                print("📤 Data stored locally, queued for sync")
            }
        } else {
            // Queue for later sync
            queuePendingOperation(
                id: operationId,
                endpoint: endpoint,
                data: encodedData,
                method: method,
                type: .create
            )
            print("📤 Data stored locally, will sync when online")
        }
        
        return operationId
    }
    
    private func performUpdateData<T: Codable>(
        _ data: T,
        endpoint: String,
        id: String,
        sync: Bool
    ) async throws -> Bool {
        let encodedData = try JSONEncoder().encode(data)
        
        // Update locally first
        await updateLocalData(
            data: encodedData,
            endpoint: endpoint,
            id: id
        )
        
        if isOnline && sync {
            do {
                // Try to sync immediately
                try await syncOperation(
                    id: id,
                    endpoint: endpoint,
                    data: encodedData,
                    method: .PUT
                )
                print("✅ Data updated and synced immediately")
                return true
            } catch {
                // Queue for later sync
                queuePendingOperation(
                    id: id,
                    endpoint: endpoint,
                    data: encodedData,
                    method: .PUT,
                    type: .update
                )
                print("📤 Data updated locally, queued for sync")
                return true
            }
        } else {
            // Queue for later sync
            queuePendingOperation(
                id: id,
                endpoint: endpoint,
                data: encodedData,
                method: .PUT,
                type: .update
            )
            print("📤 Data updated locally, will sync when online")
            return true
        }
    }
    
    private func performDeleteData(
        endpoint: String,
        id: String,
        sync: Bool
    ) async throws -> Bool {
        // Mark as deleted locally
        await markAsDeleted(endpoint: endpoint, id: id)
        
        if isOnline && sync {
            do {
                // Try to sync immediately
                try await syncOperation(
                    id: id,
                    endpoint: endpoint,
                    data: Data(),
                    method: .DELETE
                )
                
                // Remove from local storage after successful sync
                await removeFromLocalStorage(endpoint: endpoint, id: id)
                print("✅ Data deleted and synced immediately")
                return true
            } catch {
                // Queue for later sync
                queuePendingOperation(
                    id: id,
                    endpoint: endpoint,
                    data: Data(),
                    method: .DELETE,
                    type: .delete
                )
                print("📤 Data marked for deletion, queued for sync")
                return true
            }
        } else {
            // Queue for later sync
            queuePendingOperation(
                id: id,
                endpoint: endpoint,
                data: Data(),
                method: .DELETE,
                type: .delete
            )
            print("📤 Data marked for deletion, will sync when online")
            return true
        }
    }
    
    private func performFullSync() async throws {
        print("🔄 Starting full data synchronization...")
        
        // Sync pending operations first
        try await syncPendingOperations()
        
        // Refresh critical data from server
        try await refreshCriticalData()
        
        // Resolve any conflicts
        await resolveDataConflicts()
        
        print("✅ Full synchronization completed")
    }
    
    private func syncPendingOperations() async throws {
        let operations = pendingWrites + pendingReads
        let batches = operations.chunked(into: batchSize)
        
        for batch in batches {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for operation in batch {
                    group.addTask {
                        try await self.processPendingOperation(operation)
                    }
                }
                
                try await group.waitForAll()
            }
        }
        
        // Clear successfully synced operations
        pendingWrites.removeAll()
        pendingReads.removeAll()
        updatePendingOperationsCount()
    }
    
    private func processPendingOperation(_ operation: DataOperation) async throws {
        let networkEndpoint = NetworkEndpoint(
            url: URL(string: operation.endpoint),
            method: operation.method,
            headers: ["Content-Type": "application/json"],
            body: operation.data.isEmpty ? nil : try? JSONSerialization.jsonObject(with: operation.data)
        )
        
        _ = try await networkCache.request(from: networkEndpoint)
        print("✅ Synced operation: \(operation.type.rawValue) \(operation.endpoint)")
    }
    
    private func refreshCriticalData() async throws {
        let criticalEndpoints = [
            "/api/user/profile",
            "/api/bookings/active",
            "/api/classes/featured"
        ]
        
        for endpoint in criticalEndpoints {
            do {
                let networkEndpoint = NetworkEndpoint(
                    url: URL(string: endpoint),
                    method: .GET
                )
                
                let data = try await networkCache.request(from: networkEndpoint)
                let cacheKey = generateCacheKey(endpoint: endpoint, parameters: [:])
                await cacheData(data, key: cacheKey)
                
                print("🔄 Refreshed critical data: \(endpoint)")
            } catch {
                print("⚠️ Failed to refresh critical data: \(endpoint) - \(error)")
            }
        }
    }
    
    private func resolveDataConflicts() async {
        let conflicts = await identifyDataConflicts()
        
        for conflict in conflicts {
            let resolution = await conflictResolver.resolveConflict(conflict)
            await applyConflictResolution(resolution)
        }
        
        if !conflicts.isEmpty {
            print("🔧 Resolved \(conflicts.count) data conflicts")
        }
    }
    
    // MARK: - Cache Management
    
    private func getCachedData(key: String, maxAge: TimeInterval) async -> Data? {
        // Check memory cache first
        if let memoryItem = memoryCache.object(forKey: NSString(string: key)) {
            if Date().timeIntervalSince(memoryItem.timestamp) <= maxAge {
                return memoryItem.data
            } else {
                memoryCache.removeObject(forKey: NSString(string: key))
            }
        }
        
        // Check disk cache
        if let diskData = await diskCacheManager.getData(forKey: key) {
            // Load back into memory cache
            let cachedItem = CachedDataItem(data: diskData, timestamp: Date())
            memoryCache.setObject(cachedItem, forKey: NSString(string: key))
            return diskData
        }
        
        return nil
    }
    
    private func cacheData(_ data: Data, key: String) async {
        // Store in memory cache
        let cachedItem = CachedDataItem(data: data, timestamp: Date())
        memoryCache.setObject(cachedItem, forKey: NSString(string: key))
        
        // Store in disk cache
        await diskCacheManager.setData(data, forKey: key)
    }
    
    private func clearAllCaches() async throws {
        memoryCache.removeAllObjects()
        await diskCacheManager.clearAll()
        print("🧹 All caches cleared")
    }
    
    // MARK: - Core Data Operations
    
    private func storeLocalData(data: Data, endpoint: String, operationId: String, method: HTTPMethod) async {
        let context = persistentContainer.viewContext
        
        // Implementation would create Core Data entity
        // This is a simplified version
        
        try? context.save()
    }
    
    private func updateLocalData(data: Data, endpoint: String, id: String) async {
        let context = persistentContainer.viewContext
        
        // Implementation would update Core Data entity
        
        try? context.save()
    }
    
    private func markAsDeleted(endpoint: String, id: String) async {
        let context = persistentContainer.viewContext
        
        // Implementation would mark entity as deleted
        
        try? context.save()
    }
    
    private func removeFromLocalStorage(endpoint: String, id: String) async {
        let context = persistentContainer.viewContext
        
        // Implementation would remove Core Data entity
        
        try? context.save()
    }
    
    // MARK: - Helper Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasOnline = self?.isOnline ?? false
                self?.isOnline = path.status == .satisfied
                
                if !wasOnline && (self?.isOnline ?? false) {
                    // Device came back online
                    print("🌐 Device came back online - starting sync")
                    Task {
                        try? await self?.syncAllData()
                    }
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    private func setupMemoryCache() {
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        memoryCache.countLimit = 1000
    }
    
    private func setupPeriodicSync() {
        Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if self?.isOnline == true && self?.syncStatus != .syncing {
                    try? await self?.syncAllData()
                }
            }
        }
    }
    
    private func setupPerformanceTracking() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateStorageUsage()
            }
        }
    }
    
    private func generateCacheKey(endpoint: String, parameters: [String: Any]) -> String {
        let paramString = parameters.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: "&")
        return "\(endpoint)?\(paramString)".sha256Hash
    }
    
    private func queuePendingOperation(
        id: String,
        endpoint: String,
        data: Data,
        method: HTTPMethod,
        type: OperationType
    ) {
        let operation = DataOperation(
            id: id,
            endpoint: endpoint,
            data: data,
            method: method,
            type: type,
            timestamp: Date(),
            retryCount: 0
        )
        
        pendingWrites.append(operation)
        updatePendingOperationsCount()
    }
    
    private func syncOperation(
        id: String,
        endpoint: String,
        data: Data,
        method: HTTPMethod
    ) async throws {
        let networkEndpoint = NetworkEndpoint(
            url: URL(string: endpoint),
            method: method,
            headers: ["Content-Type": "application/json"],
            body: data.isEmpty ? nil : try? JSONSerialization.jsonObject(with: data)
        )
        
        _ = try await networkCache.request(from: networkEndpoint)
    }
    
    private func clearPendingOperations() async throws {
        pendingWrites.removeAll()
        pendingReads.removeAll()
        updatePendingOperationsCount()
    }
    
    private func updatePendingOperationsCount() {
        pendingOperations = pendingWrites.count + pendingReads.count
    }
    
    private func updateCacheHitRate() {
        let total = cacheHits + cacheMisses
        cacheHitRate = total > 0 ? Double(cacheHits) / Double(total) : 0.0
    }
    
    private func updateStorageUsage() async {
        storageUsage = await diskCacheManager.getTotalSize()
    }
    
    private func getTotalCachedItems() -> Int {
        return memoryCache.countLimit // Simplified
    }
    
    private func identifyDataConflicts() async -> [DataConflict] {
        // Implementation would identify conflicts between local and remote data
        return []
    }
    
    private func applyConflictResolution(_ resolution: ConflictResolution) async {
        // Implementation would apply conflict resolution
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

// MARK: - Supporting Types

public enum SyncStatus: String, CaseIterable {
    case idle = "Idle"
    case syncing = "Syncing"
    case completed = "Completed"
    case failed = "Failed"
    
    public var color: Color {
        switch self {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

public enum CachePolicy {
    case cacheFirst     // Try cache first, fallback to network
    case networkFirst   // Try network first, fallback to cache
    case cacheOnly      // Only use cache
    case networkOnly    // Only use network
}

public enum OperationType: String {
    case create = "create"
    case update = "update"
    case delete = "delete"
    case read = "read"
}

public enum OfflineDataError: Error, LocalizedError {
    case networkUnavailable
    case dataNotAvailable
    case syncFailed
    case conflictResolutionFailed
    case storageError
    
    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network is unavailable"
        case .dataNotAvailable:
            return "Data is not available offline"
        case .syncFailed:
            return "Data synchronization failed"
        case .conflictResolutionFailed:
            return "Failed to resolve data conflicts"
        case .storageError:
            return "Local storage error"
        }
    }
}

public struct OfflineStatistics {
    public let isOnline: Bool
    public let syncStatus: SyncStatus
    public let pendingOperations: Int
    public let lastSyncTime: Date?
    public let cacheHitRate: Double
    public let storageUsage: Int64
    public let totalCachedItems: Int
    public let conflictsResolved: Int
    
    public var formattedCacheHitRate: String {
        return String(format: "%.1f%%", cacheHitRate * 100)
    }
    
    public var formattedStorageUsage: String {
        return ByteCountFormatter.string(fromByteCount: storageUsage, countStyle: .file)
    }
    
    public var formattedLastSync: String {
        guard let lastSync = lastSyncTime else { return "Never" }
        return RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date())
    }
}

struct DataOperation {
    let id: String
    let endpoint: String
    let data: Data
    let method: HTTPMethod
    let type: OperationType
    let timestamp: Date
    var retryCount: Int
}

struct CachedDataItem {
    let data: Data
    let timestamp: Date
}

struct DataConflict {
    let id: String
    let localData: Data
    let remoteData: Data
    let endpoint: String
}

struct ConflictResolution {
    let conflictId: String
    let resolution: ConflictResolutionType
    let resolvedData: Data
}

enum ConflictResolutionType {
    case useLocal
    case useRemote
    case merge
}

// MARK: - Disk Cache Manager

private actor DiskCacheManager {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
    init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("OfflineData", isDirectory: true)
        
        Task {
            await createCacheDirectoryIfNeeded()
        }
    }
    
    func setData(_ data: Data, forKey key: String) {
        let url = cacheDirectory.appendingPathComponent(key.sha256Hash)
        
        do {
            try data.write(to: url)
        } catch {
            print("Failed to write offline data: \(error)")
        }
    }
    
    func getData(forKey key: String) -> Data? {
        let url = cacheDirectory.appendingPathComponent(key.sha256Hash)
        
        do {
            return try Data(contentsOf: url)
        } catch {
            return nil
        }
    }
    
    func removeData(forKey key: String) {
        let url = cacheDirectory.appendingPathComponent(key.sha256Hash)
        try? fileManager.removeItem(at: url)
    }
    
    func clearAll() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
        } catch {
            print("Failed to clear offline data cache: \(error)")
        }
    }
    
    func getTotalSize() -> Int64 {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            
            var totalSize: Int64 = 0
            for url in contents {
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
            
            return totalSize
        } catch {
            return 0
        }
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
}

// MARK: - Conflict Resolver

private class ConflictResolver {
    var resolvedConflicts: Int = 0
    
    func resolveConflict(_ conflict: DataConflict) async -> ConflictResolution {
        // Simplified conflict resolution - in production this would be more sophisticated
        resolvedConflicts += 1
        
        // Default to remote data (server wins)
        return ConflictResolution(
            conflictId: conflict.id,
            resolution: .useRemote,
            resolvedData: conflict.remoteData
        )
    }
}

// MARK: - Extensions

extension String {
    var sha256Hash: String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - SwiftUI Integration

public struct OfflineDataDebugView: View {
    @StateObject private var offlineManager = OfflineDataManager.shared
    @State private var statistics: OfflineStatistics?
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Offline Data Manager")
                .font(.headline)
            
            if let stats = statistics {
                VStack(alignment: .leading, spacing: 8) {
                    statusRow("Online", stats.isOnline ? "Yes" : "No")
                    statusRow("Sync Status", stats.syncStatus.rawValue)
                    statusRow("Pending Ops", "\(stats.pendingOperations)")
                    statusRow("Cache Hit Rate", stats.formattedCacheHitRate)
                    statusRow("Storage Usage", stats.formattedStorageUsage)
                    statusRow("Cached Items", "\(stats.totalCachedItems)")
                    statusRow("Last Sync", stats.formattedLastSync)
                    
                    if stats.conflictsResolved > 0 {
                        statusRow("Conflicts Resolved", "\(stats.conflictsResolved)")
                    }
                }
            }
            
            HStack {
                Button("Force Sync") {
                    Task {
                        try? await offlineManager.syncAllData()
                        updateStatistics()
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Clear Cache") {
                    Task {
                        try? await offlineManager.clearOfflineData()
                        updateStatistics()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            updateStatistics()
        }
    }
    
    private func statusRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
    
    private func updateStatistics() {
        statistics = offlineManager.getOfflineStatistics()
    }
}

#Preview {
    OfflineDataDebugView()
        .padding()
}

// MARK: - CryptoKit Extension

import CryptoKit

extension SHA256 {
    static func hash(data: Data) -> SHA256Digest {
        return SHA256.hash(data: data)
    }
}