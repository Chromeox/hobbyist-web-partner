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
