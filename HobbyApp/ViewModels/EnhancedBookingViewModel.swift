import Foundation
import SwiftUI
import Combine

// MARK: - Enhanced Booking View Model

@MainActor
class EnhancedBookingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Class and booking details
    @Published var selectedClass: ClassItem?
    @Published var selectedDate: Date = Date()
    @Published var selectedTimeSlot: TimeSlot?
    @Published var availableTimeSlots: [TimeSlot] = []
    
    // Participant information
    @Published var participantCount: Int = 1
    @Published var participantNames: [String] = [""]
    @Published var specialRequests: String = ""
    @Published var experienceLevel: ExperienceLevel = .beginner
    @Published var emergencyContactName: String = ""
    @Published var emergencyContactPhone: String = ""
    
    // Equipment and add-ons
    @Published var selectedEquipment: Set<EquipmentItem> = []
    @Published var equipmentCost: Double = 0.0
    
    // Payment and pricing
    @Published var selectedPaymentMethod: PaymentMethodType?
    @Published var appliedCoupon: CouponCode?
    @Published var subtotal: Double = 0.0
    @Published var discountAmount: Double = 0.0
    @Published var processingFee: Double = 0.0
    @Published var totalAmount: Double = 0.0
    @Published var useCredits: Bool = false
    @Published var creditsToUse: Int = 0
    @Published var remainingPayment: Double = 0.0
    
    // Booking state
    @Published var currentStep: BookingStep = .selectDateTime
    @Published var isProcessing: Bool = false
    @Published var processingMessage: String = ""
    @Published var agreedToTerms: Bool = false
    @Published var bookingComplete: Bool = false
    @Published var confirmationCode: String = ""
    @Published var errorMessage: String?
    
    // Payment state
    @Published var paymentSheetPresented: Bool = false
    @Published var paymentResult: PaymentResult?
    
    // MARK: - Services
    
    private let paymentService = PaymentService.shared
    private let creditService = CreditService.shared
    private let supabaseService = SimpleSupabaseService.shared
    private let errorService = ErrorHandlingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    func initializeBooking(for classItem: ClassItem) {
        selectedClass = classItem
        updatePricing()
        loadAvailableTimeSlots()
        resetToFirstStep()
    }
    
    func selectTimeSlot(_ timeSlot: TimeSlot) {
        selectedTimeSlot = timeSlot
        updatePricing()
    }
    
    func updateParticipantCount(_ count: Int) {
        participantCount = max(1, count)
        
        // Adjust participant names array
        while participantNames.count < participantCount {
            participantNames.append("")
        }
        if participantNames.count > participantCount {
            participantNames = Array(participantNames.prefix(participantCount))
        }
        
        updatePricing()
    }
    
    func toggleEquipment(_ equipment: EquipmentItem) {
        if selectedEquipment.contains(equipment) {
            selectedEquipment.remove(equipment)
        } else {
            selectedEquipment.insert(equipment)
        }
        updateEquipmentCost()
        updatePricing()
    }
    
    func applyCoupon(_ code: String) {
        // Validate and apply coupon
        if let coupon = validateCouponCode(code) {
            appliedCoupon = coupon
            updatePricing()
        } else {
            errorMessage = "Invalid coupon code"
        }
    }
    
    func selectPaymentMethod(_ method: PaymentMethodType) {
        selectedPaymentMethod = method
        updatePricing()
    }
    
    func toggleCreditUsage() {
        useCredits.toggle()
        if useCredits {
            creditsToUse = min(creditService.totalCredits, Int(totalAmount))
        } else {
            creditsToUse = 0
        }
        updatePricing()
    }
    
    func proceedToNextStep() {
        guard canProceedToNextStep else { return }
        
        switch currentStep {
        case .selectDateTime:
            currentStep = .participantDetails
        case .participantDetails:
            currentStep = .paymentMethod
        case .paymentMethod:
            currentStep = .reviewBooking
        case .reviewBooking:
            processBooking()
        case .confirmation:
            break
        }
    }
    
    func goToPreviousStep() {
        switch currentStep {
        case .selectDateTime:
            break
        case .participantDetails:
            currentStep = .selectDateTime
        case .paymentMethod:
            currentStep = .participantDetails
        case .reviewBooking:
            currentStep = .paymentMethod
        case .confirmation:
            currentStep = .reviewBooking
        }
    }
    
    func processBooking() {
        Task {
            await performBookingProcess()
        }
    }
    
    // MARK: - Computed Properties
    
    var canProceedToNextStep: Bool {
        switch currentStep {
        case .selectDateTime:
            return selectedTimeSlot != nil
        case .participantDetails:
            return participantCount > 0 && !emergencyContactName.isEmpty && !emergencyContactPhone.isEmpty
        case .paymentMethod:
            return selectedPaymentMethod != nil && (selectedPaymentMethod == .credits ? creditService.totalCredits >= creditsToUse : true)
        case .reviewBooking:
            return agreedToTerms
        case .confirmation:
            return true
        }
    }
    
    var stepTitle: String {
        switch currentStep {
        case .selectDateTime: return "Select Date & Time"
        case .participantDetails: return "Participant Details"
        case .paymentMethod: return "Payment Method"
        case .reviewBooking: return "Review Booking"
        case .confirmation: return "Booking Confirmed"
        }
    }
    
    var progressPercentage: Double {
        let stepCount = BookingStep.allCases.count
        let currentIndex = BookingStep.allCases.firstIndex(of: currentStep) ?? 0
        return Double(currentIndex + 1) / Double(stepCount)
    }
    
    var formattedSubtotal: String {
        return String(format: "$%.2f", subtotal)
    }
    
    var formattedDiscountAmount: String {
        return String(format: "-$%.2f", discountAmount)
    }
    
    var formattedProcessingFee: String {
        return String(format: "$%.2f", processingFee)
    }
    
    var formattedTotalAmount: String {
        return String(format: "$%.2f", totalAmount)
    }
    
    var formattedRemainingPayment: String {
        return String(format: "$%.2f", remainingPayment)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Observe credit service changes
        creditService.$totalCredits
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePricing()
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        // Load any initial data needed
    }
    
    private func loadAvailableTimeSlots() {
        // Mock time slots for development
        availableTimeSlots = [
            TimeSlot(id: "1", time: "09:00 AM", date: selectedDate, available: true, spotsRemaining: 5),
            TimeSlot(id: "2", time: "11:00 AM", date: selectedDate, available: true, spotsRemaining: 3),
            TimeSlot(id: "3", time: "01:00 PM", date: selectedDate, available: true, spotsRemaining: 8),
            TimeSlot(id: "4", time: "03:00 PM", date: selectedDate, available: false, spotsRemaining: 0),
            TimeSlot(id: "5", time: "05:00 PM", date: selectedDate, available: true, spotsRemaining: 2)
        ]
    }
    
    private func updateEquipmentCost() {
        equipmentCost = selectedEquipment.reduce(0) { total, equipment in
            total + equipment.price
        }
    }
    
    private func updatePricing() {
        guard let classItem = selectedClass else { return }
        
        // Parse base price from class
        let basePrice = Double(classItem.price.replacingOccurrences(of: "$", with: "")) ?? 0.0
        
        // Calculate subtotal
        subtotal = (basePrice * Double(participantCount)) + equipmentCost
        
        // Calculate discount
        if let coupon = appliedCoupon {
            discountAmount = subtotal * (Double(coupon.percentage) / 100.0)
        } else {
            discountAmount = 0.0
        }
        
        // Calculate processing fee (only for non-credit payments)
        if selectedPaymentMethod == .credits {
            processingFee = 0.0
        } else {
            processingFee = (subtotal - discountAmount) * 0.03 // 3% processing fee
        }
        
        // Calculate total
        totalAmount = subtotal - discountAmount + processingFee
        
        // Calculate remaining payment after credits
        if useCredits {
            let creditValue = Double(creditsToUse)
            remainingPayment = max(0, totalAmount - creditValue)
        } else {
            remainingPayment = totalAmount
        }
    }
    
    private func validateCouponCode(_ code: String) -> CouponCode? {
        // Mock coupon validation
        switch code.uppercased() {
        case "SAVE20":
            return CouponCode(code: "SAVE20", percentage: 20, description: "20% off your booking")
        case "FIRST10":
            return CouponCode(code: "FIRST10", percentage: 10, description: "10% off for first-time users")
        case "STUDENT15":
            return CouponCode(code: "STUDENT15", percentage: 15, description: "15% student discount")
        default:
            return nil
        }
    }
    
    private func resetToFirstStep() {
        currentStep = .selectDateTime
        bookingComplete = false
        confirmationCode = ""
        errorMessage = nil
    }
    
    private func performBookingProcess() async {
        isProcessing = true
        processingMessage = "Processing your booking..."
        errorMessage = nil
        
        do {
            // Step 1: Handle payment
            var paymentResult: PaymentResult?
            
            if selectedPaymentMethod == .credits && remainingPayment == 0 {
                // Pure credit payment
                paymentResult = try await paymentService.processCreditPayment(
                    amount: Double(creditsToUse),
                    classId: selectedClass?.id ?? "",
                    participantCount: participantCount
                )
            } else if remainingPayment > 0 {
                // Stripe payment (with or without credits)
                processingMessage = "Processing payment..."
                
                let paymentIntent = try await paymentService.createBookingPaymentIntent(
                    amount: remainingPayment,
                    classId: selectedClass?.id ?? "",
                    participantCount: participantCount
                )
                
                paymentService.configurePaymentSheet(for: paymentIntent)
                paymentResult = await paymentService.presentPaymentSheet()
            }
            
            guard let result = paymentResult, result.success else {
                throw BookingError.invalidPayment
            }
            
            // Step 2: Create booking record
            processingMessage = "Creating your booking..."
            
            let bookingRequest = createBookingRequest(paymentResult: result)
            let booking = try await createBooking(request: bookingRequest)
            
            // Step 3: Use credits if applicable
            if useCredits && creditsToUse > 0 {
                processingMessage = "Applying credits..."
                try await applyCreditPayment()
            }
            
            // Step 4: Confirm payment with backend
            if let paymentIntentId = result.paymentIntentId {
                _ = try await paymentService.confirmPayment(paymentIntentId: paymentIntentId)
            }
            
            // Success!
            confirmationCode = booking.confirmationCode
            currentStep = .confirmation
            bookingComplete = true
            
        } catch {
            errorService.handleBookingError(error, bookingContext: .paymentProcessing)
            errorMessage = errorService.getUserFriendlyMessage(for: error)
            print("❌ Booking failed: \(error)")
        }
        
        isProcessing = false
        processingMessage = ""
    }
    
    private func createBookingRequest(paymentResult: PaymentResult) -> BookingRequest {
        return BookingRequest(
            classId: selectedClass?.id ?? "",
            userId: supabaseService.currentUser?.id.uuidString ?? "",
            participantCount: participantCount,
            specialRequests: specialRequests.isEmpty ? nil : specialRequests,
            paymentId: paymentResult.paymentIntentId ?? UUID().uuidString,
            couponId: appliedCoupon?.code,
            totalAmount: totalAmount,
            paymentMethod: selectedPaymentMethod ?? .card,
            paymentIntentId: paymentResult.paymentIntentId,
            creditsUsed: useCredits ? creditsToUse : nil,
            discountApplied: discountAmount > 0 ? discountAmount : nil,
            processingFee: processingFee > 0 ? processingFee : nil,
            participantNames: participantNames.isEmpty ? nil : participantNames,
            emergencyContact: EmergencyContact(name: emergencyContactName, phone: emergencyContactPhone),
            equipmentRental: selectedEquipment.isEmpty ? nil : selectedEquipment.map { $0.name },
            experienceLevel: experienceLevel.rawValue
        )
    }
    
    private func createBooking(request: BookingRequest) async throws -> Booking {
        // This would call the Supabase function to create the booking
        // For now, return a mock booking
        return Booking(
            id: UUID().uuidString,
            classId: request.classId,
            className: selectedClass?.name ?? "",
            userId: request.userId,
            participantCount: request.participantCount,
            specialRequests: request.specialRequests,
            paymentId: request.paymentId,
            totalAmount: request.totalAmount,
            status: .confirmed,
            createdAt: Date(),
            updatedAt: Date(),
            classStartDate: selectedTimeSlot?.date ?? Date(),
            classEndDate: Calendar.current.date(byAdding: .hour, value: 2, to: selectedTimeSlot?.date ?? Date()) ?? Date(),
            venue: Venue(id: "1", name: "Test Venue", address: "123 Test St", city: "Vancouver", province: "BC", postalCode: "V6B 1A1", latitude: 49.2827, longitude: -123.1207),
            instructor: Instructor(id: "1", name: "Test Instructor", bio: "Experienced instructor", rating: 4.8, reviewCount: 120, specialties: ["Pottery"], avatar: nil),
            confirmationCode: generateConfirmationCode(),
            qrCode: nil,
            paymentMethod: request.paymentMethod,
            paymentIntentId: request.paymentIntentId,
            paidWithCredits: useCredits,
            creditsUsed: request.creditsUsed,
            discountApplied: request.discountApplied,
            processingFee: request.processingFee,
            refundableAmount: totalAmount * 0.8, // 80% refundable
            availableSpotsAtBooking: selectedTimeSlot?.spotsRemaining,
            waitlistPosition: nil,
            isWaitlisted: false,
            remindersSent: nil,
            cancellationDeadline: Calendar.current.date(byAdding: .hour, value: -24, to: selectedTimeSlot?.date ?? Date())
        )
    }
    
    private func applyCreditPayment() async throws {
        // Apply credits through credit service
        await withCheckedContinuation { continuation in
            creditService.useCredits(amount: creditsToUse, for: "Class Booking - \(selectedClass?.name ?? "")") { success in
                continuation.resume()
            }
        }
    }
    
    private func generateConfirmationCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        
        var code = ""
        
        // Add 2 letters
        for _ in 0..<2 {
            code += String(letters.randomElement()!)
        }
        
        // Add 4 numbers
        for _ in 0..<4 {
            code += String(numbers.randomElement()!)
        }
        
        return code
    }
}

// MARK: - Supporting Types

enum BookingStep: CaseIterable {
    case selectDateTime
    case participantDetails
    case paymentMethod
    case reviewBooking
    case confirmation
}

enum ExperienceLevel: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

struct TimeSlot: Identifiable, Hashable {
    let id: String
    let time: String
    let date: Date
    let available: Bool
    let spotsRemaining: Int
    
    var isFullyBooked: Bool {
        spotsRemaining <= 0
    }
    
    var displayTime: String {
        time
    }
}

struct EquipmentItem: Identifiable, Hashable {
    let id: String
    let name: String
    let price: Double
    let description: String
    
    var formattedPrice: String {
        String(format: "$%.2f", price)
    }
}

struct CouponCode: Identifiable {
    let id = UUID()
    let code: String
    let percentage: Int
    let description: String
    
    var displayText: String {
        "\(code) - \(percentage)% off"
    }
}