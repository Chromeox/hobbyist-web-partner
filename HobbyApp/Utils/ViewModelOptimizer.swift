import Foundation
import SwiftUI
import Combine

// MARK: - ViewModel Memory Optimization Framework

/// Base class for optimized ViewModels with memory leak prevention and performance monitoring
@MainActor
open class OptimizedViewModel: ObservableObject {
    // Memory management
    private var cancellables = Set<AnyCancellable>()
    private var activeTasks: Set<Task<Void, Never>> = []
    private var retainedObjects: [String: Any] = [:]
    private var subscriptionTimestamps: [String: Date] = [:]
    
    // Performance monitoring
    private let performanceMonitor = PerformanceMonitor.shared
    private var operationStartTimes: [String: CFTimeInterval] = [:]
    private var memoryUsageAtInit: Int64
    
    // Lifecycle management
    @Published public var isActive: Bool = true
    @Published public var memoryUsage: Int64 = 0
    @Published public var activeSubscriptions: Int = 0
    
    // Configuration
    private let maxRetainedObjects = 50
    private let subscriptionTimeout: TimeInterval = 300 // 5 minutes
    private let memoryThreshold: Int64 = 100 * 1024 * 1024 // 100MB
    
    public init() {
        self.memoryUsageAtInit = getCurrentMemoryUsage()
        self.memoryUsage = memoryUsageAtInit
        
        setupMemoryMonitoring()
        setupPerformanceTracking()
        setupSubscriptionCleanup()
        
        print("✅ OptimizedViewModel initialized - Initial memory: \(ByteCountFormatter.string(fromByteCount: memoryUsageAtInit, countStyle: .memory))")
    }
    
    // MARK: - Memory Management
    
    /// Add a cancellable with automatic cleanup
    public func addCancellable(_ cancellable: AnyCancellable, identifier: String? = nil) {
        let id = identifier ?? UUID().uuidString
        cancellables.insert(cancellable)
        subscriptionTimestamps[id] = Date()
        updateActiveSubscriptionCount()
        
        print("📝 Added subscription: \(id) (Total: \(cancellables.count))")
    }
    
    /// Execute async task with memory tracking
    public func executeTask<T>(
        name: String,
        priority: TaskPriority = .userInitiated,
        operation: @escaping () async throws -> T
    ) async rethrows -> T {
        let task = Task(priority: priority) {
            await trackOperation(name: name) {
                _ = try? await operation()
            }
        }
        
        activeTasks.insert(task)
        
        defer {
            activeTasks.remove(task)
        }
        
        return try await operation()
    }
    
    /// Retain object with automatic cleanup
    public func retainObject(_ object: Any, key: String, ttl: TimeInterval = 300) {
        retainedObjects[key] = object
        
        // Schedule cleanup
        Task {
            try? await Task.sleep(nanoseconds: UInt64(ttl * 1_000_000_000))
            retainedObjects.removeValue(forKey: key)
        }
        
        // Enforce maximum retained objects
        if retainedObjects.count > maxRetainedObjects {
            let oldestKey = retainedObjects.keys.first!
            retainedObjects.removeValue(forKey: oldestKey)
        }
    }
    
    /// Get retained object
    public func getRetainedObject<T>(key: String, type: T.Type) -> T? {
        return retainedObjects[key] as? T
    }
    
    /// Clean up expired subscriptions
    private func cleanupExpiredSubscriptions() {
        let now = Date()
        var expiredKeys: [String] = []
        
        for (key, timestamp) in subscriptionTimestamps {
            if now.timeIntervalSince(timestamp) > subscriptionTimeout {
                expiredKeys.append(key)
            }
        }
        
        for key in expiredKeys {
            subscriptionTimestamps.removeValue(forKey: key)
        }
        
        if !expiredKeys.isEmpty {
            print("🧹 Cleaned up \(expiredKeys.count) expired subscriptions")
        }
    }
    
    // MARK: - Performance Tracking
    
    /// Track operation performance
    public func trackOperation<T>(name: String, operation: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()
        
        operationStartTimes[name] = startTime
        
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            let memoryDelta = getCurrentMemoryUsage() - startMemory
            
            operationStartTimes.removeValue(forKey: name)
            
            if duration > 1.0 {
                print("⚠️ Slow operation '\(name)': \(String(format: "%.2f", duration))s")
            }
            
            if memoryDelta > 10 * 1024 * 1024 { // 10MB threshold
                print("⚠️ High memory operation '\(name)': +\(ByteCountFormatter.string(fromByteCount: memoryDelta, countStyle: .memory))")
            }
        }
        
