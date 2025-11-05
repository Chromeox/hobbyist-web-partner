import Foundation
import BackgroundTasks
import UserNotifications
import UIKit

// MARK: - Background Task Manager

/// Enterprise-grade background task management for data sync and notifications
@MainActor
public class BackgroundTaskManager: ObservableObject {
    public static let shared = BackgroundTaskManager()
    
    @Published public var isBackgroundRefreshEnabled: Bool = false
    @Published public var lastBackgroundUpdate: Date?
    @Published public var backgroundTasksRegistered: [String] = []
    @Published public var syncStatus: SyncStatus = .idle
    @Published public var pendingNotifications: Int = 0
    
    // Task identifiers
    private struct TaskIdentifiers {
        static let dataSync = "com.hobbyapp.background.datasync"
        static let bookingReminders = "com.hobbyapp.background.bookingreminders"
        static let classUpdates = "com.hobbyapp.background.classupdates"
        static let locationSync = "com.hobbyapp.background.locationsync"
        static let performanceCleanup = "com.hobbyapp.background.cleanup"
    }
    
    // Services
    private let notificationCenter = UNUserNotificationCenter.current()
    private let performanceMonitor = PerformanceMonitor.shared
    private let securityService = SecurityService.shared
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // Sync managers
    private let dataSyncManager = DataSyncManager()
    private let bookingSyncManager = BookingSyncManager()
    private let locationSyncManager = LocationSyncManager()
    private let performanceCleanupManager = PerformanceCleanupManager()
    
    // Configuration
    private let maxBackgroundTime: TimeInterval = 25.0 // iOS gives us ~30 seconds
    private let syncInterval: TimeInterval = 60.0 * 60.0 // 1 hour
    
    private init() {
        setupBackgroundTasks()
        checkBackgroundRefreshStatus()
        setupAppLifecycleObservers()
    }
    
    // MARK: - Public API
    
    /// Initialize background task system
    public func initialize() async {
        await requestNotificationPermissions()
        registerBackgroundTasks()
        await schedulePendingTasks()
        
        print("BackgroundTaskManager initialized")
    }
    
    /// Force sync all data in background
    public func performImmediateSync() async {
        syncStatus = .syncing
        
        await performanceMonitor.trackOperation(
            name: "BackgroundTaskManager.immediateSync",
            category: .general
        ) {
            await executeBackgroundSync()
        }
        
        syncStatus = .completed
    }
    
    /// Schedule booking reminder
    public func scheduleBookingReminder(
        for bookingId: String,
        className: String,
        reminderTime: Date
    ) async {
        let request = UNNotificationRequest(
            identifier: "booking-\(bookingId)",
            content: createBookingReminderContent(className: className),
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: reminderTime.timeIntervalSinceNow,
                repeats: false
            )
        )
        
