import Foundation
import WatchConnectivity
import Combine
import UIKit

// MARK: - Watch Connectivity Service Implementation
/// Production-ready service for iPhone-Watch communication with comprehensive error handling
class WatchConnectivityService: NSObject, WatchConnectivityServiceProtocol {
    
    // MARK: - Properties
    static let shared = WatchConnectivityService()
    
    private let session: WCSession
    private var cancellables = Set<AnyCancellable>()
    private let messageQueue = DispatchQueue(label: "com.hobbyist.watchconnectivity", qos: .userInitiated)
    private var pendingMessages: [String: Any] = [:]
    private var replyHandlers: [String: (Data) -> Void] = [:]
    private var errorHandlers: [String: (Error) -> Void] = [:]
    
    // Connection state management
    let connectionState = CurrentValueSubject<WatchConnectionState, Never>(.notPaired)
    private var connectionRetryTimer: Timer?
    private var connectionRetryCount = 0
    private let maxRetryAttempts = 3
    
    // Metrics and analytics
    private var messagesSent = 0
    private var messagesReceived = 0
    private var lastSuccessfulSync: Date?
    private var connectionUptime: TimeInterval = 0
    private var connectionStartTime: Date?
    
    // MARK: - Computed Properties
    var isWatchAppInstalled: Bool {
        #if os(iOS)
        return session.isWatchAppInstalled
        #else
        return true
        #endif
    }
    
    var isWatchPaired: Bool {
        #if os(iOS)
        return session.isPaired
        #else
        return true
        #endif
    }
    
    var isReachable: Bool {
        session.isReachable
    }
    
    // MARK: - Initialization
    private override init() {
        self.session = WCSession.default
        super.init()
        setupSession()
        setupConnectionMonitoring()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else {
            print("⌚ Watch Connectivity not supported on this device")
            connectionState.send(.error)
            return
        }
        
        session.delegate = self
        activateSession()
    }
    
