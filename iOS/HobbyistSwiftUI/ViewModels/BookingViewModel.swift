import Foundation
import Combine

@MainActor
class BookingViewModel: ObservableObject {
    @Published var selectedClass: HobbyClass?
    @Published var bookingState: BookingState = .idle
    @Published var participantCount: Int = 1
    @Published var specialRequests: String = ""
    @Published var paymentMethod: PaymentMethod = .creditCard
    @Published var appliedCoupon: Coupon?
    @Published var errorMessage: String?
    @Published var currentStep: BookingStep = .selectParticipants
    @Published var userBookings: [Booking] = []
    @Published var upcomingBookings: [Booking] = []
    @Published var pastBookings: [Booking] = []
    @Published var isProcessingPayment: Bool = false
    
    private let bookingService: BookingService
    private let paymentService: PaymentService
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    enum BookingState {
        case idle
        case reviewing
        case processing
        case confirmed(Booking)
        case failed(Error)
    }
    
    enum BookingStep: Int, CaseIterable {
        case selectParticipants = 0
        case addDetails = 1
        case selectPayment = 2
        case review = 3
        case confirmation = 4
        
        var title: String {
            switch self {
            case .selectParticipants: return "Participants"
            case .addDetails: return "Details"
            case .selectPayment: return "Payment"
            case .review: return "Review"
            case .confirmation: return "Confirmation"
            }
        }
        
        var isCompleted: Bool {
            return self.rawValue < BookingStep.confirmation.rawValue
        }
    }
    
    init(
        bookingService: BookingService = BookingService.shared,
        paymentService: PaymentService = PaymentService.shared,
        authService: AuthenticationService = AuthenticationService.shared
    ) {
        self.bookingService = bookingService
        self.paymentService = paymentService
        self.authService = authService
        setupBindings()
        Task { await loadUserBookings() }
    }
    
    private func setupBindings() {
        // Listen for booking updates
        bookingService.bookingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bookings in
                self?.updateBookingLists(bookings)
            }
            .store(in: &cancellables)
    }
    
    func startBooking(for hobbyClass: HobbyClass) {
        selectedClass = hobbyClass
        bookingState = .reviewing
        currentStep = .selectParticipants
        participantCount = 1
        specialRequests = ""
        appliedCoupon = nil
        errorMessage = nil
    }
    
    func proceedToNextStep() {
        guard let nextStep = BookingStep(rawValue: currentStep.rawValue + 1) else { return }
        
        // Validate current step before proceeding
        if validateCurrentStep() {
            currentStep = nextStep
            
            // If moving to confirmation, process the booking
            if nextStep == .confirmation {
                Task { await processBooking() }
            }
        }
    }
    
    func goToPreviousStep() {
        guard let previousStep = BookingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = previousStep
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case .selectParticipants:
            guard let selectedClass = selectedClass else {
                errorMessage = "Please select a class"
                return false
            }
            
            if participantCount < 1 {
                errorMessage = "At least one participant is required"
                return false
            }
            
            if participantCount > selectedClass.availableSpots {
                errorMessage = "Not enough spots available"
                return false
            }
            
            return true
            
        case .addDetails:
            // Special requests are optional
            return true
            
        case .selectPayment:
            // Payment method is always selected
            return true
            
        case .review:
            // All previous steps validated
            return true
            
        case .confirmation:
            // Already at confirmation
            return true
        }
    }
    
    func processBooking() async {
        guard let selectedClass = selectedClass,
              let currentUser = authService.currentUser else {
            errorMessage = "Missing required information"
            return
        }
        
        bookingState = .processing
        isProcessingPayment = true
        errorMessage = nil
        
        do {
            // Calculate total price
            let subtotal = selectedClass.price * Double(participantCount)
            let discount = appliedCoupon?.discountAmount(for: subtotal) ?? 0
            let total = subtotal - discount
            
            // Process payment
            let paymentResult = try await paymentService.processPayment(
                amount: total,
                method: paymentMethod,
                userId: currentUser.id
            )
            
            // Create booking
            let bookingRequest = BookingRequest(
                classId: selectedClass.id,
                userId: currentUser.id,
                participantCount: participantCount,
                specialRequests: specialRequests.isEmpty ? nil : specialRequests,
                paymentId: paymentResult.paymentId,
                couponId: appliedCoupon?.id,
                totalAmount: total
            )
            
            let booking = try await bookingService.createBooking(bookingRequest)
            
            // Send confirmation email
            try await bookingService.sendConfirmationEmail(for: booking)
            
            bookingState = .confirmed(booking)
            currentStep = .confirmation
            
            // Clear selection
            selectedClass = nil
            
            // Reload bookings
            await loadUserBookings()
            
        } catch {
            bookingState = .failed(error)
            errorMessage = handleBookingError(error)
        }
        
        isProcessingPayment = false
    }
    
    func cancelBooking(_ booking: Booking) async {
        errorMessage = nil
        
        do {
            try await bookingService.cancelBooking(bookingId: booking.id)
            
            // Process refund if applicable
            if booking.canBeRefunded {
                try await paymentService.processRefund(
                    paymentId: booking.paymentId,
                    amount: booking.refundAmount
                )
            }
            
            // Reload bookings
            await loadUserBookings()
            
        } catch {
            errorMessage = "Failed to cancel booking: \(error.localizedDescription)"
        }
    }
    
    func loadUserBookings() async {
        guard let userId = authService.currentUser?.id else { return }
        
        do {
            userBookings = try await bookingService.fetchUserBookings(userId: userId)
            updateBookingLists(userBookings)
        } catch {
            errorMessage = "Failed to load bookings: \(error.localizedDescription)"
        }
    }
    
    private func updateBookingLists(_ bookings: [Booking]) {
        let now = Date()
        upcomingBookings = bookings
            .filter { $0.classStartDate > now && $0.status != .cancelled }
            .sorted { $0.classStartDate < $1.classStartDate }
        
        pastBookings = bookings
            .filter { $0.classStartDate <= now || $0.status == .cancelled }
            .sorted { $0.classStartDate > $1.classStartDate }
    }
    
    func applyCoupon(code: String) async {
        errorMessage = nil
        
        do {
            appliedCoupon = try await paymentService.validateCoupon(code: code)
        } catch {
            errorMessage = "Invalid coupon code"
            appliedCoupon = nil
        }
    }
    
    func removeCoupon() {
        appliedCoupon = nil
    }
    
    var totalPrice: Double {
        guard let selectedClass = selectedClass else { return 0 }
        let subtotal = selectedClass.price * Double(participantCount)
        let discount = appliedCoupon?.discountAmount(for: subtotal) ?? 0
        return subtotal - discount
    }
    
    var savings: Double {
        guard let selectedClass = selectedClass else { return 0 }
        let subtotal = selectedClass.price * Double(participantCount)
        return appliedCoupon?.discountAmount(for: subtotal) ?? 0
    }
    
    private func handleBookingError(_ error: Error) -> String {
        if let bookingError = error as? BookingError {
            switch bookingError {
            case .classFullyBooked:
                return "This class is fully booked"
            case .invalidPayment:
                return "Payment processing failed. Please try again"
            case .userNotAuthenticated:
                return "Please sign in to complete your booking"
            case .bookingNotFound:
                return "Booking not found"
            case .cancellationNotAllowed:
                return "This booking cannot be cancelled"
            case .networkError:
                return "Network error. Please check your connection"
            case .unknown(let message):
                return message
            }
        }
        return error.localizedDescription
    }
}

