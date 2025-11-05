import SwiftUI
import PassKit

struct BookClassView: View {
    let classItem: ClassItem
    @StateObject private var viewModel = EnhancedBookingViewModel()
    @EnvironmentObject var hapticService: HapticFeedbackService
    @Environment(\.dismiss) var dismiss
    
    @State private var showingCancelAlert = false
    @State private var showingPaymentSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Header
                    BookingProgressHeader(
                        currentStep: viewModel.currentStep,
                        title: viewModel.stepTitle,
                        progress: viewModel.progressPercentage
                    )
                    
                    // Step Content
                    TabView(selection: $viewModel.currentStep) {
                        // Step 1: Date & Time Selection
                        DateTimeSelectionView(viewModel: viewModel)
                            .tag(BookingStep.selectDateTime)
                        
                        // Step 2: Participant Details
                        ParticipantDetailsView(viewModel: viewModel)
                            .tag(BookingStep.participantDetails)
                        
                        // Step 3: Payment Method
                        PaymentMethodView(viewModel: viewModel)
                            .tag(BookingStep.paymentMethod)
                        
                        // Step 4: Review Booking
                        ReviewBookingView(viewModel: viewModel)
                            .tag(BookingStep.reviewBooking)
                        
                        // Step 5: Confirmation
                        BookingConfirmationView(viewModel: viewModel)
                            .tag(BookingStep.confirmation)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .disabled(viewModel.isProcessing)
                    
                    // Bottom Navigation
                    if viewModel.currentStep != .confirmation {
                        BookingNavigationButtons(viewModel: viewModel, hapticService: hapticService)
                    }
                }
                
                // Processing Overlay
                if viewModel.isProcessing {
                    BookingProcessingOverlay(
                        message: viewModel.processingMessage,
                        isVisible: viewModel.isProcessing
                    )
                }
                
                // Error Alert
                if let errorMessage = viewModel.errorMessage {
                    ErrorAlertOverlay(
                        message: errorMessage,
                        onDismiss: { viewModel.errorMessage = nil }
                    )
                }
            }
            .navigationTitle("Book Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.currentStep != .confirmation {
                        Button("Cancel") {
                            hapticService.playLight()
                            showingCancelAlert = true
                        }
                    }
                }
            }
            .alert("Cancel Booking?", isPresented: $showingCancelAlert) {
                Button("Continue Booking", role: .cancel) { }
                Button("Cancel Booking", role: .destructive) {
                    hapticService.playWarning()
                    dismiss()
                }
            } message: {
                Text("Your progress will be lost if you cancel now.")
            }
            .onAppear {
                viewModel.initializeBooking(for: classItem)
            }
            .onChange(of: viewModel.bookingComplete) { _, complete in
                if complete {
                    hapticService.playBookingSuccess()
                }
            }
        }
    }
}

// MARK: - Progress Header

struct BookingProgressHeader: View {
    let currentStep: BookingStep
    let title: String
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress Bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .frame(height: 8)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            
            // Step Title
            HStack {
                Text(title)
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Step \(stepNumber) of 5")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var stepNumber: Int {
        BookingStep.allCases.firstIndex(of: currentStep).map { $0 + 1 } ?? 1
    }
}

// MARK: - Date & Time Selection

struct DateTimeSelectionView: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Class Header
                ClassHeaderCard(classItem: viewModel.selectedClass)
                
                // Date Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Date")
                        .font(BrandConstants.Typography.headline)
                    
                    DatePicker(
                        "Class Date",
                        selection: $viewModel.selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .onChange(of: viewModel.selectedDate) { _, _ in
                        viewModel.loadAvailableTimeSlots()
                    }
                }
                
                // Time Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Available Times")
                        .font(BrandConstants.Typography.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(viewModel.availableTimeSlots) { timeSlot in
                            TimeSlotButton(
                                timeSlot: timeSlot,
                                isSelected: viewModel.selectedTimeSlot?.id == timeSlot.id,
                                onTap: {
                                    hapticService.playSelectionChanged()
                                    viewModel.selectTimeSlot(timeSlot)
                                }
                            )
                        }
                    }
                    
                    if viewModel.availableTimeSlots.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(BrandConstants.Typography.title)
                                .foregroundColor(.secondary)
                            
                            Text("No available times for this date")
                                .font(BrandConstants.Typography.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
                
                // Pricing Preview
                if let selectedTimeSlot = viewModel.selectedTimeSlot {
                    PricingPreviewCard(viewModel: viewModel)
                }
            }
            .padding()
        }
    }
}

