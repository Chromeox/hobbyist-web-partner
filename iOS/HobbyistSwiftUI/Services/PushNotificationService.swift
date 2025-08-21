import Foundation
import UserNotifications
import UIKit
import Combine

// MARK: - Push Notification Service
@MainActor
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    // Published states
    @Published var isAuthorized = false
    @Published var deviceToken: String?
    @Published var pendingNotification: NotificationPayload?
    
    // Configuration
    private let supabaseClient = SupabaseManager.shared.client
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .badge, .sound, .providesAppNotificationSettings]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
                await setupNotificationCategories()
            }
            
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func registerForRemoteNotifications() async {
        await UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Device Token Management
    
    func updateDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        
        Task {
            await saveDeviceTokenToSupabase(token)
        }
    }
    
    private func saveDeviceTokenToSupabase(_ token: String) async {
        guard let userId = try? await supabaseClient.auth.session.user.id else { return }
        
        do {
            _ = try await supabaseClient.database
                .from("device_tokens")
                .upsert([
                    "user_id": userId.uuidString,
                    "token": token,
                    "platform": "ios",
                    "updated_at": Date().ISO8601Format()
                ])
                .execute()
        } catch {
            print("Failed to save device token: \(error)")
        }
    }
    
    func removeDeviceToken() async {
        guard let token = deviceToken,
              let userId = try? await supabaseClient.auth.session.user.id else { return }
        
        do {
            _ = try await supabaseClient.database
                .from("device_tokens")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("token", value: token)
                .execute()
        } catch {
            print("Failed to remove device token: \(error)")
        }
    }
    
    // MARK: - Notification Categories
    
    private func setupNotificationCategories() async {
        // Class Reminder Category
        let attendAction = UNNotificationAction(
            identifier: "ATTEND_ACTION",
            title: "I'll be there",
            options: [.foreground]
        )
        
        let cancelAction = UNNotificationAction(
            identifier: "CANCEL_ACTION",
            title: "Can't make it",
            options: [.destructive]
        )
        
        let classReminderCategory = UNNotificationCategory(
            identifier: "CLASS_REMINDER",
            actions: [attendAction, cancelAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Booking Confirmation Category
        let viewBookingAction = UNNotificationAction(
            identifier: "VIEW_BOOKING",
            title: "View Details",
            options: [.foreground]
        )
        
        let addToCalendarAction = UNNotificationAction(
            identifier: "ADD_TO_CALENDAR",
            title: "Add to Calendar",
            options: []
        )
        
        let bookingCategory = UNNotificationCategory(
            identifier: "BOOKING_CONFIRMATION",
            actions: [viewBookingAction, addToCalendarAction],
            intentIdentifiers: [],
            options: []
        )
        
        // New Class Alert Category
        let viewClassAction = UNNotificationAction(
            identifier: "VIEW_CLASS",
            title: "View Class",
            options: [.foreground]
        )
        
        let bookNowAction = UNNotificationAction(
            identifier: "BOOK_NOW",
            title: "Book Now",
            options: [.foreground]
        )
        
        let newClassCategory = UNNotificationCategory(
            identifier: "NEW_CLASS",
            actions: [viewClassAction, bookNowAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Set categories
        UNUserNotificationCenter.current().setNotificationCategories([
            classReminderCategory,
            bookingCategory,
            newClassCategory
        ])
    }
    
    // MARK: - Schedule Local Notifications
    
    func scheduleClassReminder(
        classId: String,
        className: String,
        classTime: Date,
        reminderTime: TimeInterval = -3600 // 1 hour before
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Class Reminder"
        content.body = "\(className) starts in 1 hour. Don't forget your gear!"
        content.sound = .default
        content.categoryIdentifier = "CLASS_REMINDER"
        content.userInfo = [
            "class_id": classId,
            "type": "class_reminder"
        ]
        
        // Add haptic feedback on Apple Watch
        content.interruptionLevel = .timeSensitive
        
        let triggerDate = classTime.addingTimeInterval(reminderTime)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            ),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "class_reminder_\(classId)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled reminder for class \(classId)")
        } catch {
            print("Failed to schedule reminder: \(error)")
        }
    }
    
    func scheduleBookingConfirmation(
        bookingId: String,
        className: String,
        confirmationCode: String
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Booking Confirmed! ✅"
        content.body = "You're all set for \(className). Confirmation: \(confirmationCode)"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("success.m4a"))
        content.categoryIdentifier = "BOOKING_CONFIRMATION"
        content.userInfo = [
            "booking_id": bookingId,
            "type": "booking_confirmation"
        ]
        
        // Immediate notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "booking_\(bookingId)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            
            // Trigger haptic feedback
            await MainActor.run {
                HapticFeedbackService.shared.playBookingSuccess()
            }
        } catch {
            print("Failed to schedule booking confirmation: \(error)")
        }
    }
    
    // MARK: - Handle Remote Notifications
    
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async {
        guard let type = userInfo["type"] as? String else { return }
        
        let payload = NotificationPayload(from: userInfo)
        
        await MainActor.run {
            self.pendingNotification = payload
        }
        
        switch type {
        case "booking_confirmation":
            await handleBookingConfirmation(payload)
            
        case "class_reminder":
            await handleClassReminder(payload)
            
        case "class_cancelled":
            await handleClassCancellation(payload)
            
        case "new_class_alert":
            await handleNewClassAlert(payload)
            
        case "promotional_offer":
            await handlePromotionalOffer(payload)
            
        default:
            print("Unknown notification type: \(type)")
        }
    }
    
    private func handleBookingConfirmation(_ payload: NotificationPayload) async {
        // Navigate to booking details
        if let bookingId = payload.bookingId {
            NotificationCenter.default.post(
                name: .navigateToBooking,
                object: nil,
                userInfo: ["booking_id": bookingId]
            )
        }
        
        // Update local state
        await SupabaseDataService.shared.fetchUserBookings()
    }
    
    private func handleClassReminder(_ payload: NotificationPayload) async {
        // Show in-app reminder
        if let classId = payload.classId {
            NotificationCenter.default.post(
                name: .showClassReminder,
                object: nil,
                userInfo: ["class_id": classId]
            )
        }
    }
    
    private func handleClassCancellation(_ payload: NotificationPayload) async {
        // Show cancellation alert
        if let classId = payload.classId {
            NotificationCenter.default.post(
                name: .classCancelled,
                object: nil,
                userInfo: ["class_id": classId]
            )
            
            // Refresh bookings
            await SupabaseDataService.shared.fetchUserBookings()
        }
    }
    
    private func handleNewClassAlert(_ payload: NotificationPayload) async {
        // Navigate to class detail
        if let classId = payload.classId {
            NotificationCenter.default.post(
                name: .navigateToClass,
                object: nil,
                userInfo: ["class_id": classId]
            )
        }
    }
    
    private func handlePromotionalOffer(_ payload: NotificationPayload) async {
        // Show promotional banner
        if let promoCode = payload.promoCode {
            NotificationCenter.default.post(
                name: .showPromotion,
                object: nil,
                userInfo: ["promo_code": promoCode]
            )
        }
    }
    
    // MARK: - Notification Preferences
    
    func updateNotificationPreferences(
        classReminders: Bool,
        newClassAlerts: Bool,
        promotionalOffers: Bool
    ) async {
        guard let userId = try? await supabaseClient.auth.session.user.id else { return }
        
        do {
            _ = try await supabaseClient.database
                .from("notification_preferences")
                .upsert([
                    "user_id": userId.uuidString,
                    "class_reminders": classReminders,
                    "new_class_alerts": newClassAlerts,
                    "promotional_offers": promotionalOffers,
                    "updated_at": Date().ISO8601Format()
                ])
                .execute()
        } catch {
            print("Failed to update notification preferences: \(error)")
        }
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) async {
        await UIApplication.shared.setApplicationIconBadgeNumber(count)
    }
    
    func clearBadge() async {
        await updateBadgeCount(0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .badge, .sound]
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "ATTEND_ACTION":
            // Mark attendance
            if let classId = userInfo["class_id"] as? String {
                await markAttendance(for: classId)
            }
            
        case "CANCEL_ACTION":
            // Cancel booking
            if let classId = userInfo["class_id"] as? String {
                await cancelBooking(for: classId)
            }
            
        case "VIEW_BOOKING", "VIEW_CLASS":
            // Navigate to details
            await handleRemoteNotification(userInfo)
            
        case "BOOK_NOW":
            // Navigate to booking flow
            if let classId = userInfo["class_id"] as? String {
                NotificationCenter.default.post(
                    name: .startBookingFlow,
                    object: nil,
                    userInfo: ["class_id": classId]
                )
            }
            
        case "ADD_TO_CALENDAR":
            // Add to calendar
            if let bookingId = userInfo["booking_id"] as? String {
                await addToCalendar(bookingId: bookingId)
            }
            
        default:
            // Default tap action
            await handleRemoteNotification(userInfo)
        }
    }
    
    private func markAttendance(for classId: String) async {
        // Update attendance status
        print("Marking attendance for class \(classId)")
    }
    
    private func cancelBooking(for classId: String) async {
        // Cancel the booking
        print("Cancelling booking for class \(classId)")
    }
    
    private func addToCalendar(bookingId: String) async {
        // Add to calendar implementation
        print("Adding booking \(bookingId) to calendar")
    }
}

// MARK: - Models

struct NotificationPayload {
    let type: String
    let title: String?
    let body: String?
    let classId: String?
    let bookingId: String?
    let promoCode: String?
    let deepLink: String?
    
    init(from userInfo: [AnyHashable: Any]) {
        self.type = userInfo["type"] as? String ?? ""
        self.title = userInfo["title"] as? String
        self.body = userInfo["body"] as? String
        self.classId = userInfo["class_id"] as? String
        self.bookingId = userInfo["booking_id"] as? String
        self.promoCode = userInfo["promo_code"] as? String
        self.deepLink = userInfo["deep_link"] as? String
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToBooking = Notification.Name("navigateToBooking")
    static let navigateToClass = Notification.Name("navigateToClass")
    static let showClassReminder = Notification.Name("showClassReminder")
    static let classCancelled = Notification.Name("classCancelled")
    static let showPromotion = Notification.Name("showPromotion")
    static let startBookingFlow = Notification.Name("startBookingFlow")
}