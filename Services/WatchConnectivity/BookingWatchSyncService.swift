import Foundation
import Combine
import SwiftUI

// MARK: - Booking Watch Sync Service
/// Specialized service for synchronizing booking flow between iPhone and Apple Watch
class BookingWatchSyncService: ObservableObject {
    
    // MARK: - Properties
    static let shared = BookingWatchSyncService()
    
    @Published var watchBookingState: BookingWatchState = .disconnected
    @Published var currentWatchStep: BookingViewModel.BookingStep = .selectParticipants
    @Published var isWatchSyncEnabled: Bool = false
    @Published var lastSyncTime: Date?
    @Published var syncStatus: SyncStatus = .idle
    
    private let watchService: WatchConnectivityServiceProtocol
    private let hapticService: HapticFeedbackServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Booking flow data
    @Published var watchBookingData: BookingWatchData?
    @Published var pendingBookings: [BookingWatchData] = []
    @Published var recentBookings: [BookingWatchData] = []
    
    // Sync metrics
    private var syncAttempts = 0
    private var successfulSyncs = 0
    private var failedSyncs = 0
    private var averageSyncTime: TimeInterval = 0
    
    // MARK: - Initialization
    init(watchService: WatchConnectivityServiceProtocol = WatchConnectivityService.shared,
         hapticService: HapticFeedbackServiceProtocol = ServiceContainer.shared.resolve(HapticFeedbackServiceProtocol.self) ?? HapticFeedbackService.shared) {
        self.watchService = watchService
        self.hapticService = hapticService
        setupBindings()
        setupNotificationObservers()
    }
    
    private func setupBindings() {
        // Monitor Watch connection state
        watchService.connectionState
            .sink { [weak self] state in
                self?.handleConnectionStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationObservers() {
        // Listen for Watch actions
        NotificationCenter.default.publisher(for: .watchUserAction)
            .sink { [weak self] notification in
                self?.handleWatchAction(notification)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .watchQuickAction)
            .sink { [weak self] notification in
                self?.handleWatchQuickAction(notification)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Connection Management
    private func handleConnectionStateChange(_ state: WatchConnectionState) {
        switch state {
        case .reachable:
            watchBookingState = .connected
            isWatchSyncEnabled = true
            syncCurrentBookingState()
        case .active:
            watchBookingState = .syncing
        case .unreachable, .paired:
            watchBookingState = .disconnected
            isWatchSyncEnabled = false
        case .notPaired, .appNotInstalled:
            watchBookingState = .notAvailable
            isWatchSyncEnabled = false
        default:
            break
        }
    }
    
    // MARK: - Booking Flow Synchronization
    func startBookingFlowSync(for booking: HobbyClass) {
        guard isWatchSyncEnabled else { return }
        
        syncStatus = .syncing
        let startTime = Date()
        
        // Create initial Watch data
        let watchData = createWatchData(from: booking)
        watchBookingData = watchData
        
        // Send to Watch
        watchService.syncBookingStep(.selectParticipants)
        
        // Play coordinated haptic
        hapticService.playFormFieldFocus()
        watchService.requestWatchHapticFeedback(.init(type: .start))
        
        // Update metrics
        syncAttempts += 1
        lastSyncTime = Date()
        
        // Calculate sync time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateSyncMetrics(startTime: startTime, success: true)
        }
    }
    
    func syncBookingStep(_ step: BookingViewModel.BookingStep, animated: Bool = true) {
        guard isWatchSyncEnabled else { return }
        
        currentWatchStep = step
        
        // Animate transition if needed
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                watchBookingState = .syncing
            }
        }
        
        // Send to Watch
        watchService.syncBookingStep(step)
        
        // Coordinated haptic feedback
        playStepHaptic(for: step)
        
        // Update state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.watchBookingState = .connected
        }
    }
    
    func syncBookingState(_ state: BookingViewModel.BookingState) {
        guard isWatchSyncEnabled else { return }
        
        // Update local state
        switch state {
        case .processing:
            watchBookingState = .processing
            startPaymentProgressSync()
        case .confirmed(let booking):
            watchBookingState = .confirmed
            handleBookingConfirmation(booking)
        case .failed:
            watchBookingState = .error
            handleBookingError()
        default:
            watchBookingState = .connected
        }
        
        // Send to Watch
        watchService.syncBookingState(state)
    }
    
