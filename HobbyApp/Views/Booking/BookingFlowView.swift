import SwiftUI
// Using Apple Pay/StoreKit instead of Stripe

struct BookingFlowView: View {
    let classItem: ClassItem
    @StateObject private var viewModel = BookingViewModel()
    @StateObject private var watchSync = BookingWatchSyncService()
    @EnvironmentObject var hapticService: HapticFeedbackService
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 0
    @State private var showingCancelAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Bar
                    BookingProgressBar(
                        currentStep: currentStep,
                        totalSteps: 5,
                        stepTitles: ["Select", "Details", "Payment", "Review", "Confirm"]
                    )
                    .padding(.horizontal)
                    .padding(.top, BrandConstants.Spacing.sm)
                    
                    // Watch Connection Status
                    if watchSync.isConnected {
                        HStack {
                            Image(systemName: "applewatch.radiowaves.left.and.right")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.green)
                            Text("Apple Watch Connected")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(20)
                        .padding(.top, BrandConstants.Spacing.sm)
                    }
                    
                    // Step Content
                    TabView(selection: $currentStep) {
                        // Step 1: Participant Selection
                        ParticipantSelectionStep(
                            viewModel: viewModel,
                            classItem: classItem
                        )
                        .tag(0)
                        
                        // Step 2: Booking Details
                        BookingDetailsStep(
                            viewModel: viewModel,
                            classItem: classItem
                        )
                        .tag(1)
                        
                        // Step 3: Payment Method
                        PaymentSelectionStep(
                            viewModel: viewModel,
                            classItem: classItem
                        )
                        .tag(2)
                        
                        // Step 4: Review
                        BookingReviewStep(
                            viewModel: viewModel,
                            classItem: classItem
                        )
                        .tag(3)
                        
                        // Step 5: Confirmation
                        BookingConfirmationStep(
                            viewModel: viewModel,
                            classItem: classItem
                        )
                        .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .disabled(viewModel.isProcessing)
                    
                    // Bottom Navigation
                    HStack(spacing: 16) {
                        // Back Button
                        if currentStep > 0 && currentStep < 4 {
                            Button {
                                hapticService.playLight()
                                withAnimation {
                                    currentStep -= 1
                                }
                                watchSync.syncBookingStep(currentStep, of: 5)
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
                        
                        // Continue/Pay Button
                        if currentStep < 4 {
                            Button {
                                handleContinue()
                            } label: {
                                HStack {
                                    if viewModel.isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(buttonTitle)
                                            .fontWeight(.semibold)
                                        if currentStep < 3 {
                                            Image(systemName: "chevron.right")
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isStepValid ? Color.accentColor : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!isStepValid || viewModel.isProcessing)
                        } else {
                            // Done Button on Confirmation
                            Button {
                                hapticService.playSuccess()
                                dismiss()
                            } label: {
                                Text("Done")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
                
                // Loading Overlay
                if viewModel.isProcessing {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProcessingOverlay(
                                message: viewModel.processingMessage,
                                progress: viewModel.processingProgress
                            )
                        )
                }
            }
            .navigationTitle("Book Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentStep < 4 {
                        Button("Cancel") {
                            hapticService.playLight()
                            showingCancelAlert = true
                        }
                    }
                }
            }
            .alert("Cancel Booking?", isPresented: $showingCancelAlert) {
                Button("Continue Booking", role: .cancel) {
                    hapticService.playLight()
                }
                Button("Cancel Booking", role: .destructive) {
                    hapticService.playWarning()
                    watchSync.cancelBooking()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to cancel this booking? Your progress will be lost.")
            }
            .onChange(of: currentStep) { _, newStep in
                watchSync.syncBookingStep(newStep, of: 5)
                hapticService.playBookingStepTransition()
            }
            .onChange(of: viewModel.bookingComplete) { _, complete in
                if complete {
                    hapticService.playBookingSuccess()
                    watchSync.sendBookingConfirmation(
                        classItem.name,
                        date: classItem.startTime,
                        confirmationCode: viewModel.confirmationCode
                    )
                }
            }
            .onAppear {
                viewModel.initializeBooking(for: classItem)
                watchSync.startBookingSession(for: classItem.name)
            }
            .onDisappear {
                watchSync.endBookingSession()
            }
        }
    }
    
    private var buttonTitle: String {
        if currentStep == 3 && viewModel.selectedPaymentMethod == .credits && viewModel.totalPrice <= viewModel.userCredits {
            return "Confirm Booking"
        } else {
            switch currentStep {
            case 0: return "Continue to Details"
            case 1: return "Continue to Payment"
            case 2: return "Review Booking"
            case 3: return "Pay \(viewModel.formattedTotalPrice)"
            default: return "Continue"
            }
        }
    }
    
    private var isStepValid: Bool {
        switch currentStep {
        case 0: return viewModel.participantCount > 0
        case 1: return true // Details are optional
        case 2: 
            // Payment method must be selected
            guard viewModel.selectedPaymentMethod != nil else { return false }
            
            // If paying with credits, ensure sufficient balance
            if viewModel.selectedPaymentMethod == .credits {
                return viewModel.userCredits >= viewModel.totalPrice
            }
            return true
        case 3: return viewModel.agreedToTerms
        default: return true
        }
    }
    
    private func handleContinue() {
        hapticService.playMedium()
        
        if currentStep == 3 {
            // Process payment
            Task {
                await viewModel.processPayment()
            }
        } else {
            withAnimation {
                currentStep += 1
            }
        }
    }
}

// Progress Bar Component
struct BookingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    let stepTitles: [String]
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress Line
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background line
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress line
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(
                            width: geometry.size.width * (Double(currentStep + 1) / Double(totalSteps)),
                            height: 4
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
                }
            }
            .frame(height: 4)
            
            // Step Labels
            HStack {
                ForEach(0..<stepTitles.count, id: \.self) { index in
                    Text(stepTitles[index])
                        .font(BrandConstants.Typography.caption)
                        .fontWeight(index <= currentStep ? .medium : .regular)
                        .foregroundColor(index <= currentStep ? .primary : .secondary)
                    
                    if index < stepTitles.count - 1 {
                        Spacer()
                    }
                }
            }
        }
    }
}

