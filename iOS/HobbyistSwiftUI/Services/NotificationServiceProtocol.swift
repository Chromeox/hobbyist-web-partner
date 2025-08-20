import Foundation
import UserNotifications
import UIKit

protocol NotificationServiceProtocol {
    // Permission Management
    func requestNotificationPermission() async -> Bool
    func checkNotificationStatus() async -> UNAuthorizationStatus
    func updateNotificationSettings(_ settings: NotificationSettings) async throws
    
    // Device Token Management
    func registerDeviceToken(_ token: Data) async throws
    func unregisterDeviceToken() async throws
    
    // Local Notifications
    func scheduleClassReminder(for booking: Booking) async throws
    func cancelClassReminder(bookingId: String) async throws
    func scheduleWorkoutReminder(at time: DateComponents) async throws
    
    // Push Notification Handlers
    func handleNotificationResponse(_ response: UNNotificationResponse) async
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult
    
    // Notification Categories
    func setupNotificationCategories()
    
    // Badge Management
    func updateBadgeCount(_ count: Int) async
    func clearBadge() async
    
    // In-App Notifications
    func showInAppNotification(_ notification: InAppNotification)
}

// MARK: - Notification Models

struct NotificationSettings: Codable {
    var classReminders: Bool = true
    var bookingConfirmations: Bool = true
    var promotionalOffers: Bool = false
    var newClassAlerts: Bool = true
    var instructorUpdates: Bool = true
    var paymentNotifications: Bool = true
    var reviewReminders: Bool = true
    var creditExpiryAlerts: Bool = true
    
    var reminderTimeBeforeClass: TimeInterval = 3600 // 1 hour default
    var dailyWorkoutReminder: DateComponents?
}

struct InAppNotification {
    let id: String = UUID().uuidString
    let title: String
    let message: String
    let type: NotificationType
    let action: NotificationAction?
    let imageURL: String?
    
    enum NotificationType {
        case success
        case warning
        case error
        case info
        case promotion
    }
    
    struct NotificationAction {
        let title: String
        let handler: () -> Void
    }
}

// MARK: - Push Notification Payload

struct PushNotificationPayload: Codable {
    let aps: APSPayload
    let data: NotificationData?
    
    struct APSPayload: Codable {
        let alert: Alert
        let badge: Int?
        let sound: String?
        let category: String?
        
        struct Alert: Codable {
            let title: String
            let body: String
            let subtitle: String?
        }
    }
    
    struct NotificationData: Codable {
        let type: String
        let id: String?
        let action: String?
        let metadata: [String: String]?
    }
}

// MARK: - Notification Categories

enum NotificationCategory: String {
    case classReminder = "CLASS_REMINDER"
    case bookingConfirmation = "BOOKING_CONFIRMATION"
    case paymentSuccess = "PAYMENT_SUCCESS"
    case reviewRequest = "REVIEW_REQUEST"
    case promotionalOffer = "PROMOTIONAL_OFFER"
    case creditExpiry = "CREDIT_EXPIRY"
    
    var actions: [UNNotificationAction] {
        switch self {
        case .classReminder:
            return [
                UNNotificationAction(
                    identifier: "VIEW_CLASS",
                    title: "View Class",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "GET_DIRECTIONS",
                    title: "Get Directions",
                    options: .foreground
                )
            ]
            
        case .bookingConfirmation:
            return [
                UNNotificationAction(
                    identifier: "VIEW_BOOKING",
                    title: "View Details",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "ADD_TO_CALENDAR",
                    title: "Add to Calendar",
                    options: []
                )
            ]
            
        case .reviewRequest:
            return [
                UNNotificationAction(
                    identifier: "WRITE_REVIEW",
                    title: "Write Review",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "REMIND_LATER",
                    title: "Later",
                    options: []
                )
            ]
            
        case .promotionalOffer:
            return [
                UNNotificationAction(
                    identifier: "VIEW_OFFER",
                    title: "View Offer",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: "Dismiss",
                    options: .destructive
                )
            ]
            
        case .creditExpiry:
            return [
                UNNotificationAction(
                    identifier: "USE_CREDITS",
                    title: "Book a Class",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "BUY_MORE",
                    title: "Buy More Credits",
                    options: .foreground
                )
            ]
            
        default:
            return []
        }
    }
}

// MARK: - Notification Templates

struct NotificationTemplate {
    static func classReminder(className: String, time: Date, venue: String) -> (title: String, body: String) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: time)
        
        return (
            title: "Class Starting Soon! ⏰",
            body: "\(className) starts at \(timeString) at \(venue). Don't forget to bring your gear!"
        )
    }
    
    static func bookingConfirmation(className: String, date: Date) -> (title: String, body: String) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let dateString = formatter.string(from: date)
        
        return (
            title: "Booking Confirmed! ✅",
            body: "You're all set for \(className) on \(dateString)"
        )
    }
    
    static func paymentSuccess(amount: Double) -> (title: String, body: String) {
        return (
            title: "Payment Successful 💳",
            body: String(format: "Your payment of $%.2f has been processed successfully", amount)
        )
    }
    
    static func creditPurchase(credits: Int) -> (title: String, body: String) {
        return (
            title: "Credits Added! 🎉",
            body: "\(credits) credits have been added to your account"
        )
    }
    
    static func reviewRequest(className: String) -> (title: String, body: String) {
        return (
            title: "How was \(className)? ⭐",
            body: "Share your experience and help others discover great classes"
        )
    }
    
    static func creditExpiry(credits: Int, days: Int) -> (title: String, body: String) {
        return (
            title: "Credits Expiring Soon ⚠️",
            body: "\(credits) credits will expire in \(days) days. Book a class today!"
        )
    }
    
    static func newClassAlert(className: String, instructor: String) -> (title: String, body: String) {
        return (
            title: "New Class Available! 🆕",
            body: "\(className) with \(instructor) is now available for booking"
        )
    }
}