    // MARK: - Payment Progress Sync
    private func startPaymentProgressSync() {
        var progress: Double = 0.0
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            progress += 0.05
            
            if progress >= 1.0 {
                timer.invalidate()
                progress = 1.0
            }
            
            self?.watchService.syncPaymentProgress(progress)
            
            // Haptic milestones
            if [0.25, 0.5, 0.75, 1.0].contains(where: { abs($0 - progress) < 0.01 }) {
                self?.playPaymentMilestoneHaptic(progress: progress)
            }
        }
    }
    
    // MARK: - Booking Confirmation
    private func handleBookingConfirmation(_ booking: Booking) {
        // Create celebration sequence
        let celebrationSequence = DispatchGroup()
        
        celebrationSequence.enter()
        // iPhone haptic
        hapticService.playSignUpSuccess()
        
        // Watch haptic and notification
        watchService.sendBookingConfirmation(booking)
        
        // Store in recent bookings
        if let watchData = createWatchData(from: booking) {
            recentBookings.insert(watchData, at: 0)
            if recentBookings.count > 10 {
                recentBookings.removeLast()
            }
        }
        
        celebrationSequence.leave()
        
        celebrationSequence.notify(queue: .main) { [weak self] in
            self?.syncStatus = .completed
            self?.successfulSyncs += 1
        }
    }
    
    private func handleBookingError() {
        // Error feedback
        hapticService.playLoginFailure()
        watchService.requestWatchHapticFeedback(.init(
            type: .bookingError,
            intensity: 0.9
        ))
        
        syncStatus = .failed
        failedSyncs += 1
    }
    
    // MARK: - Haptic Coordination
    private func playStepHaptic(for step: BookingViewModel.BookingStep) {
        // iPhone haptic based on step
        switch step {
        case .selectParticipants:
            hapticService.playFormFieldFocus()
        case .addDetails:
            hapticService.playAccountCreationStep(step: 2, totalSteps: 5)
        case .selectPayment:
            hapticService.playAccountCreationStep(step: 3, totalSteps: 5)
        case .review:
            hapticService.playAccountCreationStep(step: 4, totalSteps: 5)
        case .confirmation:
            hapticService.playSignUpSuccess()
        }
        
        // Coordinated Watch haptic
        let intensity = 0.3 + (Double(step.rawValue) * 0.15)
        watchService.requestWatchHapticFeedback(.init(
            type: .bookingStepProgress,
            intensity: intensity
        ))
    }
    
    private func playPaymentMilestoneHaptic(progress: Double) {
        // Progressive haptic intensity
        let hapticPattern = HapticPattern(
            events: [],
            duration: 0.2
        )
        hapticService.playCustomPattern(hapticPattern)
        
        // Watch haptic
        watchService.requestWatchHapticFeedback(.init(
            type: .tap,
            intensity: progress
        ))
    }
    
    // MARK: - Watch Action Handling
    private func handleWatchAction(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let action = userInfo["action"] as? String else { return }
        
        print("📱 Handling Watch action: \(action)")
        
        switch action {
        case "nextStep":
            NotificationCenter.default.post(name: .bookingFlowNextStep, object: nil)
        case "previousStep":
            NotificationCenter.default.post(name: .bookingFlowPreviousStep, object: nil)
        case "cancelBooking":
            NotificationCenter.default.post(name: .bookingFlowCancel, object: nil)
        default:
            break
        }
    }
    
    private func handleWatchQuickAction(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let action = userInfo["action"] as? WatchQuickAction else { return }
        
        print("📱 Handling Watch quick action: \(action.title)")
        
        // Post notification for UI to handle
        NotificationCenter.default.post(
            name: .watchQuickActionReceived,
            object: nil,
            userInfo: ["action": action]
        )
    }
    
    // MARK: - Data Synchronization
    func syncCurrentBookingState() {
        guard isWatchSyncEnabled,
              let currentData = watchBookingData else { return }
        
        syncStatus = .syncing
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(currentData)
            
            let syncMessage: [String: Any] = [
                "type": WatchMessageType.dataSync.rawValue,
                "bookingData": data
            ]
            
            watchService.transferUserInfo(syncMessage)
            syncStatus = .completed
            lastSyncTime = Date()
            
        } catch {
            print("❌ Failed to sync booking data: \(error)")
            syncStatus = .failed
        }
    }
    
    func requestWatchDataSync() {
        guard isWatchSyncEnabled else { return }
        
        let request: [String: Any] = [
            "type": WatchMessageType.dataSyncRequest.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        watchService.sendMessage(request, replyHandler: { [weak self] data in
            self?.handleWatchDataResponse(data)
        }, errorHandler: { error in
            print("❌ Watch data sync failed: \(error)")
        })
    }
    
    private func handleWatchDataResponse(_ data: Data) {
        // Process Watch data response
        syncStatus = .completed
        lastSyncTime = Date()
    }
    
    // MARK: - Helper Methods
    private func createWatchData(from class: HobbyClass) -> BookingWatchData {
        BookingWatchData(
            bookingId: nil,
            className: class.title,
            instructorName: class.instructor,
            startTime: class.startDate,
            venue: class.location,
            currentStep: currentWatchStep.rawValue,
            totalSteps: BookingViewModel.BookingStep.allCases.count,
            participantCount: 1,
            totalPrice: class.price,
            paymentMethod: "Not selected",
            status: "pending",
            imageData: nil
        )
    }
    
    private func createWatchData(from booking: Booking) -> BookingWatchData? {
        BookingWatchData(
            bookingId: booking.id,
            className: booking.className,
            instructorName: booking.instructor.name,
            startTime: booking.classStartDate,
            venue: booking.venue.name,
            currentStep: BookingViewModel.BookingStep.confirmation.rawValue,
            totalSteps: BookingViewModel.BookingStep.allCases.count,
            participantCount: booking.participantCount,
            totalPrice: booking.totalAmount,
            paymentMethod: "Paid",
            status: booking.status.rawValue,
            imageData: nil
        )
    }
    
    private func updateSyncMetrics(startTime: Date, success: Bool) {
        let syncTime = Date().timeIntervalSince(startTime)
        
        if success {
            successfulSyncs += 1
            // Update rolling average
            averageSyncTime = ((averageSyncTime * Double(successfulSyncs - 1)) + syncTime) / Double(successfulSyncs)
        } else {
            failedSyncs += 1
        }
        
        syncStatus = success ? .completed : .failed
    }
    
    // MARK: - Public Methods
    func enableWatchSync() {
        watchService.activateSession()
        isWatchSyncEnabled = true
    }
    
    func disableWatchSync() {
        isWatchSyncEnabled = false
        watchService.deactivateSession()
    }
    
    func clearSyncData() {
        watchBookingData = nil
        pendingBookings.removeAll()
        recentBookings.removeAll()
        syncStatus = .idle
        lastSyncTime = nil
    }
    
    var syncSuccessRate: Double {
        guard syncAttempts > 0 else { return 0 }
        return Double(successfulSyncs) / Double(syncAttempts)
    }
}