// MARK: - Participant Details

struct ParticipantDetailsView: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Participant Count
                VStack(alignment: .leading, spacing: 16) {
                    Text("How many participants?")
                        .font(BrandConstants.Typography.headline)
                    
                    ParticipantCountSelector(viewModel: viewModel)
                }
                
                // Participant Names
                if viewModel.participantCount > 1 {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Participant Names")
                            .font(BrandConstants.Typography.headline)
                        
                        ForEach(0..<viewModel.participantCount, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Participant \(index + 1)")
                                    .font(BrandConstants.Typography.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField(
                                    "Full name",
                                    text: Binding(
                                        get: { 
                                            index < viewModel.participantNames.count ? viewModel.participantNames[index] : ""
                                        },
                                        set: { newValue in
                                            while viewModel.participantNames.count <= index {
                                                viewModel.participantNames.append("")
                                            }
                                            viewModel.participantNames[index] = newValue
                                        }
                                    )
                                )
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                }
                
                // Experience Level
                VStack(alignment: .leading, spacing: 16) {
                    Text("Experience Level")
                        .font(BrandConstants.Typography.headline)
                    
                    Picker("Experience Level", selection: $viewModel.experienceLevel) {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Special Requests
                VStack(alignment: .leading, spacing: 16) {
                    Text("Special Requests")
                        .font(BrandConstants.Typography.headline)
                    
                    Text("Any allergies, accessibility needs, or special accommodations?")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $viewModel.specialRequests)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Emergency Contact
                VStack(alignment: .leading, spacing: 16) {
                    Text("Emergency Contact")
                        .font(BrandConstants.Typography.headline)
                    
                    VStack(spacing: 12) {
                        TextField("Contact Name", text: $viewModel.emergencyContactName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Phone Number", text: $viewModel.emergencyContactPhone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                    }
                }
                
                // Equipment Rental
                if let classItem = viewModel.selectedClass, !classItem.equipment.isEmpty {
                    EquipmentSelectionView(viewModel: viewModel, equipment: classItem.equipment)
                }
            }
            .padding()
        }
    }
}

// MARK: - Payment Method

struct PaymentMethodView: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Credits Option
                if CreditService.shared.totalCredits > 0 {
                    CreditPaymentOption(viewModel: viewModel)
                }
                
                // Payment Methods
                VStack(alignment: .leading, spacing: 16) {
                    Text("Payment Method")
                        .font(BrandConstants.Typography.headline)
                    
                    // Apple Pay
                    if PaymentService.shared.isApplePayAvailable {
                        PaymentMethodOption(
                            icon: "apple.logo",
                            title: "Apple Pay",
                            subtitle: "Quick and secure",
                            isSelected: viewModel.selectedPaymentMethod == .applePay,
                            onTap: {
                                hapticService.playSelectionChanged()
                                viewModel.selectPaymentMethod(.applePay)
                            }
                        )
                    }
                    
                    // Credit Card
                    PaymentMethodOption(
                        icon: "creditcard.fill",
                        title: "Credit Card",
                        subtitle: "Visa, Mastercard, Amex",
                        isSelected: viewModel.selectedPaymentMethod == .card,
                        onTap: {
                            hapticService.playSelectionChanged()
                            viewModel.selectPaymentMethod(.card)
                        }
                    )
                }
                
                // Coupon Code
                CouponCodeSection(viewModel: viewModel)
                
                // Price Breakdown
                PriceBreakdownCard(viewModel: viewModel)
            }
            .padding()
        }
    }
}

// MARK: - Review Booking