    private func setupConnectionMonitoring() {
        // Monitor reachability changes
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refreshConnectionState()
        }
    }
    
    // MARK: - Session Management
    func activateSession() {
        guard WCSession.isSupported() else { return }
        
        connectionState.send(.activating)
        session.activate()
        connectionStartTime = Date()
        
        // Start connection retry timer
        startConnectionRetry()
    }
    
    func deactivateSession() {
        stopConnectionRetry()
        connectionRetryCount = 0
        
        if let startTime = connectionStartTime {
            connectionUptime += Date().timeIntervalSince(startTime)
        }
        
        connectionState.send(.inactive)
    }
    
    func refreshConnectionState() {
        #if os(iOS)
        if !session.isPaired {
            connectionState.send(.notPaired)
        } else if !session.isWatchAppInstalled {
            connectionState.send(.appNotInstalled)
        } else if session.activationState != .activated {
            connectionState.send(.inactive)
        } else if session.isReachable {
            connectionState.send(.reachable)
            stopConnectionRetry()
        } else {
            connectionState.send(.unreachable)
        }
        #else
        // watchOS side
        if session.activationState != .activated {
            connectionState.send(.inactive)
        } else if session.isReachable {
            connectionState.send(.reachable)
        } else {
            connectionState.send(.unreachable)
        }
        #endif
    }
    
    // MARK: - Connection Retry Logic
    private func startConnectionRetry() {
        guard connectionRetryTimer == nil else { return }
        
        connectionRetryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.retryConnection()
        }
    }
    
    private func stopConnectionRetry() {
        connectionRetryTimer?.invalidate()
        connectionRetryTimer = nil
        connectionRetryCount = 0
    }
    
    private func retryConnection() {
        guard connectionRetryCount < maxRetryAttempts else {
            stopConnectionRetry()
            return
        }
        
        connectionRetryCount += 1
        print("⌚ Retrying Watch connection (attempt \(connectionRetryCount)/\(maxRetryAttempts))")
        
        if session.activationState != .activated {
            session.activate()
        } else {
            // Send ping to check connection
            sendPing()
        }
    }
    
    private func sendPing() {
        let pingMessage = [
            "type": WatchMessageType.ping.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        sendMessage(pingMessage, replyHandler: { [weak self] _ in
            self?.connectionState.send(.reachable)
            self?.stopConnectionRetry()
        }, errorHandler: { [weak self] _ in
            self?.connectionState.send(.unreachable)
        })
    }
    
    // MARK: - Data Transfer Methods
    func sendMessage(_ message: [String: Any], replyHandler: ((Data) -> Void)?, errorHandler: ((Error) -> Void)?) {
        guard session.isReachable else {
            errorHandler?(WatchConnectivityError.notReachable)
            return
        }
        
        let messageId = UUID().uuidString
        var enrichedMessage = message
        enrichedMessage["messageId"] = messageId
        enrichedMessage["timestamp"] = Date().timeIntervalSince1970
        
        if let handler = replyHandler {
            replyHandlers[messageId] = handler
        }
        if let handler = errorHandler {
            errorHandlers[messageId] = handler
        }
        
        messageQueue.async { [weak self] in
            self?.session.sendMessage(enrichedMessage, replyHandler: { reply in
                self?.messagesSent += 1
                self?.lastSuccessfulSync = Date()
                
                if let data = reply["data"] as? Data {
                    DispatchQueue.main.async {
                        self?.replyHandlers[messageId]?(data)
                        self?.replyHandlers.removeValue(forKey: messageId)
                    }
                }
            }, errorHandler: { error in
                print("⌚ Error sending message: \(error)")
                DispatchQueue.main.async {
                    self?.errorHandlers[messageId]?(error)
                    self?.errorHandlers.removeValue(forKey: messageId)
                }
            })
        }
    }
    
    func transferUserInfo(_ userInfo: [String: Any]) {
        var enrichedInfo = userInfo
        enrichedInfo["timestamp"] = Date().timeIntervalSince1970
        enrichedInfo["transferId"] = UUID().uuidString
        
        session.transferUserInfo(enrichedInfo)
        messagesSent += 1
    }
    
    func updateApplicationContext(_ context: [String: Any]) throws {
        var enrichedContext = context
        enrichedContext["lastUpdate"] = Date().timeIntervalSince1970
        enrichedContext["deviceId"] = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        
        try session.updateApplicationContext(enrichedContext)
        lastSuccessfulSync = Date()
    }
    
    func transferFile(_ fileURL: URL, metadata: [String: Any]?) {
        var enrichedMetadata = metadata ?? [:]
        enrichedMetadata["fileName"] = fileURL.lastPathComponent
        enrichedMetadata["fileSize"] = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64
        enrichedMetadata["transferDate"] = Date().timeIntervalSince1970
        
        session.transferFile(fileURL, metadata: enrichedMetadata)
    }
    
    // MARK: - Booking Specific Methods
    func syncBookingStep(_ step: BookingViewModel.BookingStep) {
        let message: [String: Any] = [
            "type": WatchMessageType.bookingStepUpdate.rawValue,
            "step": step.rawValue,
            "stepTitle": step.title,
            "isCompleted": step.isCompleted
        ]
        
        // High priority - use message if reachable, otherwise context
        if session.isReachable {
            sendMessage(message, replyHandler: nil) { error in
                print("⌚ Failed to sync booking step: \(error)")
                // Fallback to application context
                try? self.updateApplicationContext(message)
            }
        } else {
            try? updateApplicationContext(message)
        }
        
        // Request haptic feedback on Watch
        requestWatchHapticFeedback(.init(
            type: .bookingStepProgress,
            intensity: 0.5 + (Double(step.rawValue) * 0.1)
        ))
    }
    
    func syncBookingState(_ state: BookingViewModel.BookingState) {
        var stateInfo: [String: Any] = ["type": WatchMessageType.bookingStateChange.rawValue]
        
        switch state {
        case .idle:
            stateInfo["state"] = "idle"
        case .reviewing:
            stateInfo["state"] = "reviewing"
        case .processing:
            stateInfo["state"] = "processing"
            requestWatchHapticFeedback(.init(type: .paymentProcessing, repeatCount: 3))
        case .confirmed(let booking):
            stateInfo["state"] = "confirmed"
            stateInfo["bookingId"] = booking.id
            sendBookingConfirmation(booking)
        case .failed(let error):
            stateInfo["state"] = "failed"
            stateInfo["error"] = error.localizedDescription
            requestWatchHapticFeedback(.init(type: .bookingError))
        }
        
        // Critical update - use message with fallback
        if session.isReachable {
            sendMessage(stateInfo, replyHandler: nil, errorHandler: nil)
        }
        
        // Always update context for persistence
        try? updateApplicationContext(stateInfo)
    }
    
    func syncPaymentProgress(_ progress: Double) {
        let progressData: [String: Any] = [
            "type": WatchMessageType.paymentProgress.rawValue,
            "progress": progress,
            "isProcessing": progress < 1.0
        ]
        
        // Real-time update if reachable
        if session.isReachable {
            sendMessage(progressData, replyHandler: nil, errorHandler: nil)
        }
        
        // Haptic feedback at milestones
        if [0.25, 0.5, 0.75, 1.0].contains(progress) {
            requestWatchHapticFeedback(.init(
                type: .tap,
                intensity: progress
            ))
        }
    }
    
    func sendBookingConfirmation(_ booking: Booking) {
        // Create lightweight Watch data
        let watchData = BookingWatchData(
            bookingId: booking.id,
            className: booking.className,
            instructorName: booking.instructor.name,
            startTime: booking.classStartDate,
            venue: booking.venue.name,
            currentStep: BookingViewModel.BookingStep.confirmation.rawValue,
            totalSteps: BookingViewModel.BookingStep.allCases.count,
            participantCount: booking.participantCount,
            totalPrice: booking.totalAmount,
            paymentMethod: booking.paymentId,
            status: booking.status.rawValue,
            imageData: nil // Could compress and include class image
        )
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(watchData)
            
            let confirmation: [String: Any] = [
                "type": WatchMessageType.bookingConfirmation.rawValue,
                "bookingData": data,
                "notificationTitle": "Booking Confirmed!",
                "notificationBody": "\(booking.className) on \(watchData.formattedDate)"
            ]
            
            // Critical message - use multiple delivery methods
            if session.isReachable {
                sendMessage(confirmation, replyHandler: { _ in
                    print("⌚ Booking confirmation delivered to Watch")
                }, errorHandler: { error in
                    print("⌚ Failed to deliver booking confirmation: \(error)")
                    // Fallback to user info transfer
                    self.transferUserInfo(confirmation)
                })
            } else {
                // Guaranteed delivery via user info
                transferUserInfo(confirmation)
            }
            
            // Update application context for persistence
            try updateApplicationContext(confirmation)
            
            // Celebration haptic
            requestWatchHapticFeedback(.init(
                type: .bookingConfirmed,
                intensity: 1.0,
                repeatCount: 2
            ))
            
        } catch {
            print("⌚ Error encoding booking data: \(error)")
        }
    }
    
    func requestWatchHapticFeedback(_ pattern: WatchHapticPattern) {
        guard session.isReachable else { return }
        
        do {
            let encoder = JSONEncoder()
            let patternData = try encoder.encode(pattern)
            
            let hapticRequest: [String: Any] = [
                "type": WatchMessageType.hapticRequest.rawValue,
                "pattern": patternData
            ]
            
            sendMessage(hapticRequest, replyHandler: nil, errorHandler: nil)
            
        } catch {
            print("⌚ Error encoding haptic pattern: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("⌚ Session activation failed: \(error)")
            connectionState.send(.error)
            return
        }
        
        print("⌚ Session activated with state: \(activationState.rawValue)")
        
        switch activationState {
        case .activated:
            connectionState.send(.active)
            refreshConnectionState()
        case .inactive:
            connectionState.send(.inactive)
        case .notActivated:
            connectionState.send(.inactive)
        @unknown default:
            connectionState.send(.error)
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("⌚ Session became inactive")
        connectionState.send(.inactive)
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("⌚ Session deactivated, reactivating...")
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("⌚ Watch state changed - Paired: \(session.isPaired), Installed: \(session.isWatchAppInstalled)")
        refreshConnectionState()
    }
    #endif
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("⌚ Reachability changed: \(session.isReachable)")
        refreshConnectionState()
        
        if session.isReachable {
            // Sync any pending data
            syncPendingData()
        }
    }
    
    // MARK: - Message Handling
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        messagesReceived += 1
        handleReceivedMessage(message, replyHandler: nil)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        messagesReceived += 1
        handleReceivedMessage(message, replyHandler: replyHandler)
    }
    
    private func handleReceivedMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        guard let typeString = message["type"] as? String,
              let type = WatchMessageType(rawValue: typeString) else {
            replyHandler?(["error": "Invalid message type"])
            return
        }
        
        switch type {
        case .ping:
            replyHandler?(["type": WatchMessageType.pong.rawValue])
            
        case .pong:
            connectionState.send(.reachable)
            
        case .userAction:
            handleWatchUserAction(message)
            replyHandler?(["success": true])
            
        case .quickAction:
            handleWatchQuickAction(message)
            replyHandler?(["success": true])
            
        case .dataSyncRequest:
            provideSyncData(replyHandler: replyHandler)
            
        case .hapticConfirmation:
            print("⌚ Haptic played on Watch")
            replyHandler?(["success": true])
            
        default:
            replyHandler?(["success": true])
        }
    }
    
    // MARK: - User Info & Context Handling
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        messagesReceived += 1
        print("⌚ Received user info: \(userInfo)")
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("⌚ Received application context update")
        // Handle context updates from Watch
    }
    
    // MARK: - File Transfer Handling
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("⌚ Received file: \(file.fileURL.lastPathComponent)")
        // Handle received files
    }
    
    // MARK: - Helper Methods
    private func syncPendingData() {
        // Sync any queued messages or data
        if !pendingMessages.isEmpty {
            for (_, message) in pendingMessages {
                sendMessage(message, replyHandler: nil, errorHandler: nil)
            }
            pendingMessages.removeAll()
        }
    }
    
    private func handleWatchUserAction(_ message: [String: Any]) {
        // Handle user actions from Watch
        guard let action = message["action"] as? String else { return }
        
        print("⌚ Watch user action: \(action)")
        
        // Post notification for UI to handle
        NotificationCenter.default.post(
            name: .watchUserAction,
            object: nil,
            userInfo: ["action": action, "data": message]
        )
    }
    
    private func handleWatchQuickAction(_ message: [String: Any]) {
        guard let actionString = message["quickAction"] as? String,
              let action = WatchQuickAction(rawValue: actionString) else { return }
        
        print("⌚ Watch quick action: \(action.title)")
        
        // Post notification for UI to handle
        NotificationCenter.default.post(
            name: .watchQuickAction,
            object: nil,
            userInfo: ["action": action, "data": message]
        )
    }
    
    private func provideSyncData(replyHandler: (([String: Any]) -> Void)?) {
        // Provide current app state data to Watch
        var syncData: [String: Any] = [
            "type": WatchMessageType.dataSyncResponse.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Add relevant app state data
        // This would be populated from actual app state
        
        replyHandler?(syncData)
    }
}

