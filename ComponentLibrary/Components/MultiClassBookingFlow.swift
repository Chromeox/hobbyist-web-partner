import SwiftUI

// MARK: - Refactored Multi-Class Booking Flow Component

struct MultiClassBookingFlow: View, InteractiveComponent {
    typealias Configuration = BookingFlowConfiguration
    typealias Action = BookingFlowAction
    
    // MARK: - Properties
    let configuration: BookingFlowConfiguration
    let onAction: ((BookingFlowAction) -> Void)?
    
    @State private var currentStep: BookingStep = .classSelection
    @State private var selectedClasses: Set<UUID> = []
    @State private var bookingData = BookingData()
    @State private var isProcessing = false
    
    // MARK: - Initializer
    init(
        onBookingComplete: ((BookingData) -> Void)? = nil,
        onStepChange: ((BookingStep) -> Void)? = nil,
        configuration: BookingFlowConfiguration = BookingFlowConfiguration()
    ) {
        self.configuration = configuration
        self.onAction = { action in
            switch action {
            case .stepChanged(let step):
                onStepChange?(step)
            case .bookingCompleted(let data):
                onBookingComplete?(data)
            case .cancelled:
                break
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        buildContent()
    }
    
    @ViewBuilder
    func buildContent() -> some View {
        VStack(spacing: 0) {
            BookingProgressBar(
                currentStep: currentStep,
                totalSteps: BookingStep.allCases.count,
                configuration: configuration
            )
            
            BookingStepContainer(
                currentStep: currentStep,
                selectedClasses: $selectedClasses,
                bookingData: $bookingData,
                isProcessing: $isProcessing,
                onStepChange: { step in
                    withAnimation(.easeInOut(duration: configuration.animationDuration)) {
                        currentStep = step
                    }
                    onAction?(.stepChanged(step))
                },
                onBookingComplete: { data in
                    onAction?(.bookingCompleted(data))
                },
                configuration: configuration
            )
        }
        .componentStyle(configuration)
    }
    
    enum BookingFlowAction {
        case stepChanged(BookingStep)
        case bookingCompleted(BookingData)
        case cancelled
    }
}

// MARK: - Booking Progress Bar Sub-Component

struct BookingProgressBar: View {
    let currentStep: BookingStep
    let totalSteps: Int
    let configuration: BookingFlowConfiguration
    
    private var progress: Double {
        Double(currentStep.stepNumber) / Double(totalSteps)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Step \(currentStep.stepNumber) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(currentStep.title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .scaleEffect(y: 2)
            
            HStack(spacing: 8) {
                ForEach(BookingStep.allCases, id: \.self) { step in
                    StepIndicator(
                        step: step,
                        currentStep: currentStep,
                        isCompleted: step.stepNumber < currentStep.stepNumber
                    )
                }
            }
        }
        .padding()
        .background(.background)
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
}

// MARK: - Step Indicator Sub-Component

struct StepIndicator: View {
    let step: BookingStep
    let currentStep: BookingStep
    let isCompleted: Bool
    
    private var isActive: Bool { step == currentStep }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text("\(step.stepNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isActive ? .white : .secondary)
                }
            }
            
            Text(step.shortTitle)
                .font(.caption2)
                .foregroundColor(isActive ? .primary : .secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var indicatorColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return .accentColor
        } else {
            return .gray.opacity(0.3)
        }
    }
}

// MARK: - Booking Step Container Sub-Component

struct BookingStepContainer: View {
    let currentStep: BookingStep
    @Binding var selectedClasses: Set<UUID>
    @Binding var bookingData: BookingData
    @Binding var isProcessing: Bool
    let onStepChange: (BookingStep) -> Void
    let onBookingComplete: (BookingData) -> Void
    let configuration: BookingFlowConfiguration
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                stepContent
                