struct ReviewBookingView: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Class Summary
                ClassSummaryCard(viewModel: viewModel)
                
                // Booking Details
                BookingDetailsCard(viewModel: viewModel)
                
                // Payment Summary
                PaymentSummaryCard(viewModel: viewModel)
                
                // Terms and Conditions
                VStack(alignment: .leading, spacing: 16) {
                    Toggle(isOn: $viewModel.agreedToTerms) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I agree to the terms and conditions")
                                .font(BrandConstants.Typography.subheadline)
                            Text("Including the cancellation policy and waiver")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct ClassHeaderCard: View {
    let classItem: ClassItem?
    
    var body: some View {
        guard let classItem = classItem else { return AnyView(EmptyView()) }
        
        return AnyView(
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: classItem.icon)
                            .font(BrandConstants.Typography.title2)
                            .foregroundColor(.accentColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(classItem.name)
                        .font(BrandConstants.Typography.headline)
                        .fontWeight(.semibold)
                    
                    Text(classItem.venueName)
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(classItem.duration)
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        )
    }
}

struct TimeSlotButton: View {
    let timeSlot: TimeSlot
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(timeSlot.displayTime)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
                
                if timeSlot.isFullyBooked {
                    Text("Sold Out")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.red)
                } else {
                    Text("\(timeSlot.spotsRemaining) spots left")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isSelected ? Color.accentColor : 
                timeSlot.isFullyBooked ? Color(.systemGray5) : Color(.systemGray6)
            )
            .foregroundColor(
                isSelected ? .white :
                timeSlot.isFullyBooked ? .secondary : .primary
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: isSelected ? 2 : 0)
            )
        }
        .disabled(timeSlot.isFullyBooked)
    }
}