// MARK: - Mock Implementation for Testing
class MockWatchConnectivityService: WatchConnectivityServiceProtocol {
    
    var isWatchAppInstalled = true
    var isWatchPaired = true
    var isReachable = true
    let connectionState = CurrentValueSubject<WatchConnectionState, Never>(.reachable)
    
    var sentMessages: [(message: [String: Any], priority: WatchTransferPriority)] = []
    var transferredUserInfo: [[String: Any]] = []
    var applicationContext: [String: Any] = [:]
    var hapticRequests: [WatchHapticPattern] = []
    
    func sendMessage(_ message: [String: Any], replyHandler: ((Data) -> Void)?, errorHandler: ((Error) -> Void)?) {
        sentMessages.append((message, .high))
        replyHandler?(Data())
    }
    
    func transferUserInfo(_ userInfo: [String: Any]) {
        transferredUserInfo.append(userInfo)
    }
    
    func updateApplicationContext(_ context: [String: Any]) throws {
        applicationContext = context
    }
    
    func transferFile(_ fileURL: URL, metadata: [String: Any]?) {
        // Mock implementation
    }
    
    func syncBookingStep(_ step: BookingViewModel.BookingStep) {
        sentMessages.append((["step": step.rawValue], .high))
    }
    
    func syncBookingState(_ state: BookingViewModel.BookingState) {
        var message: [String: Any] = ["type": "bookingState"]
        
        switch state {
        case .confirmed(let booking):
            message["bookingId"] = booking.id
        case .failed(let error):
            message["error"] = error.localizedDescription
        default:
            break
        }
        
        sentMessages.append((message, .critical))
    }
    
