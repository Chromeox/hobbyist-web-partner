import Foundation
import UserNotifications
import UIKit
import Combine

class NotificationService: NSObject, NotificationServiceProtocol {
    private let notificationCenter = UNUserNotificationCenter.current()
    private var deviceToken: Data?
    private let supabase = SupabaseManager.shared.client
    private var notificationSettings = NotificationSettings()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        setupNotificationCategories()
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .providesAppNotificationSettings]
            )
            
            if granted {
                await UIApplication.shared.registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func checkNotificationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    func updateNotificationSettings(_ settings: NotificationSettings) async throws {
        self.notificationSettings = settings
        
        // Save to backend
        guard let supabase = supabase else { return }

        let request = UserPreferencesRequest(
            userId: try await getCurrentUserId(),
            notificationSettings: settings,
            updatedAt: Date()
        )

        _ = try await supabase
            .from("user_preferences")
            .update(request)
            .eq("user_id", value: request.userId)
            .execute()
    }
    
    // MARK: - Device Token Management
    
    func registerDeviceToken(_ token: Data) async throws {
        self.deviceToken = token
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        
        guard let supabase = supabase else { return }

        let request = DeviceTokenRequest(
            userId: try await getCurrentUserId(),
            token: tokenString,
            platform: "ios",
            updatedAt: Date()
        )

        // Register token with backend
        _ = try await supabase
            .from("device_tokens")
            .upsert(request)
            .execute()
    }
    
    func unregisterDeviceToken() async throws {
        guard let token = deviceToken else { return }
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        
        guard let supabase = supabase else { return }

        _ = try await supabase
            .from("device_tokens")
            .delete()
            .eq("token", value: tokenString)
            .execute()
    }
    
    // MARK: - Local Notifications
    
    func scheduleClassReminder(for booking: Booking) async throws {
        // Temporarily disabled for build compatibility
        return
        /*
        guard notificationSettings.pushNotifications else { return }

        let reminderTime = booking.startTime.addingTimeInterval(-3600) // 1 hour before
        
        // Check if reminder time is in the future
        guard reminderTime > Date() else { return }
        
        let content = UNMutableNotificationContent()
        let template = NotificationTemplate.classReminder(
            className: booking.className,
            time: booking.startDate,
            venue: booking.venueName
        )
        
        content.title = template.title
        content.body = template.body
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.classReminder.rawValue
        content.userInfo = [
            "booking_id": booking.id,
            "class_id": booking.classId,
            "type": "class_reminder"
        ]
        
        // Add location notification if available
        if let latitude = booking.latitude, let longitude = booking.longitude {
            content.userInfo["latitude"] = latitude
            content.userInfo["longitude"] = longitude
        }
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderTime
            ),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "class_reminder_\(booking.id)",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        */
    }
    
    func cancelClassReminder(bookingId: String) async throws {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["class_reminder_\(bookingId)"]
        )
    }
    
    func scheduleWorkoutReminder(at time: DateComponents) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Time for Your Workout! 💪"
        content.body = "Stay consistent with your fitness goals. Book a class now!"
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_REMINDER"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: time,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "daily_workout_reminder",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    // MARK: - Push Notification Handlers
    
    func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "VIEW_CLASS":
            if let classId = userInfo["class_id"] as? String {
                await navigateToClass(classId)
            }
            
        case "GET_DIRECTIONS":
            if let latitude = userInfo["latitude"] as? Double,
               let longitude = userInfo["longitude"] as? Double {
                await openMaps(latitude: latitude, longitude: longitude)
            }
            
        case "VIEW_BOOKING":
            if let bookingId = userInfo["booking_id"] as? String {
                await navigateToBooking(bookingId)
            }
            
        case "WRITE_REVIEW":
            if let classId = userInfo["class_id"] as? String {
                await navigateToReview(classId)
            }
            
        case "VIEW_OFFER":
            if let offerId = userInfo["offer_id"] as? String {
                await navigateToOffer(offerId)
            }
            
        case "USE_CREDITS", "BUY_MORE":
            await navigateToCredits()
            
        default:
            // Handle default tap action
            if let type = userInfo["type"] as? String {
                await handleNotificationType(type, userInfo: userInfo)
            }
        }
    }
    
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        // Process silent push notifications
        if let type = userInfo["type"] as? String {
            switch type {
            case "sync_data":
                // Trigger data sync
                return await syncData() ? .newData : .failed
                
            case "update_badge":
                if let badgeCount = userInfo["badge"] as? Int {
                    await updateBadgeCount(badgeCount)
                    return .newData
                }
                
            default:
                break
            }
        }
        
        return .noData
    }
    
    // MARK: - Notification Categories
    
    func setupNotificationCategories() {
        var categories = Set<UNNotificationCategory>()
        
        for category in NotificationCategory.allCases {
            let notificationCategory = UNNotificationCategory(
                identifier: category.rawValue,
                actions: category.actions,
                intentIdentifiers: [],
                options: []
            )
            categories.insert(notificationCategory)
        }
        
        notificationCenter.setNotificationCategories(categories)
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) async {
        if #available(iOS 16.0, *) {
            try? await UNUserNotificationCenter.current().setBadgeCount(count)
        } else {
            await MainActor.run {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        }
    }

    func clearBadge() async {
        if #available(iOS 16.0, *) {
            try? await UNUserNotificationCenter.current().setBadgeCount(0)
        } else {
            await MainActor.run {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
    
    // MARK: - In-App Notifications
    
    func showInAppNotification(_ notification: InAppNotification) {
        Task { @MainActor in
            NotificationBanner.show(notification)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() async throws -> String {
        guard let supabase = supabase else { throw NotificationError.notInitialized }
        
        let session = try await supabase.auth.session
        let userId = session.user.id.uuidString
        
        return userId
    }
    
    private func syncData() async -> Bool {
        // Implement data sync logic
        return true
    }
    
    private func navigateToClass(_ classId: String) async {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .navigateToClass,
                object: nil,
                userInfo: ["classId": classId]
            )
        }
    }
    
    private func navigateToBooking(_ bookingId: String) async {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .navigateToBooking,
                object: nil,
                userInfo: ["bookingId": bookingId]
            )
        }
    }
    
    private func navigateToReview(_ classId: String) async {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .navigateToReview,
                object: nil,
                userInfo: ["classId": classId]
            )
        }
    }
    
    private func navigateToOffer(_ offerId: String) async {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .navigateToOffer,
                object: nil,
                userInfo: ["offerId": offerId]
            )
        }
    }
    
    private func navigateToCredits() async {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .navigateToCredits,
                object: nil,
                userInfo: nil
            )
        }
    }
    
    private func openMaps(latitude: Double, longitude: Double) async {
        await MainActor.run {
            let coordinate = "\(latitude),\(longitude)"
            if let url = URL(string: "maps://maps.apple.com/?q=\(coordinate)") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func handleNotificationType(_ type: String, userInfo: [AnyHashable: Any]) async {
        // Handle different notification types
        switch type {
        case "class_reminder":
            if let classId = userInfo["class_id"] as? String {
                await navigateToClass(classId)
            }
        case "booking_confirmation":
            if let bookingId = userInfo["booking_id"] as? String {
                await navigateToBooking(bookingId)
            }
        default:
            break
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task {
            await handleNotificationResponse(response)
            completionHandler()
        }
    }
}

// MARK: - Supporting Types

enum NotificationError: LocalizedError {
    case notInitialized
    case userNotAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Notification service not initialized"
        case .userNotAuthenticated:
            return "User must be authenticated"
        }
    }
}

// MARK: - Notification Extensions

extension NotificationCategory: CaseIterable {
    static var allCases: [NotificationCategory] {
        return [.classReminder, .bookingConfirmation, .paymentSuccess, .reviewRequest, .promotionalOffer, .creditExpiry]
    }
}

extension Notification.Name {
    static let navigateToClass = Notification.Name("navigateToClass")
    static let navigateToBooking = Notification.Name("navigateToBooking")
    static let navigateToReview = Notification.Name("navigateToReview")
    static let navigateToOffer = Notification.Name("navigateToOffer")
    static let navigateToCredits = Notification.Name("navigateToCredits")
}

// MARK: - In-App Notification Banner

@MainActor
class NotificationBanner {
    static func show(_ notification: InAppNotification) {
        // Implementation would show a banner view
        // This is a simplified version
        print("📬 In-App Notification: \(notification.title) - \(notification.message)")
    }
}

// MARK: - Device Token Request Type

struct DeviceTokenRequest: Codable {
    let userId: String
    let token: String
    let platform: String
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case token
        case platform
        case updatedAt = "updated_at"
    }
}

// Extension for Booking to include location
extension Booking {
    var latitude: Double? { nil } // Would be fetched from venue
    var longitude: Double? { nil } // Would be fetched from venue
}