import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var filteredNotifications: [AppNotification] {
        notifications // Filter will be applied by the view based on selected filter
    }
    
    var groupedNotifications: [NotificationGroup] {
        let grouped = Dictionary(grouping: filteredNotifications) { notification in
            Calendar.current.startOfDay(for: notification.createdAt)
        }
        
        return grouped.map { date, notifications in
            NotificationGroup(
                date: date,
                notifications: notifications.sorted { $0.createdAt > $1.createdAt },
                unreadCount: notifications.filter { !$0.isRead }.count
            )
        }.sorted { $0.date > $1.date }
    }
    
    func loadNotifications() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate loading delay
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            // Generate sample notifications
            notifications = generateSampleNotifications()
            
        } catch {
            errorMessage = "Failed to load notifications"
        }
        
        isLoading = false
    }
    
    func notificationCount(for filter: NotificationFilter) -> Int {
        switch filter {
        case .all:
            return notifications.count
        case .classReminders:
            return notifications.filter { $0.type == .classReminder }.count
        case .bookings:
            return notifications.filter { $0.type == .bookingConfirmation }.count
        case .messages:
            return notifications.filter { $0.type == .instructorMessage }.count
        case .promotions:
            return notifications.filter { $0.type == .promotion }.count
        case .updates:
            return notifications.filter { $0.type == .systemUpdate }.count
        }
    }
    
    func hasUnreadNotifications(for filter: NotificationFilter) -> Bool {
        let filteredNotifications: [AppNotification]
        
        switch filter {
        case .all:
            filteredNotifications = notifications
        case .classReminders:
            filteredNotifications = notifications.filter { $0.type == .classReminder }
        case .bookings:
            filteredNotifications = notifications.filter { $0.type == .bookingConfirmation }
        case .messages:
            filteredNotifications = notifications.filter { $0.type == .instructorMessage }
        case .promotions:
            filteredNotifications = notifications.filter { $0.type == .promotion }
        case .updates:
            filteredNotifications = notifications.filter { $0.type == .systemUpdate }
        }
        
        return filteredNotifications.contains { !$0.isRead }
    }
    
    func markAsRead(_ notification: AppNotification) async {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        
        // Update locally first
        notifications[index] = AppNotification(
            id: notification.id,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            createdAt: notification.createdAt,
            isRead: true,
            actionText: notification.actionText,
            data: notification.data
        )
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
    
    func markAllAsRead() async {
        // Update all notifications locally
        notifications = notifications.map { notification in
            AppNotification(
                id: notification.id,
                type: notification.type,
                title: notification.title,
                message: notification.message,
                createdAt: notification.createdAt,
                isRead: true,
                actionText: notification.actionText,
                data: notification.data
            )
        }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    func deleteNotification(_ notification: AppNotification) async {
        // Remove locally first
        notifications.removeAll { $0.id == notification.id }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
    
    func clearAll() async {
        // Clear all notifications locally
        notifications.removeAll()
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
    }
    
    private func generateSampleNotifications() -> [AppNotification] {
        let currentDate = Date()
        
        return [
            // Recent notifications (today)
            AppNotification(
                id: UUID().uuidString,
                type: .classReminder,
                title: "Class Starting Soon",
                message: "Your Pottery Basics class with Sarah Chen starts in 30 minutes at Creative Arts Studio.",
                createdAt: currentDate.addingTimeInterval(-1800), // 30 minutes ago
                isRead: false,
                actionText: "View Class Details",
                data: [
                    "className": "Pottery Basics",
                    "instructorName": "Sarah Chen",
                    "startTime": "2:00 PM",
                    "venue": "Creative Arts Studio"
                ]
            ),
            
            AppNotification(
                id: UUID().uuidString,
                type: .bookingConfirmation,
                title: "Booking Confirmed",
                message: "Your booking for Watercolor Painting has been confirmed for tomorrow at 10:00 AM.",
                createdAt: currentDate.addingTimeInterval(-3600), // 1 hour ago
                isRead: false,
                actionText: "View Booking",
                data: [
                    "className": "Watercolor Painting",
                    "venue": "Downtown Art Center",
                    "date": "Tomorrow",
                    "time": "10:00 AM"
                ]
            ),
            
            AppNotification(
                id: UUID().uuidString,
                type: .instructorMessage,
                title: "Message from Michael Rodriguez",
                message: "Great work in today's photography class! Don't forget to practice the composition techniques we covered.",
                createdAt: currentDate.addingTimeInterval(-7200), // 2 hours ago
                isRead: true,
                actionText: "Reply",
                data: [
                    "instructorName": "Michael Rodriguez",
                    "className": "Photography Basics"
                ]
            ),
            
            // Yesterday's notifications
            AppNotification(
                id: UUID().uuidString,
                type: .newClass,
                title: "New Class Available",
                message: "Digital Art Fundamentals with Emma Thompson is now available for booking. Limited spots remaining!",
                createdAt: currentDate.addingTimeInterval(-86400), // Yesterday
                isRead: true,
                actionText: "Book Now",
                data: [
                    "className": "Digital Art Fundamentals",
                    "instructorName": "Emma Thompson"
                ]
            ),
            
            AppNotification(
                id: UUID().uuidString,
                type: .promotion,
                title: "Special Offer - 20% Off",
                message: "Get 20% off your next class booking! Use code HOBBY20 at checkout. Valid until Friday.",
                createdAt: currentDate.addingTimeInterval(-90000), // Yesterday
                isRead: false,
                actionText: "Browse Classes",
                data: [
                    "promoCode": "HOBBY20",
                    "discount": "20%",
                    "expiryDate": "Friday"
                ]
            ),
            
            // Older notifications (2 days ago)
            AppNotification(
                id: UUID().uuidString,
                type: .classReminder,
                title: "Class Completed",
                message: "Thank you for attending Italian Cooking Masterclass! We'd love your feedback.",
                createdAt: currentDate.addingTimeInterval(-172800), // 2 days ago
                isRead: true,
                actionText: "Leave Review",
                data: [
                    "className": "Italian Cooking Masterclass",
                    "instructorName": "Maria Rossi"
                ]
            ),
            
            AppNotification(
                id: UUID().uuidString,
                type: .systemUpdate,
                title: "App Update Available",
                message: "Version 2.1.0 is now available with improved booking flow and new features.",
                createdAt: currentDate.addingTimeInterval(-200000), // 2+ days ago
                isRead: true,
                actionText: "Update Now",
                data: [
                    "version": "2.1.0",
                    "features": ["Improved booking", "New search filters", "Bug fixes"]
                ]
            ),
            
            // Week-old notifications
            AppNotification(
                id: UUID().uuidString,
                type: .bookingConfirmation,
                title: "Payment Processed",
                message: "Your payment of $75.00 for Woodworking Fundamentals has been processed successfully.",
                createdAt: currentDate.addingTimeInterval(-604800), // 1 week ago
                isRead: true,
                actionText: "View Receipt",
                data: [
                    "amount": "$75.00",
                    "className": "Woodworking Fundamentals",
                    "paymentMethod": "Credit Card ending in 4242"
                ]
            ),
            
            AppNotification(
                id: UUID().uuidString,
                type: .instructorMessage,
                title: "Welcome Message",
                message: "Welcome to HobbyApp! We're excited to help you discover new creative skills. Check out our featured classes to get started.",
                createdAt: currentDate.addingTimeInterval(-1209600), // 2 weeks ago
                isRead: true,
                actionText: "Browse Classes",
                data: [:]
            )
        ]
    }
}

// MARK: - Supporting Models

struct AppNotification: Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String?
    let createdAt: Date
    let isRead: Bool
    let actionText: String?
    let data: [String: Any]?
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

enum NotificationType: String, CaseIterable {
    case classReminder = "class_reminder"
    case bookingConfirmation = "booking_confirmation"
    case instructorMessage = "instructor_message"
    case newClass = "new_class"
    case promotion = "promotion"
    case systemUpdate = "system_update"
    
    var displayName: String {
        switch self {
        case .classReminder:
            return "Class Reminder"
        case .bookingConfirmation:
            return "Booking"
        case .instructorMessage:
            return "Message"
        case .newClass:
            return "New Class"
        case .promotion:
            return "Promotion"
        case .systemUpdate:
            return "Update"
        }
    }
    
    var iconName: String {
        switch self {
        case .classReminder:
            return "bell.fill"
        case .bookingConfirmation:
            return "checkmark.circle.fill"
        case .instructorMessage:
            return "message.fill"
        case .newClass:
            return "plus.circle.fill"
        case .promotion:
            return "tag.fill"
        case .systemUpdate:
            return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .classReminder:
            return .orange
        case .bookingConfirmation:
            return .green
        case .instructorMessage:
            return .blue
        case .newClass:
            return .purple
        case .promotion:
            return .pink
        case .systemUpdate:
            return .gray
        }
    }
}

enum NotificationFilter: String, CaseIterable {
    case all = "All"
    case classReminders = "Reminders"
    case bookings = "Bookings"
    case messages = "Messages"
    case promotions = "Promotions"
    case updates = "Updates"
    
    var displayName: String {
        return rawValue
    }
}

struct NotificationGroup {
    let date: Date
    let notifications: [AppNotification]
    let unreadCount: Int
    
    var displayDate: String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// NotificationSettings moved to Models/NotificationSettings.swift