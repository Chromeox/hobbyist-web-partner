import SwiftUI
import Combine

// MARK: - Enhanced Booking Flow View with Watch Sync
/// Production-ready booking flow with Apple Watch synchronization and haptic coordination
struct BookingFlowView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: BookingViewModel
    @StateObject private var watchSync = BookingWatchSyncService.shared
    @StateObject private var hapticService = HapticFeedbackService.shared
    
    @State private var showingWatchStatus = false
    @State private var watchStatusAnimation = false
    @State private var stepTransitionAnimation = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let hobbyClass: HobbyClass
    let onComplete: ((Booking) -> Void)?
    
    // MARK: - Initialization
    init(hobbyClass: HobbyClass, onComplete: ((Booking) -> Void)? = nil) {
        self.hobbyClass = hobbyClass
        self.onComplete = onComplete
        self._viewModel = StateObject(wrappedValue: BookingViewModel())
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Watch Connection Status
                    if watchSync.isWatchSyncEnabled {
                        watchConnectionStatusBar
                    }
                    
                    // Progress Indicator
                    bookingProgressBar
                    
                    // Main Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Current Step Content
                            stepContent
                            
                            // Error Message
                            if let error = viewModel.errorMessage {
                                errorMessageView(error)
                            }
                        }
                        .padding()
                    }
                    
                    // Navigation Controls
                    navigationControls
                }
            }
            .navigationTitle("Book \(hobbyClass.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    watchSyncToggle
                }
            }
            .sheet(isPresented: $showingWatchStatus) {
                WatchConnectionStatusView(syncService: watchSync)
            }
            .onAppear {
                setupBookingFlow()
            }
            .onChange(of: viewModel.currentStep) { newStep in
                handleStepChange(newStep)
            }
            .onChange(of: viewModel.bookingState) { newState in
                handleBookingStateChange(newState)
            }
            .onReceive(NotificationCenter.default.publisher(for: .bookingFlowNextStep)) { _ in
                viewModel.proceedToNextStep()
            }
            .onReceive(NotificationCenter.default.publisher(for: .bookingFlowPreviousStep)) { _ in
                viewModel.goToPreviousStep()
            }
            .onReceive(NotificationCenter.default.publisher(for: .bookingFlowCancel)) { _ in
                handleCancel()
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.05),
                Color.purple.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var watchConnectionStatusBar: some View {
        HStack(spacing: 12) {
            Image(systemName: watchSync.watchBookingState.symbolName)
                .foregroundColor(watchSync.watchBookingState.color)
                .font(.system(size: 14, weight: .medium))
                .scaleEffect(watchStatusAnimation ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: watchStatusAnimation)
            
            Text(watchSync.watchBookingState.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if watchSync.syncStatus.isActive {
                ProgressView()
                    .scaleEffect(0.7)
            }
            
            if let syncTime = watchSync.lastSyncTime {
                Text(syncTime, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(watchSync.watchBookingState.color.opacity(0.1))
        )
        .padding(.horizontal)
        .onTapGesture {
            showingWatchStatus = true
        }
        .onAppear {
            if watchSync.watchBookingState == .syncing {
                watchStatusAnimation = true
            }
        }
        .onChange(of: watchSync.watchBookingState) { state in
            watchStatusAnimation = state == .syncing
        }
    }
    
    private var bookingProgressBar: some View {
        VStack(spacing: 12) {
            // Step Labels
            HStack {
                ForEach(BookingViewModel.BookingStep.allCases, id: \.self) { step in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(stepColor(for: step))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text("\(step.rawValue + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(stepTextColor(for: step))
                            )
                            .scaleEffect(step == viewModel.currentStep ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: viewModel.currentStep)
                        
                        Text(step.title)
                            .font(.caption2)
                            .foregroundColor(step == viewModel.currentStep ? .primary : .secondary)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                    }
                    
                    if step != BookingViewModel.BookingStep.allCases.last {
                        Rectangle()
                            .fill(stepLineColor(for: step))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * progressPercentage,
                            height: 4
                        )
                        .cornerRadius(2)
                        .animation(.spring(response: 0.5), value: progressPercentage)
                }
            }
            .frame(height: 4)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .selectParticipants:
            ParticipantSelectionView(
                participantCount: $viewModel.participantCount,
                maxParticipants: hobbyClass.availableSpots,
                pricePerPerson: hobbyClass.price
            )
            
        case .addDetails:
            BookingDetailsView(
                specialRequests: $viewModel.specialRequests,
                selectedClass: hobbyClass
            )
            
        case .selectPayment:
            PaymentSelectionView(
                selectedMethod: $viewModel.paymentMethod,
                appliedCoupon: $viewModel.appliedCoupon,
                totalPrice: viewModel.totalPrice,
                onApplyCoupon: { code in
                    Task {
                        await viewModel.applyCoupon(code: code)
                    }
                }
            )
            
        case .review:
            BookingReviewView(
                hobbyClass: hobbyClass,
                participantCount: viewModel.participantCount,
                specialRequests: viewModel.specialRequests,
                paymentMethod: viewModel.paymentMethod,
                appliedCoupon: viewModel.appliedCoupon,
                totalPrice: viewModel.totalPrice,
                savings: viewModel.savings
            )
            
        case .confirmation:
            if case .confirmed(let booking) = viewModel.bookingState {
                BookingConfirmationView(
                    booking: booking,
                    onDone: {
                        onComplete?(booking)
                        dismiss()
                    }
                )
            }
        }
    }
    
    private var navigationControls: some View {
        HStack(spacing: 16) {
            // Previous Button
            if viewModel.currentStep != .selectParticipants && viewModel.currentStep != .confirmation {
                Button(action: handlePreviousStep) {
                    Label("Previous", systemImage: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            // Next/Confirm Button
            if viewModel.currentStep != .confirmation {
                Button(action: handleNextStep) {
                    HStack {
                        if viewModel.isProcessingPayment {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(nextButtonTitle)
                            Image(systemName: nextButtonIcon)
                        }
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: nextButtonGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .disabled(viewModel.isProcessingPayment)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            handleCancel()
        }
        .foregroundColor(.red)
    }
    
    private var watchSyncToggle: some View {
        Button(action: toggleWatchSync) {
            Image(systemName: watchSync.isWatchSyncEnabled ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                .foregroundColor(watchSync.isWatchSyncEnabled ? .green : .gray)
        }
    }
    
    private func errorMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
            
            Spacer()
            
            Button(action: { viewModel.errorMessage = nil }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.1))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func setupBookingFlow() {
        viewModel.startBooking(for: hobbyClass)
        
        // Initialize Watch sync if available
        if watchSync.isWatchSyncEnabled {
            watchSync.startBookingFlowSync(for: hobbyClass)
        }
        
        // Initial haptic
        hapticService.playFormFieldFocus()
    }
    
    private func handleStepChange(_ step: BookingViewModel.BookingStep) {
        // Sync with Watch
        watchSync.syncBookingStep(step, animated: true)
        
        // Haptic feedback
        hapticService.playAccountCreationStep(
            step: step.rawValue + 1,
            totalSteps: BookingViewModel.BookingStep.allCases.count
        )
        
        // Animate transition
        withAnimation(.spring(response: 0.5)) {
            stepTransitionAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            stepTransitionAnimation = false
        }
    }
    
    private func handleBookingStateChange(_ state: BookingViewModel.BookingState) {
        // Sync with Watch
        watchSync.syncBookingState(state)
        
        switch state {
        case .processing:
            hapticService.prepareHaptics()
        case .confirmed:
            hapticService.playSignUpSuccess()
        case .failed:
            hapticService.playLoginFailure()
        default:
            break
        }
    }
    
    private func handleNextStep() {
        viewModel.proceedToNextStep()
    }
    
    private func handlePreviousStep() {
        viewModel.goToPreviousStep()
    }
    
    private func handleCancel() {
        hapticService.playFormValidationError()
        dismiss()
    }
    
    private func toggleWatchSync() {
        if watchSync.isWatchSyncEnabled {
            watchSync.disableWatchSync()
        } else {
            watchSync.enableWatchSync()
        }
        
        hapticService.selectionFeedback.selectionChanged()
    }
    
    // MARK: - Computed Properties
    
    private var progressPercentage: Double {
        Double(viewModel.currentStep.rawValue + 1) / Double(BookingViewModel.BookingStep.allCases.count)
    }
    
    private var nextButtonTitle: String {
        switch viewModel.currentStep {
        case .review:
            return "Confirm & Pay"
        case .confirmation:
            return "Done"
        default:
            return "Continue"
        }
    }
    
    private var nextButtonIcon: String {
        switch viewModel.currentStep {
        case .review:
            return "creditcard.fill"
        case .confirmation:
            return "checkmark.circle.fill"
        default:
            return "chevron.right"
        }
    }
    
    private var nextButtonGradient: [Color] {
        switch viewModel.currentStep {
        case .review:
            return [.green, .blue]
        case .confirmation:
            return [.green, .mint]
        default:
            return [.blue, .purple]
        }
    }
    
    private func stepColor(for step: BookingViewModel.BookingStep) -> Color {
        if step.rawValue < viewModel.currentStep.rawValue {
            return .green
        } else if step == viewModel.currentStep {
            return .blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private func stepTextColor(for step: BookingViewModel.BookingStep) -> Color {
        if step.rawValue <= viewModel.currentStep.rawValue {
            return .white
        } else {
            return .gray
        }
    }
    
    private func stepLineColor(for step: BookingViewModel.BookingStep) -> Color {
        if step.rawValue < viewModel.currentStep.rawValue {
            return .green
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

// MARK: - Watch Connection Status View
struct WatchConnectionStatusView: View {
    @ObservedObject var syncService: BookingWatchSyncService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Status Icon
                Image(systemName: syncService.watchBookingState.symbolName)
                    .font(.system(size: 60))
                    .foregroundColor(syncService.watchBookingState.color)
                    .padding()
                
                // Status Text
                Text(syncService.watchBookingState.description)
                    .font(.title2.bold())
                
                // Sync Metrics
                VStack(alignment: .leading, spacing: 12) {
                    MetricRow(label: "Sync Status", value: syncService.syncStatus == .syncing ? "Syncing..." : "Ready")
                    MetricRow(label: "Last Sync", value: syncService.lastSyncTime?.formatted() ?? "Never")
                    MetricRow(label: "Success Rate", value: String(format: "%.0f%%", syncService.syncSuccessRate * 100))
                    
                    if !syncService.recentBookings.isEmpty {
                        Divider()
                        Text("Recent Bookings")
                            .font(.headline)
                            .padding(.top)
                        
                        ForEach(syncService.recentBookings.prefix(3), id: \.bookingId) { booking in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(booking.className)
                                        .font(.subheadline.bold())
                                    Text(booking.formattedDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(booking.formattedPrice)
                                    .font(.caption.bold())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: {
                        syncService.syncCurrentBookingState()
                    }) {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        syncService.clearSyncData()
                    }) {
                        Text("Clear Sync Data")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .navigationTitle("Apple Watch Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    struct MetricRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .bold()
            }
        }
    }
}