                BookingStepActions(
                    currentStep: currentStep,
                    canProceed: canProceedToNextStep,
                    isProcessing: isProcessing,
                    onNext: proceedToNextStep,
                    onBack: goToPreviousStep,
                    configuration: configuration
                )
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .classSelection:
            ClassSelectionStep(
                selectedClasses: $selectedClasses,
                bookingData: $bookingData
            )
        case .timeSlotSelection:
            TimeSlotSelectionStep(
                selectedClasses: selectedClasses,
                bookingData: $bookingData
            )
        case .personalDetails:
            PersonalDetailsStep(bookingData: $bookingData)
        case .paymentMethod:
            PaymentMethodStep(bookingData: $bookingData)
        case .confirmation:
            BookingConfirmationStep(
                bookingData: bookingData,
                selectedClasses: selectedClasses
            )
        case .completion:
            BookingCompletionStep(bookingData: bookingData)
        }
    }
    
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case .classSelection:
            return !selectedClasses.isEmpty
        case .timeSlotSelection:
            return bookingData.selectedTimeSlots.count == selectedClasses.count
        case .personalDetails:
            return bookingData.personalDetails.isValid
        case .paymentMethod:
            return bookingData.paymentMethod != nil
        case .confirmation:
            return true
        case .completion:
            return false
        }
    }
    
    private func proceedToNextStep() {
        guard let nextStep = currentStep.nextStep else {
            // Complete booking
            isProcessing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isProcessing = false
                onBookingComplete(bookingData)
            }
            return
        }
        
        onStepChange(nextStep)
    }
    
    private func goToPreviousStep() {
        guard let previousStep = currentStep.previousStep else { return }
        onStepChange(previousStep)
    }
}

// MARK: - Booking Step Actions Sub-Component

struct BookingStepActions: View {
    let currentStep: BookingStep
    let canProceed: Bool
    let isProcessing: Bool
    let onNext: () -> Void
    let onBack: () -> Void
    let configuration: BookingFlowConfiguration
    
    var body: some View {
        HStack(spacing: 16) {
            if currentStep != .classSelection {
                Button("Back") {
                    onBack()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            
            Button(nextButtonTitle) {
                onNext()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canProceed ? .accentColor : .gray.opacity(0.3))
            .foregroundColor(canProceed ? .white : .gray)
            .cornerRadius(12)
            .disabled(!canProceed || isProcessing)
            .overlay(
                Group {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                }
            )
        }
        .padding(.top)
    }
    
    private var nextButtonTitle: String {
        if isProcessing {
            return ""
        }
        
        switch currentStep {
        case .classSelection:
            return "Select Time Slots"
        case .timeSlotSelection:
            return "Enter Details"
        case .personalDetails:
            return "Choose Payment"
        case .paymentMethod:
            return "Review Booking"
        case .confirmation:
            return "Complete Booking"
        case .completion:
            return "Done"
        }
    }
}

// MARK: - Individual Step Components

struct ClassSelectionStep: View {
    @Binding var selectedClasses: Set<UUID>
    @Binding var bookingData: BookingData
    
    // Sample data - in real implementation, this would come from ViewModel
    private let availableClasses: [ClassData] = [
        ClassData(
            title: "Morning Yoga Flow",
            instructor: "Sarah Wilson",
            duration: 60,
            price: 25,
            difficulty: .beginner,
            imageURL: nil
        ),
        ClassData(
            title: "HIIT Training",
            instructor: "Mike Johnson",
            duration: 45,
            price: 30,
            difficulty: .intermediate,
            imageURL: nil
        ),
        ClassData(
            title: "Pilates Core",
            instructor: "Emma Davis",
            duration: 50,
            price: 28,
            difficulty: .intermediate,
            imageURL: nil
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ModularHeader(
                title: "Select Classes",
                subtitle: "Choose the classes you'd like to book",
                headerStyle: .medium
            )
            
            MultiClassSelectionGrid(
                classes: availableClasses,
                selectedClasses: selectedClasses,
                onSelectionChange: { classId in
                    if selectedClasses.contains(classId) {
                        selectedClasses.remove(classId)
                    } else {
                        selectedClasses.insert(classId)
                    }
                }
            )
            
            if !selectedClasses.isEmpty {
                BookingSummaryCard(
                    selectedClasses: selectedClasses,
                    availableClasses: availableClasses
                )
            }
        }
    }
}

struct TimeSlotSelectionStep: View {
    let selectedClasses: Set<UUID>
    @Binding var bookingData: BookingData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ModularHeader(
                title: "Select Time Slots",
                subtitle: "Choose when you'd like to attend each class",
                headerStyle: .medium
            )
            
            ForEach(Array(selectedClasses), id: \.self) { classId in
                TimeSlotSelector(
                    classId: classId,
                    selectedTimeSlot: bookingData.selectedTimeSlots[classId],
                    onTimeSlotSelect: { timeSlot in
                        bookingData.selectedTimeSlots[classId] = timeSlot
                    }
                )
            }
        }
    }
}