        return try await operation()
    }
    
    /// Check for memory leaks
    public func checkMemoryLeaks() -> MemoryLeakReport {
        let currentMemory = getCurrentMemoryUsage()
        let memoryGrowth = currentMemory - memoryUsageAtInit
        let memoryGrowthMB = Double(memoryGrowth) / (1024 * 1024)
        
        let report = MemoryLeakReport(
            initialMemory: memoryUsageAtInit,
            currentMemory: currentMemory,
            memoryGrowth: memoryGrowth,
            activeCancellables: cancellables.count,
            activeTasks: activeTasks.count,
            retainedObjects: retainedObjects.count,
            subscriptions: subscriptionTimestamps.count,
            isLeakSuspected: memoryGrowthMB > 50.0 || cancellables.count > 100
        )
        
        if report.isLeakSuspected {
            print("🚨 Memory leak suspected in \(String(describing: type(of: self)))")
            print("   Memory growth: +\(String(format: "%.1f", memoryGrowthMB))MB")
            print("   Active subscriptions: \(cancellables.count)")
            print("   Active tasks: \(activeTasks.count)")
        }
        
        return report
    }
    
    // MARK: - Cleanup Management
    
    /// Perform comprehensive cleanup
    public func performCleanup() {
        print("🧹 Performing cleanup for \(String(describing: type(of: self)))")
        
        // Cancel all subscriptions
        cancellables.removeAll()
        subscriptionTimestamps.removeAll()
        
        // Cancel active tasks
        for task in activeTasks {
            task.cancel()
        }
        activeTasks.removeAll()
        
        // Clear retained objects
        retainedObjects.removeAll()
        
        // Update counters
        updateActiveSubscriptionCount()
        updateMemoryUsage()
        
        print("✅ Cleanup completed")
    }
    
    /// Lifecycle cleanup on deactivation
    public func deactivate() {
        isActive = false
        performCleanup()
        
        print("🔄 ViewModel deactivated: \(String(describing: type(of: self)))")
    }
    
    // MARK: - Private Implementation
    
    private func setupMemoryMonitoring() {
        // Monitor memory usage every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryUsage()
                self?.checkMemoryThreshold()
            }
        }
    }
    
    private func setupPerformanceTracking() {
        // Track performance metrics
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                let _ = self?.checkMemoryLeaks()
            }
        }
    }
    
    private func setupSubscriptionCleanup() {
        // Clean up expired subscriptions every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupExpiredSubscriptions()
            }
        }
    }
    
    private func updateMemoryUsage() {
        memoryUsage = getCurrentMemoryUsage()
    }
    
    private func updateActiveSubscriptionCount() {
        activeSubscriptions = cancellables.count
    }
    
    private func checkMemoryThreshold() {
        if memoryUsage > memoryThreshold {
            print("⚠️ Memory threshold exceeded: \(ByteCountFormatter.string(fromByteCount: memoryUsage, countStyle: .memory))")
            
            // Trigger aggressive cleanup
            retainedObjects.removeAll()
            cleanupExpiredSubscriptions()
            
            // Force garbage collection hint
            autoreleasepool { }
        }
    }
    
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    deinit {
        print("♻️ Deinitializing \(String(describing: type(of: self)))")
        performCleanup()
    }
}

// MARK: - Memory Leak Detection

public struct MemoryLeakReport {
    public let initialMemory: Int64
    public let currentMemory: Int64
    public let memoryGrowth: Int64
    public let activeCancellables: Int
    public let activeTasks: Int
    public let retainedObjects: Int
    public let subscriptions: Int
    public let isLeakSuspected: Bool
    public let timestamp: Date = Date()
    
    public var formattedMemoryGrowth: String {
        return ByteCountFormatter.string(fromByteCount: memoryGrowth, countStyle: .memory)
    }
    
    public var memoryGrowthPercentage: Double {
        guard initialMemory > 0 else { return 0 }
        return Double(memoryGrowth) / Double(initialMemory) * 100
    }
}

// MARK: - Optimized Publisher Extensions

public extension Publisher {
    /// Subscribe with automatic cleanup and weak reference
    func sinkWithCleanup<T: OptimizedViewModel>(
        to viewModel: T,
        receiveValue: @escaping (T, Self.Output) -> Void
    ) -> AnyCancellable {
        return self.sink { [weak viewModel] output in
            guard let vm = viewModel else { return }
            receiveValue(vm, output)
        }
    }
    
