import Foundation
import WatchConnectivity
import Combine

// MARK: - Watch Connectivity Service Protocol
/// Enterprise-grade protocol for iPhone-Watch communication with 2025 standards
protocol WatchConnectivityServiceProtocol {
    // MARK: - Connection Management
    var isWatchAppInstalled: Bool { get }
    var isWatchPaired: Bool { get }
    var isReachable: Bool { get }
    var connectionState: CurrentValueSubject<WatchConnectionState, Never> { get }
    
    // MARK: - Data Transfer Methods
    /// Send immediate message requiring response (for real-time updates)
    func sendMessage(_ message: [String: Any], replyHandler: ((Data) -> Void)?, errorHandler: ((Error) -> Void)?)
    
    /// Transfer user info for guaranteed delivery (for critical data)
    func transferUserInfo(_ userInfo: [String: Any])
    
    /// Update application context for latest state (for UI sync)
    func updateApplicationContext(_ context: [String: Any]) throws
    
    /// Transfer file with metadata (for large data)
    func transferFile(_ fileURL: URL, metadata: [String: Any]?)
    
    // MARK: - Booking Specific Methods
    func syncBookingStep(_ step: BookingViewModel.BookingStep)
    func syncBookingState(_ state: BookingViewModel.BookingState)
    func syncPaymentProgress(_ progress: Double)
    func sendBookingConfirmation(_ booking: Booking)
    func requestWatchHapticFeedback(_ pattern: WatchHapticPattern)
    
    // MARK: - Session Management
    func activateSession()
    func deactivateSession()
    func refreshConnectionState()
}

// MARK: - Watch Connection State
enum WatchConnectionState: String {
    case notPaired = "Watch Not Paired"
    case paired = "Watch Paired"
    case appNotInstalled = "App Not Installed"
    case inactive = "Connection Inactive"
    case activating = "Activating Connection"
    case active = "Connection Active"
    case reachable = "Watch Reachable"
    case unreachable = "Watch Unreachable"
    case error = "Connection Error"
    
    var isConnected: Bool {
        switch self {
        case .active, .reachable:
            return true
        default:
            return false
        }
    }
    
    var canSendData: Bool {
        self == .reachable
    }
}

// MARK: - Watch Haptic Pattern
/// Defines haptic patterns that can be played on Apple Watch
struct WatchHapticPattern: Codable {
    enum HapticType: String, Codable {
        case notification
        case directionUp
        case directionDown
        case success
        case failure
        case retry
        case start
        case stop
        case click
        case tap
        
        // Booking specific patterns
        case bookingStepProgress
        case paymentProcessing
        case bookingConfirmed
        case bookingError
        case milestoneReached
    }
    
    let type: HapticType
    let intensity: Double // 0.0 to 1.0
    let duration: TimeInterval?
    let repeatCount: Int
    let customPattern: [WatchHapticEvent]?
    
    init(type: HapticType, 
         intensity: Double = 0.7, 
         duration: TimeInterval? = nil, 
         repeatCount: Int = 1,
         customPattern: [WatchHapticEvent]? = nil) {
        self.type = type
        self.intensity = min(max(intensity, 0.0), 1.0)
        self.duration = duration
        self.repeatCount = max(repeatCount, 1)
        self.customPattern = customPattern
    }
}

// MARK: - Watch Haptic Event
struct WatchHapticEvent: Codable {
    let timestamp: TimeInterval
    let intensity: Double
    let duration: TimeInterval
    
    init(timestamp: TimeInterval, intensity: Double, duration: TimeInterval = 0.1) {
        self.timestamp = timestamp
        self.intensity = min(max(intensity, 0.0), 1.0)
        self.duration = duration
    }
}

// MARK: - Watch Message Types
enum WatchMessageType: String {
    // Connection
    case ping = "ping"
    case pong = "pong"
    case handshake = "handshake"
    
    // Booking Flow
    case bookingStepUpdate = "bookingStepUpdate"
    case bookingStateChange = "bookingStateChange"
    case paymentProgress = "paymentProgress"
    case bookingConfirmation = "bookingConfirmation"
    case bookingError = "bookingError"
    
    // Haptic Coordination
    case hapticRequest = "hapticRequest"
    case hapticConfirmation = "hapticConfirmation"
    
    // User Actions
    case userAction = "userAction"
    case quickAction = "quickAction"
    
    // Data Sync
    case dataSync = "dataSync"
    case dataSyncRequest = "dataSyncRequest"
    case dataSyncResponse = "dataSyncResponse"
}

// MARK: - Watch Transfer Priority
enum WatchTransferPriority: Int {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    var shouldUseMessage: Bool {
        self.rawValue >= WatchTransferPriority.high.rawValue
    }
    
    var requiresResponse: Bool {
        self == .critical
    }
}

// MARK: - Booking Watch Data
/// Lightweight data structure for Watch booking synchronization
struct BookingWatchData: Codable {
    let bookingId: String?
    let className: String
    let instructorName: String
    let startTime: Date
    let venue: String
    let currentStep: Int
    let totalSteps: Int
    let participantCount: Int
    let totalPrice: Double
    let paymentMethod: String
    let status: String
    let imageData: Data? // Compressed class image
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalPrice)) ?? "$0.00"
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: startTime)
    }
}

// MARK: - Watch Quick Actions
enum WatchQuickAction: String, CaseIterable {
    case viewUpcomingBookings = "viewUpcoming"
    case quickRebook = "quickRebook"
    case favoriteClass = "favoriteClass"
    case shareClass = "shareClass"
    case contactInstructor = "contactInstructor"
    case cancelBooking = "cancelBooking"
    
    var title: String {
        switch self {
        case .viewUpcomingBookings:
            return "Upcoming"
        case .quickRebook:
            return "Rebook"
        case .favoriteClass:
            return "Favorite"
        case .shareClass:
            return "Share"
        case .contactInstructor:
            return "Contact"
        case .cancelBooking:
            return "Cancel"
        }
    }
    
    var symbolName: String {
        switch self {
        case .viewUpcomingBookings:
            return "calendar"
        case .quickRebook:
            return "arrow.clockwise"
        case .favoriteClass:
            return "heart"
        case .shareClass:
            return "square.and.arrow.up"
        case .contactInstructor:
            return "message"
        case .cancelBooking:
            return "xmark.circle"
        }
    }
}