struct PersonalDetailsStep: View {
    @Binding var bookingData: BookingData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ModularHeader(
                title: "Personal Details",
                subtitle: "We need some information to complete your booking",
                headerStyle: .medium
            )
            
            PersonalDetailsForm(personalDetails: $bookingData.personalDetails)
        }
    }
}

struct PaymentMethodStep: View {
    @Binding var bookingData: BookingData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ModularHeader(
                title: "Payment Method",
                subtitle: "Choose how you'd like to pay",
                headerStyle: .medium
            )
            
            PaymentMethodSelector(paymentMethod: $bookingData.paymentMethod)
        }
    }
}

struct BookingConfirmationStep: View {
    let bookingData: BookingData
    let selectedClasses: Set<UUID>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ModularHeader(
                title: "Confirm Booking",
                subtitle: "Please review your booking details",
                headerStyle: .medium
            )
            
            BookingConfirmationCard(
                bookingData: bookingData,
                selectedClasses: selectedClasses
            )
        }
    }
}

struct BookingCompletionStep: View {
    let bookingData: BookingData
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Booking Confirmed!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Your classes have been successfully booked")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            BookingReceiptCard(bookingData: bookingData)
        }
        .padding(.top, 40)
    }
}

// MARK: - Supporting Sub-Components

struct BookingSummaryCard: View {
    let selectedClasses: Set<UUID>
    let availableClasses: [ClassData]
    
    private var totalPrice: Double {
        availableClasses
            .filter { selectedClasses.contains($0.id) }
            .reduce(0) { $0 + $1.price }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Classes (\(selectedClasses.count))")
                .font(.headline)
                .fontWeight(.medium)
            
            ForEach(availableClasses.filter { selectedClasses.contains($0.id) }, id: \.id) { classData in
                HStack {
                    Text(classData.title)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("$\(classData.price, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("$\(totalPrice, specifier: "%.0f")")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TimeSlotSelector: View {
    let classId: UUID
    let selectedTimeSlot: Date?
    let onTimeSlotSelect: (Date) -> Void
    
    // Sample time slots - in real implementation, this would come from API
    private var availableTimeSlots: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: today)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Class \(classId.uuidString.prefix(8))")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableTimeSlots, id: \.self) { timeSlot in
                        TimeSlotChip(
                            date: timeSlot,
                            isSelected: selectedTimeSlot == timeSlot,
                            onTap: { onTimeSlotSelect(timeSlot) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
    }
}

struct TimeSlotChip: View {
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption)
                
                Text(date.formatted(.dateTime.day()))
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("9:00 AM") // Sample time
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? .accentColor : .gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct PersonalDetailsForm: View {
    @Binding var personalDetails: PersonalDetails
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("First Name", text: $personalDetails.firstName)
                .textFieldStyle(.roundedBorder)
            
            TextField("Last Name", text: $personalDetails.lastName)
                .textFieldStyle(.roundedBorder)
            
            TextField("Email", text: $personalDetails.email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
            
            TextField("Phone", text: $personalDetails.phone)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)
        }
    }
}

struct PaymentMethodSelector: View {
    @Binding var paymentMethod: PaymentMethod?
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(PaymentMethod.allCases, id: \.self) { method in
                PaymentMethodOption(
                    method: method,
                    isSelected: paymentMethod == method,
                    onSelect: { paymentMethod = method }
                )
            }
        }
    }
}