    /// Subscribe with memory-safe error handling
    func sinkWithErrorHandling<T: OptimizedViewModel>(
        to viewModel: T,
        receiveValue: @escaping (T, Self.Output) -> Void,
        receiveCompletion: @escaping (T, Subscribers.Completion<Self.Failure>) -> Void = { _, _ in }
    ) -> AnyCancellable {
        return self.sink(
            receiveCompletion: { [weak viewModel] completion in
                guard let vm = viewModel else { return }
                receiveCompletion(vm, completion)
            },
            receiveValue: { [weak viewModel] output in
                guard let vm = viewModel else { return }
                receiveValue(vm, output)
            }
        )
    }
}

// MARK: - Optimized Timer

public class OptimizedTimer {
    private var timer: Timer?
    private weak var viewModel: OptimizedViewModel?
    
    public init(viewModel: OptimizedViewModel) {
        self.viewModel = viewModel
    }
    
    public func schedule(
        timeInterval: TimeInterval,
        repeats: Bool = true,
        action: @escaping () -> Void
    ) {
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: repeats) { [weak self] _ in
            guard self?.viewModel?.isActive == true else {
                self?.invalidate()
                return
            }
            action()
        }
    }
    
    public func invalidate() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        invalidate()
    }
}

// MARK: - Memory-Safe Task Manager

public class TaskManager {
    private var tasks: [String: Task<Void, Never>] = [:]
    private weak var viewModel: OptimizedViewModel?
    
    public init(viewModel: OptimizedViewModel) {
        self.viewModel = viewModel
    }
    
    public func execute(
        identifier: String,
        priority: TaskPriority = .userInitiated,
        operation: @escaping () async -> Void
    ) {
        // Cancel existing task with same identifier
        cancel(identifier: identifier)
        
        let task = Task(priority: priority) {
            guard viewModel?.isActive == true else { return }
            await operation()
        }
        
        tasks[identifier] = task
    }
    
    public func cancel(identifier: String) {
        tasks[identifier]?.cancel()
        tasks.removeValue(forKey: identifier)
    }
    
    public func cancelAll() {
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
    }
    
    deinit {
        cancelAll()
    }
}

// MARK: - Optimized HomeViewModel