// MARK: - Supporting Models
struct Booking: Identifiable, Codable {
    let id: String
    let classId: String
    let className: String
    let userId: String
    let participantCount: Int
    let specialRequests: String?
    let paymentId: String
    let totalAmount: Double
    let status: BookingStatus
    let createdAt: Date
    let classStartDate: Date
    let classEndDate: Date
    let venue: Venue
    let instructor: Instructor
    
    var canBeCancelled: Bool {
        status == .confirmed && classStartDate.timeIntervalSinceNow > 24 * 60 * 60
    }
    
    var canBeRefunded: Bool {
        canBeCancelled
    }
    
    var refundAmount: Double {
        guard canBeRefunded else { return 0 }
        let hoursUntilClass = classStartDate.timeIntervalSinceNow / 3600
        
        if hoursUntilClass > 72 {
            return totalAmount // Full refund
        } else if hoursUntilClass > 48 {
            return totalAmount * 0.75 // 75% refund
        } else {
            return totalAmount * 0.5 // 50% refund
        }
    }
}

struct BookingRequest: Codable {
    let classId: String
    let userId: String
    let participantCount: Int
    let specialRequests: String?
    let paymentId: String
    let couponId: String?
    let totalAmount: Double
}

struct Coupon: Identifiable, Codable {
    let id: String
    let code: String
    let discountType: DiscountType
    let discountValue: Double
    let minimumAmount: Double?
    let expiryDate: Date
    
    enum DiscountType: String, Codable {
        case percentage
        case fixed
    }
    
    func discountAmount(for subtotal: Double) -> Double {
        guard subtotal >= (minimumAmount ?? 0) else { return 0 }
        
        switch discountType {
        case .percentage:
            return subtotal * (discountValue / 100)
        case .fixed:
            return min(discountValue, subtotal)
        }
    }
}

enum BookingStatus: String, Codable {
    case pending
    case confirmed
    case cancelled
    case completed
}

enum PaymentMethod: String, CaseIterable, Codable {
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case applePay = "Apple Pay"
    case paypal = "PayPal"
}

enum BookingError: Error {
    case classFullyBooked
    case invalidPayment
    case userNotAuthenticated
    case bookingNotFound
    case cancellationNotAllowed
    case networkError
    case unknown(String)
}