struct ParticipantCountSelector: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    var body: some View {
        HStack(spacing: 20) {
            Button {
                if viewModel.participantCount > 1 {
                    hapticService.playLight()
                    viewModel.updateParticipantCount(viewModel.participantCount - 1)
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(BrandConstants.Typography.title2)
                    .foregroundColor(viewModel.participantCount > 1 ? .accentColor : .gray)
            }
            .disabled(viewModel.participantCount <= 1)
            
            Text("\(viewModel.participantCount)")
                .font(BrandConstants.Typography.title)
                .fontWeight(.semibold)
                .frame(minWidth: 40)
            
            Button {
                if viewModel.participantCount < 10 {
                    hapticService.playLight()
                    viewModel.updateParticipantCount(viewModel.participantCount + 1)
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(BrandConstants.Typography.title2)
                    .foregroundColor(viewModel.participantCount < 10 ? .accentColor : .gray)
            }
            .disabled(viewModel.participantCount >= 10)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PricingPreviewCard: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Price per person")
                Spacer()
                Text(viewModel.selectedClass?.price ?? "$0")
            }
            
            if viewModel.participantCount > 1 {
                HStack {
                    Text("× \(viewModel.participantCount) participants")
                    Spacer()
                    Text(viewModel.formattedSubtotal)
                }
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .fontWeight(.semibold)
                Spacer()
                Text(viewModel.formattedSubtotal)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
        }
        .font(BrandConstants.Typography.subheadline)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Navigation Buttons

struct BookingNavigationButtons: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    let hapticService: HapticFeedbackService
    
    var body: some View {
        HStack(spacing: 16) {
            // Back Button
            if viewModel.currentStep != .selectDateTime {
                Button {
                    hapticService.playLight()
                    viewModel.goToPreviousStep()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            
            // Continue Button
            Button {
                hapticService.playMedium()
                viewModel.proceedToNextStep()
            } label: {
                HStack {
                    if viewModel.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(continueButtonTitle)
                            .fontWeight(.semibold)
                        if viewModel.currentStep != .reviewBooking {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canProceedToNextStep ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canProceedToNextStep || viewModel.isProcessing)
        }
        .padding()
    }
    
    private var continueButtonTitle: String {
        switch viewModel.currentStep {
        case .selectDateTime: return "Continue to Details"
        case .participantDetails: return "Continue to Payment"
        case .paymentMethod: return "Review Booking"
        case .reviewBooking: return "Complete Booking"
        case .confirmation: return "Done"
        }
    }
}

// MARK: - Overlays

struct BookingProcessingOverlay: View {
    let message: String
    let isVisible: Bool
    
    var body: some View {
        if isVisible {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .overlay(
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text(message)
                            .font(BrandConstants.Typography.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                )
        }
    }
}

struct ErrorAlertOverlay: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(BrandConstants.Typography.title)
                .foregroundColor(.red)
            
            Text("Booking Error")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            Text(message)
                .font(BrandConstants.Typography.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Try Again") {
                onDismiss()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 20)
        .padding()
    }
}

// MARK: - Placeholder Views for Missing Components

struct EquipmentSelectionView: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    let equipment: [Equipment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Equipment Rental")
                .font(BrandConstants.Typography.headline)
            
            ForEach(equipment, id: \.name) { item in
                HStack {
                    Toggle("", isOn: .constant(false))
                        .labelsHidden()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(BrandConstants.Typography.subheadline)
                        Text(item.price)
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CreditPaymentOption: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Use Credits")
                .font(BrandConstants.Typography.headline)
            
            HStack {
                Toggle("Use available credits", isOn: $viewModel.useCredits)
                Spacer()
            }
            
            if viewModel.useCredits {
                Text("You have \(CreditService.shared.totalCredits) credits available")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PaymentMethodOption: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(BrandConstants.Typography.title3)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct CouponCodeSection: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    @State private var showingCouponField = false
    @State private var couponCode = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Promo Code")
                    .font(BrandConstants.Typography.headline)
                Spacer()
                Button(showingCouponField ? "Cancel" : "Add") {
                    withAnimation {
                        showingCouponField.toggle()
                    }
                }
                .foregroundColor(.accentColor)
            }
            
            if showingCouponField {
                HStack {
                    TextField("Enter code", text: $couponCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Apply") {
                        viewModel.applyCoupon(couponCode)
                        showingCouponField = false
                        couponCode = ""
                    }
                    .disabled(couponCode.isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            if let coupon = viewModel.appliedCoupon {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(coupon.displayText)
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
}

struct PriceBreakdownCard: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Subtotal")
                Spacer()
                Text(viewModel.formattedSubtotal)
            }
            
            if viewModel.discountAmount > 0 {
                HStack {
                    Text("Discount")
                    Spacer()
                    Text(viewModel.formattedDiscountAmount)
                        .foregroundColor(.green)
                }
            }
            
            if viewModel.useCredits && viewModel.creditsToUse > 0 {
                HStack {
                    Text("Credits Applied")
                    Spacer()
                    Text("-\(viewModel.creditsToUse) credits")
                        .foregroundColor(.blue)
                }
            }
            
            if viewModel.processingFee > 0 {
                HStack {
                    Text("Processing Fee")
                    Spacer()
                    Text(viewModel.formattedProcessingFee)
                }
                .font(BrandConstants.Typography.caption)
                .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(BrandConstants.Typography.headline)
                Spacer()
                Text(viewModel.useCredits ? viewModel.formattedRemainingPayment : viewModel.formattedTotalAmount)
                    .font(BrandConstants.Typography.headline)
                    .foregroundColor(.accentColor)
            }
        }
        .font(BrandConstants.Typography.subheadline)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ClassSummaryCard: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Class Details")
                .font(BrandConstants.Typography.headline)
            
            if let classItem = viewModel.selectedClass, let timeSlot = viewModel.selectedTimeSlot {
                VStack(spacing: 8) {
                    DetailRow(label: "Class", value: classItem.name)
                    DetailRow(label: "Date", value: viewModel.selectedDate.formatted(date: .abbreviated, time: .omitted))
                    DetailRow(label: "Time", value: timeSlot.displayTime)
                    DetailRow(label: "Duration", value: classItem.duration)
                    DetailRow(label: "Location", value: classItem.venueName)
                    DetailRow(label: "Instructor", value: classItem.instructor)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BookingDetailsCard: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Booking Details")
                .font(BrandConstants.Typography.headline)
            
            VStack(spacing: 8) {
                DetailRow(label: "Participants", value: "\(viewModel.participantCount)")
                DetailRow(label: "Experience", value: viewModel.experienceLevel.displayName)
                
                if !viewModel.specialRequests.isEmpty {
                    DetailRow(label: "Special Requests", value: viewModel.specialRequests)
                }
                
                DetailRow(label: "Emergency Contact", value: "\(viewModel.emergencyContactName) - \(viewModel.emergencyContactPhone)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PaymentSummaryCard: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Summary")
                .font(BrandConstants.Typography.headline)
            
            VStack(spacing: 8) {
                DetailRow(label: "Payment Method", value: paymentMethodDescription)
                DetailRow(label: "Total Amount", value: viewModel.formattedTotalAmount)
                
                if viewModel.useCredits && viewModel.creditsToUse > 0 {
                    DetailRow(label: "Credits Used", value: "\(viewModel.creditsToUse) credits")
                    DetailRow(label: "Remaining Payment", value: viewModel.formattedRemainingPayment)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var paymentMethodDescription: String {
        switch viewModel.selectedPaymentMethod {
        case .applePay:
            return "Apple Pay"
        case .card:
            return "Credit Card"
        case .credits:
            return "Credits Only"
        default:
            return "Not selected"
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    BookClassView(classItem: ClassItem.sample)
        .environmentObject(HapticFeedbackService.shared)
}