struct PaymentMethodOption: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: method.iconName)
                    .foregroundColor(.accentColor)
                
                Text(method.displayName)
                    .font(.subheadline)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(isSelected ? .accentColor.opacity(0.1) : .background)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .accentColor : .gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct BookingConfirmationCard: View {
    let bookingData: BookingData
    let selectedClasses: Set<UUID>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Booking Summary")
                .font(.headline)
                .fontWeight(.bold)
            
            // Add confirmation details here
            Text("Confirmation details would go here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct BookingReceiptCard: View {
    let bookingData: BookingData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Receipt")
                .font(.headline)
                .fontWeight(.bold)
            
            // Add receipt details here
            Text("Receipt details would go here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Data Models

enum BookingStep: Int, CaseIterable {
    case classSelection = 1
    case timeSlotSelection = 2
    case personalDetails = 3
    case paymentMethod = 4
    case confirmation = 5
    case completion = 6
    
    var stepNumber: Int { rawValue }
    
    var title: String {
        switch self {
        case .classSelection: return "Select Classes"
        case .timeSlotSelection: return "Choose Time Slots"
        case .personalDetails: return "Personal Details"
        case .paymentMethod: return "Payment Method"
        case .confirmation: return "Confirmation"
        case .completion: return "Complete"
        }
    }
    
    var shortTitle: String {
        switch self {
        case .classSelection: return "Classes"
        case .timeSlotSelection: return "Times"
        case .personalDetails: return "Details"
        case .paymentMethod: return "Payment"
        case .confirmation: return "Review"
        case .completion: return "Done"
        }
    }
    
    var nextStep: BookingStep? {
        guard let nextRawValue = BookingStep(rawValue: rawValue + 1) else { return nil }
        return nextRawValue
    }
    
    var previousStep: BookingStep? {
        guard rawValue > 1, let previousRawValue = BookingStep(rawValue: rawValue - 1) else { return nil }
        return previousRawValue
    }
}

struct BookingData {
    var selectedTimeSlots: [UUID: Date] = [:]
    var personalDetails = PersonalDetails()
    var paymentMethod: PaymentMethod?
    var specialRequests: String = ""
    var totalAmount: Double = 0
}

struct PersonalDetails {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phone: String = ""
    
    var isValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !phone.isEmpty
    }
}

enum PaymentMethod: CaseIterable {
    case creditCard
    case applePay
    case paypal
    case credits
    
    var displayName: String {
        switch self {
        case .creditCard: return "Credit Card"
        case .applePay: return "Apple Pay"
        case .paypal: return "PayPal"
        case .credits: return "Class Credits"
        }
    }
    
    var iconName: String {
        switch self {
        case .creditCard: return "creditcard"
        case .applePay: return "applelogo"
        case .paypal: return "p.circle"
        case .credits: return "star.circle"
        }
    }
}

// MARK: - Configuration Objects

struct BookingFlowConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double
    let showProgress: Bool
    let allowBackNavigation: Bool
    
    init(
        isAccessibilityEnabled: Bool = true,
        animationDuration: Double = 0.4,
        showProgress: Bool = true,
        allowBackNavigation: Bool = true
    ) {
        self.isAccessibilityEnabled = isAccessibilityEnabled
        self.animationDuration = animationDuration
        self.showProgress = showProgress
        self.allowBackNavigation = allowBackNavigation
    }
}