// MARK: - Supporting Types
enum BookingWatchState {
    case notAvailable
    case disconnected
    case connected
    case syncing
    case processing
    case confirmed
    case error
    
    var description: String {
        switch self {
        case .notAvailable:
            return "Apple Watch not available"
        case .disconnected:
            return "Watch disconnected"
        case .connected:
            return "Watch connected"
        case .syncing:
            return "Syncing with Watch..."
        case .processing:
            return "Processing payment..."
        case .confirmed:
            return "Booking confirmed!"
        case .error:
            return "Sync error"
        }
    }
    
    var symbolName: String {
        switch self {
        case .notAvailable:
            return "applewatch.slash"
        case .disconnected:
            return "applewatch.radiowaves.left.and.right.slash"
        case .connected:
            return "applewatch.radiowaves.left.and.right"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .processing:
            return "hourglass"
        case .confirmed:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .notAvailable, .disconnected:
            return .gray
        case .connected:
            return .green
        case .syncing, .processing:
            return .blue
        case .confirmed:
            return .green
        case .error:
            return .red
        }
    }
}

enum SyncStatus {
    case idle
    case syncing
    case completed
    case failed
    
    var isActive: Bool {
        self == .syncing
    }
}

// MARK: - Notification Names Extension
extension Notification.Name {
    static let bookingFlowNextStep = Notification.Name("bookingFlowNextStep")
    static let bookingFlowPreviousStep = Notification.Name("bookingFlowPreviousStep")
    static let bookingFlowCancel = Notification.Name("bookingFlowCancel")
    static let watchQuickActionReceived = Notification.Name("watchQuickActionReceived")
}

// MARK: - Mock Implementation
class MockBookingWatchSyncService: BookingWatchSyncService {
    override init(watchService: WatchConnectivityServiceProtocol = MockWatchConnectivityService(),
                  hapticService: HapticFeedbackServiceProtocol = MockHapticFeedbackService()) {
        super.init(watchService: watchService, hapticService: hapticService)
        
        // Set mock states
        isWatchSyncEnabled = true
        watchBookingState = .connected
    }
}