        do {
            try await notificationCenter.add(request)
            await updatePendingNotificationCount()
            print("Scheduled booking reminder for \(className) at \(reminderTime)")
        } catch {
            print("Failed to schedule booking reminder: \(error)")
        }
    }
    
    /// Schedule class update notification
    public func scheduleClassUpdateNotification(
        for classId: String,
        updateType: ClassUpdateType,
        details: String
    ) async {
        let request = UNNotificationRequest(
            identifier: "class-update-\(classId)",
            content: createClassUpdateContent(type: updateType, details: details),
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5.0, repeats: false)
        )
        
        do {
            try await notificationCenter.add(request)
            await updatePendingNotificationCount()
            print("Scheduled class update notification: \(updateType)")
        } catch {
            print("Failed to schedule class update notification: \(error)")
        }
    }
    
    /// Cancel scheduled notification
    public func cancelNotification(identifier: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        await updatePendingNotificationCount()
    }
    
    /// Get background task statistics
    public func getBackgroundTaskStatistics() -> BackgroundTaskStatistics {
        return BackgroundTaskStatistics(
            isEnabled: isBackgroundRefreshEnabled,
            lastUpdate: lastBackgroundUpdate,
            registeredTasks: backgroundTasksRegistered,
            syncStatus: syncStatus,
            pendingNotifications: pendingNotifications
        )
    }
    
    // MARK: - Private Implementation
    
    private func setupBackgroundTasks() {
        // Register background task handlers
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifiers.dataSync,
            using: nil
        ) { [weak self] task in
            self?.handleDataSyncTask(task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifiers.bookingReminders,
            using: nil
        ) { [weak self] task in
            self?.handleBookingRemindersTask(task as! BGProcessingTask)
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifiers.classUpdates,
            using: nil
        ) { [weak self] task in
            self?.handleClassUpdatesTask(task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifiers.locationSync,
            using: nil
        ) { [weak self] task in
            self?.handleLocationSyncTask(task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifiers.performanceCleanup,
            using: nil
        ) { [weak self] task in
            self?.handlePerformanceCleanupTask(task as! BGProcessingTask)
        }
    }
    
    private func registerBackgroundTasks() {
        backgroundTasksRegistered = [
            TaskIdentifiers.dataSync,
            TaskIdentifiers.bookingReminders,
            TaskIdentifiers.classUpdates,
            TaskIdentifiers.locationSync,
            TaskIdentifiers.performanceCleanup
        ]
        
        print("Registered \(backgroundTasksRegistered.count) background tasks")
    }
    
    private func checkBackgroundRefreshStatus() {
        isBackgroundRefreshEnabled = UIApplication.shared.backgroundRefreshStatus == .available
    }
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(backgroundRefreshStatusChanged),
            name: UIApplication.backgroundRefreshStatusDidChangeNotification,
            object: nil
        )
    }
    
    // MARK: - Background Task Handlers
    
    private func handleDataSyncTask(_ task: BGAppRefreshTask) {
        Task { @MainActor in
            syncStatus = .syncing
            
            let backgroundTask = await beginBackgroundTask(name: "DataSync")
            
            let syncTask = Task {
                await executeBackgroundSync()
            }
            
            task.expirationHandler = {
                syncTask.cancel()
                self.endBackgroundTask(backgroundTask)
                Task { @MainActor in
                    self.syncStatus = .failed
                }
            }
            
            do {
                _ = try await syncTask.value
                task.setTaskCompleted(success: true)
                syncStatus = .completed
                lastBackgroundUpdate = Date()
            } catch {
                task.setTaskCompleted(success: false)
                syncStatus = .failed
                print("Background data sync failed: \(error)")
            }
            
            await endBackgroundTask(backgroundTask)
            await scheduleNextDataSync()
        }
    }
    
    private func handleBookingRemindersTask(_ task: BGProcessingTask) {
        Task { @MainActor in
            let backgroundTask = await beginBackgroundTask(name: "BookingReminders")
            
            let reminderTask = Task {
                await bookingSyncManager.processBookingReminders()
            }
            
            task.expirationHandler = {
                reminderTask.cancel()
                self.endBackgroundTask(backgroundTask)
            }
            
            do {
                _ = try await reminderTask.value
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
                print("Booking reminders task failed: \(error)")
            }
            
            await endBackgroundTask(backgroundTask)
        }
    }
    
    private func handleClassUpdatesTask(_ task: BGAppRefreshTask) {
        Task { @MainActor in
            let backgroundTask = await beginBackgroundTask(name: "ClassUpdates")
            
            let updateTask = Task {
                await dataSyncManager.syncClassUpdates()
            }
            
            task.expirationHandler = {
                updateTask.cancel()
                self.endBackgroundTask(backgroundTask)
            }
            
            do {
                _ = try await updateTask.value
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
                print("Class updates task failed: \(error)")
            }
            
            await endBackgroundTask(backgroundTask)
        }
    }
    
    private func handleLocationSyncTask(_ task: BGAppRefreshTask) {
        Task { @MainActor in
            let backgroundTask = await beginBackgroundTask(name: "LocationSync")
            
            let locationTask = Task {
                await locationSyncManager.syncLocationData()
            }
            
            task.expirationHandler = {
                locationTask.cancel()
                self.endBackgroundTask(backgroundTask)
            }
            
            do {
                _ = try await locationTask.value
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
                print("Location sync task failed: \(error)")
            }
            
            await endBackgroundTask(backgroundTask)
        }
    }
    
    private func handlePerformanceCleanupTask(_ task: BGProcessingTask) {
        Task { @MainActor in
            let backgroundTask = await beginBackgroundTask(name: "PerformanceCleanup")
            
            let cleanupTask = Task {
                await performanceCleanupManager.performCleanup()
            }
            
            task.expirationHandler = {
                cleanupTask.cancel()
                self.endBackgroundTask(backgroundTask)
            }
            
            do {
                _ = try await cleanupTask.value
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
                print("Performance cleanup task failed: \(error)")
            }
            
            await endBackgroundTask(backgroundTask)
        }
    }
    
    // MARK: - Background Task Management
    
    private func beginBackgroundTask(name: String) async -> UIBackgroundTaskIdentifier {
        return UIApplication.shared.beginBackgroundTask(withName: name) {
            print("Background task \(name) expired")
        }
    }
    
    private func endBackgroundTask(_ taskId: UIBackgroundTaskIdentifier) async {
        if taskId != .invalid {
            UIApplication.shared.endBackgroundTask(taskId)
        }
    }
    
    private func executeBackgroundSync() async {
        // Parallel execution of sync operations
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.dataSyncManager.syncBookings()
            }
            
            group.addTask {
                await self.dataSyncManager.syncClassUpdates()
            }
            
            group.addTask {
                await self.dataSyncManager.syncUserProfile()
            }
            
            group.addTask {
                await self.locationSyncManager.syncLocationData()
            }
        }
        
        print("Background sync completed")
    }
    
    // MARK: - Task Scheduling
    
    private func schedulePendingTasks() async {
        await scheduleNextDataSync()
        await scheduleBookingRemindersCheck()
        await schedulePerformanceCleanup()
    }
    
    private func scheduleNextDataSync() async {
        let request = BGAppRefreshTaskRequest(identifier: TaskIdentifiers.dataSync)
        request.earliestBeginDate = Date(timeIntervalSinceNow: syncInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled next data sync for \(request.earliestBeginDate!)")
        } catch {
            print("Failed to schedule data sync: \(error)")
        }
    }
    
    private func scheduleBookingRemindersCheck() async {
        let request = BGProcessingTaskRequest(identifier: TaskIdentifiers.bookingReminders)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        request.requiresNetworkConnectivity = true
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled booking reminders check")
        } catch {
            print("Failed to schedule booking reminders check: \(error)")
        }
    }
    
    private func schedulePerformanceCleanup() async {
        let request = BGProcessingTaskRequest(identifier: TaskIdentifiers.performanceCleanup)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24 hours
        request.requiresExternalPower = true
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled performance cleanup")
        } catch {
            print("Failed to schedule performance cleanup: \(error)")
        }
    }
    
    // MARK: - Notification Management
    
    private func requestNotificationPermissions() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            
            if granted {
                print("Notification permissions granted")
            } else {
                print("Notification permissions denied")
            }
        } catch {
            print("Failed to request notification permissions: \(error)")
        }
    }
    
    private func createBookingReminderContent(className: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Class Reminder"
        content.body = "Your \(className) class starts in 30 minutes"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "BOOKING_REMINDER"
        
        return content
    }
    
    private func createClassUpdateContent(type: ClassUpdateType, details: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = details
        content.sound = .default
        content.categoryIdentifier = "CLASS_UPDATE"
        
        return content
    }
    
    private func updatePendingNotificationCount() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        pendingNotifications = requests.count
    }
    
    // MARK: - App Lifecycle Handlers
    
    @objc private func appDidEnterBackground() {
        Task { @MainActor in
            await schedulePendingTasks()
            print("App entered background, scheduled pending tasks")
        }
    }
    
    @objc private func appWillEnterForeground() {
        Task { @MainActor in
            checkBackgroundRefreshStatus()
            await updatePendingNotificationCount()
            print("App entering foreground, updated status")
        }
    }
    
    @objc private func backgroundRefreshStatusChanged() {
        checkBackgroundRefreshStatus()
        print("Background refresh status changed: \(isBackgroundRefreshEnabled)")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Sync Managers

private class DataSyncManager {
    private let networkCache = NetworkCache.shared
    
    func syncBookings() async {
        print("Syncing bookings in background...")
        // Implement booking sync logic
        
        // Example: Fetch latest bookings
        let endpoint = NetworkEndpoint(
            url: URL(string: "https://api.hobbyapp.com/bookings"),
            method: .GET,
            cacheDuration: 300 // 5 minutes cache
        )
        
        do {
            let _: [String: Any] = try await networkCache.request([String: Any].self, from: endpoint)
            print("Bookings synced successfully")
        } catch {
            print("Failed to sync bookings: \(error)")
        }
    }
    
    func syncClassUpdates() async {
        print("Syncing class updates in background...")
        // Implement class updates sync logic
        
        let endpoint = NetworkEndpoint(
            url: URL(string: "https://api.hobbyapp.com/classes/updates"),
            method: .GET,
            cacheDuration: 600 // 10 minutes cache
        )
        
        do {
            let _: [String: Any] = try await networkCache.request([String: Any].self, from: endpoint)
            print("Class updates synced successfully")
        } catch {
            print("Failed to sync class updates: \(error)")
        }
    }
    
    func syncUserProfile() async {
        print("Syncing user profile in background...")
        // Implement user profile sync logic
    }
}

private class BookingSyncManager {
    private let notificationCenter = UNUserNotificationCenter.current()
    
    func processBookingReminders() async {
        print("Processing booking reminders...")
        
        // Get upcoming bookings that need reminders
        let upcomingBookings = await getUpcomingBookings()
        
        for booking in upcomingBookings {
            if shouldSendReminder(for: booking) {
                await sendBookingReminder(for: booking)
            }
        }
    }
    
    private func getUpcomingBookings() async -> [BookingInfo] {
        // Fetch upcoming bookings from local storage or API
        return []
    }
    
    private func shouldSendReminder(for booking: BookingInfo) -> Bool {
        let now = Date()
        let reminderTime = booking.startTime.addingTimeInterval(-30 * 60) // 30 minutes before
        return now >= reminderTime && now < booking.startTime
    }
    
    private func sendBookingReminder(for booking: BookingInfo) async {
        let content = UNMutableNotificationContent()
        content.title = "Class Reminder"
        content.body = "Your \(booking.className) class starts in 30 minutes"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "booking-reminder-\(booking.id)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        do {
            try await notificationCenter.add(request)
            print("Sent booking reminder for \(booking.className)")
        } catch {
            print("Failed to send booking reminder: \(error)")
        }
    }
}