// Participant Selection Step
struct ParticipantSelectionStep: View {
    @ObservedObject var viewModel: BookingViewModel
    let classItem: ClassItem
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Class Info Card
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
                        Text(classItem.startTime.formatted(date: .abbreviated, time: .shortened))
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(.secondary)
                        Text("\(classItem.spotsAvailable) spots available")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Participant Count
                VStack(alignment: .leading, spacing: 12) {
                    Text("How many participants?")
                        .font(BrandConstants.Typography.headline)
                    
                    HStack(spacing: 20) {
                        Button {
                            if viewModel.participantCount > 1 {
                                viewModel.participantCount -= 1
                                hapticService.playLight()
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
                            .frame(minWidth: 50)
                        
                        Button {
                            if viewModel.participantCount < min(classItem.spotsAvailable, 10) {
                                viewModel.participantCount += 1
                                hapticService.playLight()
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(BrandConstants.Typography.title2)
                                .foregroundColor(viewModel.participantCount < min(classItem.spotsAvailable, 10) ? .accentColor : .gray)
                        }
                        .disabled(viewModel.participantCount >= min(classItem.spotsAvailable, 10))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Participant Details
                if viewModel.participantCount > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Participant Details")
                            .font(BrandConstants.Typography.headline)
                        
                        ForEach(0..<viewModel.participantCount, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Participant \(index + 1)")
                                    .font(BrandConstants.Typography.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField(
                                    "Name (optional)",
                                    text: Binding(
                                        get: { viewModel.participantNames[index] ?? "" },
                                        set: { viewModel.participantNames[index] = $0 }
                                    )
                                )
                                .textFieldStyle(RoundedTextFieldStyle())
                            }
                        }
                    }
                }
                
                // Price Summary
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Price per person")
                        Spacer()
                        Text(classItem.price)
                    }
                    .font(BrandConstants.Typography.subheadline)
                    
                    if viewModel.participantCount > 1 {
                        HStack {
                            Text("× \(viewModel.participantCount) participants")
                            Spacer()
                            Text("")
                        }
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Subtotal")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(viewModel.formattedSubtotal)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

// Booking Details Step
struct BookingDetailsStep: View {
    @ObservedObject var viewModel: BookingViewModel
    let classItem: ClassItem
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Special Requests
                VStack(alignment: .leading, spacing: 12) {
                    Text("Special Requests")
                        .font(BrandConstants.Typography.headline)
                    
                    Text("Let the instructor know about any special needs or requests")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $viewModel.specialRequests)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Experience Level
                VStack(alignment: .leading, spacing: 12) {
                    Text("Experience Level")
                        .font(BrandConstants.Typography.headline)
                    
                    ForEach(["Beginner", "Intermediate", "Advanced"], id: \.self) { level in
                        HStack {
                            Image(systemName: viewModel.experienceLevel == level ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(viewModel.experienceLevel == level ? .accentColor : .secondary)
                            Text(level)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.experienceLevel = level
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Equipment Rental
                if !classItem.equipment.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Equipment Rental")
                            .font(BrandConstants.Typography.headline)
                        
                        ForEach(classItem.equipment, id: \.name) { item in
                            HStack {
                                Toggle("", isOn: Binding(
                                    get: { viewModel.selectedEquipment.contains(item.name) },
                                    set: { isOn in
                                        if isOn {
                                            viewModel.selectedEquipment.insert(item.name)
                                        } else {
                                            viewModel.selectedEquipment.remove(item.name)
                                        }
                                    }
                                ))
                                .labelsHidden()
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(BrandConstants.Typography.subheadline)
                                    Text("+\(item.price)")
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
                
                // Emergency Contact
                VStack(alignment: .leading, spacing: 12) {
                    Text("Emergency Contact")
                        .font(BrandConstants.Typography.headline)
                    
                    TextField("Contact Name", text: $viewModel.emergencyContactName)
                        .textFieldStyle(RoundedTextFieldStyle())
                    
                    TextField("Contact Phone", text: $viewModel.emergencyContactPhone)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .keyboardType(.phonePad)
                }
            }
            .padding()
        }
    }
}

// Payment Selection Step
struct PaymentSelectionStep: View {
    @ObservedObject var viewModel: BookingViewModel
    let classItem: ClassItem
    @EnvironmentObject var hapticService: HapticFeedbackService
    @State private var showingPaymentSheet = false
    @State private var showingCouponField = false
    @State private var couponCode = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Saved Payment Methods
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Method")
                        .font(BrandConstants.Typography.headline)
                    
                    // Option: Pay with Credits
                    if viewModel.userCredits >= viewModel.totalPrice {
                        PaymentMethodRow(
                            icon: "dollarsign.circle.fill",
                            title: "Pay with Credits",
                            subtitle: "Balance: \(String(format: "$%.2f", viewModel.userCredits))",
                            isSelected: viewModel.selectedPaymentMethod == .credits,
                            action: {
                                viewModel.selectedPaymentMethod = .credits
                                hapticService.playSelection()
                            }
                        )
                    }
                    
                    // Apple Pay
                    PaymentMethodRow(
                        icon: "apple.logo",
                        title: "Apple Pay",
                        subtitle: "Quick and secure",
                        isSelected: viewModel.selectedPaymentMethod == .applePay,
                        action: {
                            viewModel.selectedPaymentMethod = .applePay
                            hapticService.playSelection()
                        }
                    )
                    
                    // Saved Cards
                    ForEach(viewModel.savedCards) { card in
                        PaymentMethodRow(
                            icon: "creditcard.fill",
                            title: card.brand,
                            subtitle: "•••• \(card.last4)",
                            isSelected: viewModel.selectedPaymentMethod == .card(card.id),
                            action: {
                                viewModel.selectedPaymentMethod = .card(card.id)
                                hapticService.playSelection()
                            }
                        )
                    }
                    
                    // Add New Card
                    Button {
                        hapticService.playLight()
                        showingPaymentSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                            Text("Add Payment Method")
                                .font(BrandConstants.Typography.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                // Coupon Code
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Promo Code")
                            .font(BrandConstants.Typography.headline)
                        Spacer()
                        Button {
                            withAnimation {
                                showingCouponField.toggle()
                            }
                            hapticService.playLight()
                        } label: {
                            Text(showingCouponField ? "Cancel" : "Add")
                                .font(BrandConstants.Typography.subheadline)
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    if showingCouponField {
                        HStack {
                            TextField("Enter code", text: $couponCode)
                                .textFieldStyle(RoundedTextFieldStyle())
                            
                            Button {
                                hapticService.playMedium()
                                viewModel.applyCoupon(couponCode)
                            } label: {
                                Text("Apply")
                                    .font(BrandConstants.Typography.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.accentColor)
                                    .cornerRadius(8)
                            }
                            .disabled(couponCode.isEmpty)
                        }
                    }
                    
                    if let discount = viewModel.appliedDiscount {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("\(discount.code): \(discount.percentage)% off applied")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Price Breakdown
                VStack(spacing: 12) {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(viewModel.formattedSubtotal)
                    }
                    .font(BrandConstants.Typography.subheadline)
                    
                    if viewModel.equipmentTotal > 0 {
                        HStack {
                            Text("Equipment Rental")
                            Spacer()
                            Text(viewModel.formattedEquipmentTotal)
                        }
                        .font(BrandConstants.Typography.subheadline)
                    }
                    
                    if let discount = viewModel.appliedDiscount {
                        HStack {
                            Text("Discount (\(discount.percentage)%)")
                            Spacer()
                            Text("-\(viewModel.formattedDiscountAmount)")
                                .foregroundColor(.green)
                        }
                        .font(BrandConstants.Typography.subheadline)
                    }
                    
                    HStack {
                        Text("Processing Fee")
                        Spacer()
                        Text(viewModel.formattedProcessingFee)
                    }
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(BrandConstants.Typography.headline)
                        Spacer()
                        Text(viewModel.formattedTotalPrice)
                            .font(BrandConstants.Typography.headline)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentSheetView(viewModel: viewModel)
        }
    }
}

// Payment Method Row
struct PaymentMethodRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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

// Review Step
struct BookingReviewStep: View {
    @ObservedObject var viewModel: BookingViewModel
    let classItem: ClassItem
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Class Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Class Details")
                        .font(BrandConstants.Typography.headline)
                    
                    ReviewRow(label: "Class", value: classItem.name)
                    ReviewRow(label: "Date", value: classItem.startTime.formatted(date: .abbreviated, time: .omitted))
                    ReviewRow(label: "Time", value: classItem.startTime.formatted(date: .omitted, time: .shortened))
                    ReviewRow(label: "Duration", value: classItem.duration)
                    ReviewRow(label: "Location", value: classItem.venueName)
                    ReviewRow(label: "Instructor", value: classItem.instructor)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Booking Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Booking Details")
                        .font(BrandConstants.Typography.headline)
                    
                    ReviewRow(label: "Participants", value: "\(viewModel.participantCount)")
                    
                    if !viewModel.specialRequests.isEmpty {
                        ReviewRow(label: "Special Requests", value: viewModel.specialRequests)
                    }
                    
                    if !viewModel.selectedEquipment.isEmpty {
                        ReviewRow(label: "Equipment", value: viewModel.selectedEquipment.joined(separator: ", "))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Payment Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Summary")
                        .font(BrandConstants.Typography.headline)
                    
                    ReviewRow(label: "Payment Method", value: viewModel.paymentMethodDescription)
                    ReviewRow(label: "Total Amount", value: viewModel.formattedTotalPrice)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Terms and Conditions
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $viewModel.agreedToTerms) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I agree to the terms and conditions")
                                .font(BrandConstants.Typography.subheadline)
                            Text("Including the cancellation policy")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: viewModel.agreedToTerms) { _, _ in
                        hapticService.playLight()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

// Review Row Component
struct ReviewRow: View {
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

// Confirmation Step
struct BookingConfirmationStep: View {
    @ObservedObject var viewModel: BookingViewModel
    let classItem: ClassItem
    @State private var showConfetti = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success Animation
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showConfetti ? 1.2 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showConfetti)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(BrandConstants.Typography.heroTitle)
                        .foregroundColor(.green)
                        .scaleEffect(showConfetti ? 1.0 : 0.5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: showConfetti)
                }
                .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text("Booking Confirmed!")
                        .font(BrandConstants.Typography.title)
                        .fontWeight(.bold)
                    
                    Text("Your spot is reserved")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Confirmation Code
                VStack(spacing: 8) {
                    Text("Confirmation Code")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.confirmationCode)
                        .font(BrandConstants.Typography.title2)
                        .fontWeight(.bold)
                        .fontDesign(.monospaced)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Next Steps
                VStack(alignment: .leading, spacing: 16) {
                    Text("What's Next?")
                        .font(BrandConstants.Typography.headline)
                    
                    NextStepRow(
                        icon: "calendar.badge.plus",
                        title: "Added to Calendar",
                        subtitle: "We've added this class to your calendar"
                    )
                    
                    NextStepRow(
                        icon: "envelope.fill",
                        title: "Confirmation Email",
                        subtitle: "Check your inbox for booking details"
                    )
                    
                    NextStepRow(
                        icon: "bell.fill",
                        title: "Reminder Set",
                        subtitle: "We'll remind you 24 hours before class"
                    )
                    
                    NextStepRow(
                        icon: "map.fill",
                        title: "Get Directions",
                        subtitle: "Tap to get directions to the venue"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        // Add to calendar
                    } label: {
                        Label("Add to Calendar", systemImage: "calendar")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    Button {
                        // Share
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation {
                showConfetti = true
            }
        }
    }
}

// Next Step Row Component
struct NextStepRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(BrandConstants.Typography.title3)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// Processing Overlay
struct ProcessingOverlay: View {
    let message: String
    let progress: Double
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text(message)
                .font(BrandConstants.Typography.headline)
                .foregroundColor(.white)
            
            if progress > 0 {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(width: 200)
            }
        }
        .padding(40)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
}

// Payment Sheet View (Stripe Integration)
struct PaymentSheetView: View {
    @ObservedObject var viewModel: BookingViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Payment Method")
                    .font(BrandConstants.Typography.title2)
                    .fontWeight(.bold)
                    .padding()
                
                // Stripe PaymentSheet would go here
                Text("Stripe Payment Sheet Integration")
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
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
}

struct BookingFlowView_Previews: PreviewProvider {
    static var previews: some View {
        BookingFlowView(classItem: ClassItem.sample)
            .environmentObject(HapticFeedbackService.shared)
    }
}