    func syncPaymentProgress(_ progress: Double) {
        sentMessages.append((["progress": progress], .normal))
    }
    
    func sendBookingConfirmation(_ booking: Booking) {
        sentMessages.append((["bookingId": booking.id, "confirmed": true], .critical))
    }
    
    func requestWatchHapticFeedback(_ pattern: WatchHapticPattern) {
        hapticRequests.append(pattern)
    }
    
    func activateSession() {
        connectionState.send(.active)
    }
    
    func deactivateSession() {
        connectionState.send(.inactive)
    }
    
    func refreshConnectionState() {
        // Mock implementation
    }
    
    func reset() {
        sentMessages.removeAll()
        transferredUserInfo.removeAll()
        applicationContext.removeAll()
        hapticRequests.removeAll()
    }
}

// MARK: - Error Types
enum WatchConnectivityError: LocalizedError {
    case notSupported
    case notPaired
    case notInstalled
    case notReachable
    case sessionNotActivated
    case transferFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "Watch Connectivity is not supported on this device"
        case .notPaired:
            return "Apple Watch is not paired"
        case .notInstalled:
            return "Companion app is not installed on Apple Watch"
        case .notReachable:
            return "Apple Watch is not reachable"
        case .sessionNotActivated:
            return "Watch session is not activated"
        case .transferFailed(let reason):
            return "Data transfer failed: \(reason)"
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let watchConnectionStateChanged = Notification.Name("watchConnectionStateChanged")
    static let watchUserAction = Notification.Name("watchUserAction")
    static let watchQuickAction = Notification.Name("watchQuickAction")
    static let watchBookingUpdate = Notification.Name("watchBookingUpdate")
}