private class LocationSyncManager {
    func syncLocationData() async {
        print("Syncing location data in background...")
        // Implement location-based sync logic
        // Update nearby classes, venue information, etc.
    }
}

private class PerformanceCleanupManager {
    private let imageCache = ImageCache.shared
    private let networkCache = NetworkCache.shared
    private let performanceMonitor = PerformanceMonitor.shared
    
    func performCleanup() async {
        print("Performing background cleanup...")
        
        // Clean expired caches
        imageCache.clearExpiredCache()
        networkCache.clearCache()
        
        // Clear old performance data
        // performanceMonitor.clearOldData()
        
        // Clean temporary files
        await cleanTemporaryFiles()
        
        print("Background cleanup completed")
    }
    
    private func cleanTemporaryFiles() async {
        let tmpDirectory = FileManager.default.temporaryDirectory
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: tmpDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )
            
            let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
            
            for url in contents {
                let resourceValues = try url.resourceValues(forKeys: [.contentModificationDateKey])
                if let modificationDate = resourceValues.contentModificationDate,
                   modificationDate < cutoffDate {
                    try FileManager.default.removeItem(at: url)
                }
            }
        } catch {
            print("Failed to clean temporary files: \(error)")
        }
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

public enum ClassUpdateType {
    case cancelled
    case rescheduled
    case locationChanged
    case instructorChanged
    case newClass
    