@MainActor
public class OptimizedHomeViewModel: OptimizedViewModel {
    @Published var featuredClasses: [ClassItem] = []
    @Published var nearbyClasses: [ClassItem] = []
    @Published var upcomingClasses: [ClassItem] = []
    @Published var recommendedClasses: [ClassItem] = []
    @Published var categories: [ClassItem.Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Services with proper lifecycle management
    private let classService = ClassService.shared
    private let instructorService = InstructorService.shared
    private let searchService = SearchService.shared
    
    // Task management
    private let taskManager: TaskManager
    private let refreshTimer: OptimizedTimer
    
    public override init() {
        self.taskManager = TaskManager(viewModel: OptimizedViewModel())
        self.refreshTimer = OptimizedTimer(viewModel: OptimizedViewModel())
        
        super.init()
        
        self.taskManager = TaskManager(viewModel: self)
        self.refreshTimer = OptimizedTimer(viewModel: self)
        
        setupDataLoading()
        setupPeriodicRefresh()
    }
    
    private func setupDataLoading() {
        loadCategories()
        
        taskManager.execute(identifier: "initial-load") {
            await self.loadInitialData()
        }
    }
    
    private func setupPeriodicRefresh() {
        // Refresh data every 5 minutes
        refreshTimer.schedule(timeInterval: 300.0) {
            Task {
                await self.refreshContent()
            }
        }
    }
    
    private func loadCategories() {
        categories = [
            ClassItem.Category(name: "Ceramics", icon: "paintpalette"),
            ClassItem.Category(name: "Pottery", icon: "cup.and.saucer"),
            ClassItem.Category(name: "Painting", icon: "paintbrush"),
            ClassItem.Category(name: "Photography", icon: "camera"),
            ClassItem.Category(name: "Woodworking", icon: "hammer"),
            ClassItem.Category(name: "Jewelry Making", icon: "diamond"),
            ClassItem.Category(name: "Cooking", icon: "fork.knife.circle"),
            ClassItem.Category(name: "Dance", icon: "figure.dance"),
            ClassItem.Category(name: "Music", icon: "music.note"),
            ClassItem.Category(name: "Writing", icon: "pencil")
        ]
    }
    
    private func loadInitialData() async {
        await trackOperation(name: "loadInitialData") {
            isLoading = true
            errorMessage = nil
            
            do {
                // Load data concurrently for better performance
                async let classesTask = classService.fetchClasses()
                async let popularTask = classService.getPopularClasses()
                async let instructorsTask = instructorService.fetchInstructors()
                
                let (classes, popular, instructors) = try await (classesTask, popularTask, instructorsTask)
                
                // Process and cache results
                let classItems = classes.map { ClassItem.from(hobbyClass: $0) }
                let popularItems = popular.map { ClassItem.from(hobbyClass: $0) }
                
                // Update UI on main thread
                await MainActor.run {
                    self.featuredClasses = Array(popularItems.prefix(6))
                    self.nearbyClasses = Array(classItems.prefix(5))
                    self.upcomingClasses = Array(classItems.prefix(3))
                    self.recommendedClasses = Array(classItems.shuffled().prefix(4))
                }
                
                // Cache data for offline access
                retainObject(classItems, key: "cached_classes", ttl: 1800) // 30 minutes
                retainObject(instructors, key: "cached_instructors", ttl: 1800)
                
                print("✅ Loaded \(classes.count) classes and \(instructors.count) instructors")
                
            } catch {
                print("❌ Failed to load data: \(error)")
                errorMessage = error.localizedDescription
                
                // Try to use cached data
                if let cachedClasses: [ClassItem] = getRetainedObject(key: "cached_classes", type: [ClassItem].self) {
                    featuredClasses = Array(cachedClasses.prefix(6))
                    nearbyClasses = Array(cachedClasses.prefix(5))
                    print("🔄 Using cached data")
                }
            }
            
            isLoading = false
        }
    }
    
    public func searchClasses(query: String) {
        taskManager.execute(identifier: "search") {
            await self.performSearch(query: query)
        }
    }
    
    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            await loadInitialData()
            return
        }
        
        await trackOperation(name: "searchClasses") {
            isLoading = true
            errorMessage = nil
            
            do {
                let searchResults = try await searchService.searchClasses(query: query)
                let classItems = searchResults.map { ClassItem.from(hobbyClass: $0) }
                
                featuredClasses = Array(classItems.prefix(6))
                nearbyClasses = Array(classItems.prefix(5))
                upcomingClasses = Array(classItems.prefix(3))
                recommendedClasses = Array(classItems.shuffled().prefix(4))
                
                print("🔍 Found \(searchResults.count) classes for query: \(query)")
                
            } catch {
                print("❌ Search failed: \(error)")
                errorMessage = "Failed to search classes: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
    
    public func refreshContent() async {
        await loadInitialData()
    }
    
    public override func performCleanup() {
        taskManager.cancelAll()
        refreshTimer.invalidate()
        super.performCleanup()
    }
}

// MARK: - Memory Monitoring View

public struct ViewModelMemoryDebugView: View {
    @ObservedObject private var viewModel: OptimizedViewModel
    @State private var memoryReport: MemoryLeakReport?
    
    public init(viewModel: OptimizedViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ViewModel Memory Monitor")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                statusRow("Memory Usage", ByteCountFormatter.string(fromByteCount: viewModel.memoryUsage, countStyle: .memory))
                statusRow("Active Subscriptions", "\(viewModel.activeSubscriptions)")
                statusRow("Active", viewModel.isActive ? "Yes" : "No")
                
                if let report = memoryReport {
                    statusRow("Memory Growth", report.formattedMemoryGrowth)
                    statusRow("Active Tasks", "\(report.activeTasks)")
                    statusRow("Retained Objects", "\(report.retainedObjects)")
                    
                    if report.isLeakSuspected {
                        Text("⚠️ Memory leak suspected!")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            
            HStack {
                Button("Check Memory") {
                    memoryReport = viewModel.checkMemoryLeaks()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Cleanup") {
                    viewModel.performCleanup()
                    memoryReport = viewModel.checkMemoryLeaks()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            memoryReport = viewModel.checkMemoryLeaks()
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
}

#Preview {
    let viewModel = OptimizedHomeViewModel()
    return VStack {
        ViewModelMemoryDebugView(viewModel: viewModel)
    }
    .padding()
}