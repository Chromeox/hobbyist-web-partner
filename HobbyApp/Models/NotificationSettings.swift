import Foundation

/// User notification preferences
struct NotificationSettings {
    var classReminders = true
    var bookingConfirmations = true
    var instructorMessages = true
    var newClasses = true
    var promotions = false
    var systemUpdates = true
    var reminderTiming = 30 // minutes
    var quietHours = true
    var pushNotifications = true
    var emailNotifications = false
    var smsNotifications = false
}

// MARK: - Achievement

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let earnedDate: Date?
    let progress: Double // 0.0 to 1.0
    let isUnlocked: Bool
    
    var progressPercentage: Int {
        return Int(progress * 100)
    }
}