    var title: String {
        switch self {
        case .cancelled:
            return "Class Cancelled"
        case .rescheduled:
            return "Class Rescheduled"
        case .locationChanged:
            return "Location Changed"
        case .instructorChanged:
            return "Instructor Changed"
        case .newClass:
            return "New Class Available"
        }
    }
}

public struct BackgroundTaskStatistics {
    public let isEnabled: Bool
    public let lastUpdate: Date?
    public let registeredTasks: [String]
    public let syncStatus: SyncStatus
    public let pendingNotifications: Int
    
    public var formattedLastUpdate: String {
        guard let lastUpdate = lastUpdate else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: lastUpdate, relativeTo: Date())
    }
}

private struct BookingInfo {
    let id: String
    let className: String
    let startTime: Date
    let venue: String
}

// MARK: - SwiftUI Integration

public struct BackgroundTaskDebugView: View {
    @StateObject private var backgroundTaskManager = BackgroundTaskManager.shared
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Background Tasks")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                statusRow("Background Refresh", backgroundTaskManager.isBackgroundRefreshEnabled ? "Enabled" : "Disabled")
                statusRow("Sync Status", backgroundTaskManager.syncStatus.rawValue)
                statusRow("Last Update", backgroundTaskManager.getBackgroundTaskStatistics().formattedLastUpdate)
                statusRow("Pending Notifications", "\(backgroundTaskManager.pendingNotifications)")
                statusRow("Registered Tasks", "\(backgroundTaskManager.backgroundTasksRegistered.count)")
            }
            
            HStack {
                Button("Force Sync") {
                    Task {
                        await backgroundTaskManager.performImmediateSync()
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Test Notification") {
                    Task {
                        await backgroundTaskManager.scheduleBookingReminder(
                            for: "test-booking",
                            className: "Test Class",
                            reminderTime: Date().addingTimeInterval(5)
                        )
                    }
                }
                .buttonStyle(.bordered)
            }
            
            if !backgroundTaskManager.backgroundTasksRegistered.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Registered Tasks:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(backgroundTaskManager.backgroundTasksRegistered, id: \.self) { task in
                        Text("• \(task.components(separatedBy: ".").last ?? task)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
    BackgroundTaskDebugView()
        .padding()
}

// MARK: - Color Extension

import SwiftUI

extension Color {
    static let gray = Color(.systemGray)
    static let blue = Color(.systemBlue)
    static let green = Color(.systemGreen)
    static let red = Color(.systemRed)
}