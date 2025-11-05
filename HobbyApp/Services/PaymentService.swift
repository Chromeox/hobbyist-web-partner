import Foundation
import Combine
import PassKit
import Supabase

// MARK: - Payment Models

struct PaymentIntent: Codable {
    let id: String
    let clientSecret: String
    let amount: Int
    let currency: String
    let status: String
    let customerId: String?
    let ephemeralKeySecret: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientSecret = "client_secret"
        case amount
        case currency
        case status
        case customerId = "customer_id"
        case ephemeralKeySecret = "ephemeral_key_secret"
    }
}

struct PaymentSheetConfiguration {
    let paymentIntentClientSecret: String
    let customerId: String?
    let ephemeralKeySecret: String?
    let merchantDisplayName: String
    let allowsDelayedPaymentMethods: Bool
    
    init(paymentIntent: PaymentIntent, merchantDisplayName: String = "HobbyApp") {
        self.paymentIntentClientSecret = paymentIntent.clientSecret
        self.customerId = paymentIntent.customerId
        self.ephemeralKeySecret = paymentIntent.ephemeralKeySecret
        self.merchantDisplayName = merchantDisplayName
        self.allowsDelayedPaymentMethods = false
    }
}

struct PaymentResult {
    let success: Bool
    let paymentIntentId: String?
    let error: PaymentError?
    let paymentMethod: PaymentMethodType?
}

enum PaymentMethodType: String, Codable {
    case card = "card"
    case applePay = "apple_pay" 
    case credits = "credits"
    case bankTransfer = "bank_transfer"
}

enum PaymentError: LocalizedError {
    case userCancelled
    case networkError(String)
    case paymentFailed(String)
    case invalidAmount
    case insufficientCredits
    case stripeConfigurationError
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Payment was cancelled"
        case .networkError(let message):
            return "Network error: \(message)"
        case .paymentFailed(let message):
            return "Payment failed: \(message)"
        case .invalidAmount:
            return "Invalid payment amount"
        case .insufficientCredits:
            return "Insufficient credits for this purchase"
        case .stripeConfigurationError:
            return "Payment system configuration error"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Payment Service

@MainActor
final class PaymentService: ObservableObject {
    static let shared = PaymentService()
    
    @Published var isProcessingPayment = false
    @Published var paymentSheetConfiguration: PaymentSheetConfiguration?
    @Published var lastPaymentResult: PaymentResult?
    @Published var publishableKey: String?
    
    private let supabaseService = SimpleSupabaseService.shared
    private let creditService = CreditService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadStripeConfiguration()
    }
    
    // MARK: - Public Methods
    
    /// Create payment intent for booking
    func createBookingPaymentIntent(
        amount: Double,
        currency: String = "cad",
        classId: String,
        participantCount: Int
    ) async throws -> PaymentIntent {
        guard let userId = supabaseService.currentUser?.id else {
            throw PaymentError.networkError("User not authenticated")
        }
        
        let amountCents = Int(amount * 100) // Convert to cents
        
        let request = CreatePaymentIntentRequest(
            amount: amountCents,
            currency: currency,
            classId: classId,
            participantCount: participantCount,
            userId: userId.uuidString
        )
        
        do {
            let response: CreatePaymentIntentResponse = try await supabaseService.client
                .functions
                .invoke("payments", with: request)
            
            guard response.success else {
                throw PaymentError.paymentFailed(response.error ?? "Failed to create payment intent")
            }
            
            return PaymentIntent(
                id: response.paymentIntentId,
                clientSecret: response.clientSecret,
                amount: amountCents,
                currency: currency,
                status: "requires_payment_method",
                customerId: response.customerId,
                ephemeralKeySecret: response.ephemeralKeySecret
            )
            
        } catch {
            print("⚠️ Failed to create payment intent: \(error)")
            throw PaymentError.networkError(error.localizedDescription)
        }
    }
    
    /// Process credit payment (no Stripe involved)
    func processCreditPayment(
        amount: Double,
        classId: String,
        participantCount: Int
    ) async throws -> PaymentResult {
        guard creditService.totalCredits >= Int(amount) else {
            throw PaymentError.insufficientCredits
        }
        
        isProcessingPayment = true
        defer { isProcessingPayment = false }
        
        // Use credits via CreditService
        return await withCheckedContinuation { continuation in
            creditService.useCredits(amount: Int(amount), for: "Class Booking") { success in
                if success {
                    let result = PaymentResult(
                        success: true,
                        paymentIntentId: "credit_payment_\(UUID().uuidString)",
                        error: nil,
                        paymentMethod: .credits
                    )
                    continuation.resume(returning: result)
                } else {
                    let result = PaymentResult(
                        success: false,
                        paymentIntentId: nil,
                        error: .insufficientCredits,
                        paymentMethod: nil
                    )
                    continuation.resume(returning: result)
                }
            }
        }
    }
    
    /// Configure Stripe payment sheet
    func configurePaymentSheet(for paymentIntent: PaymentIntent) {
        paymentSheetConfiguration = PaymentSheetConfiguration(
            paymentIntent: paymentIntent,
            merchantDisplayName: "HobbyApp"
        )
    }
    
    /// Present native payment sheet (mock implementation for now)
    func presentPaymentSheet() async -> PaymentResult {
        guard let config = paymentSheetConfiguration else {
            return PaymentResult(
                success: false,
                paymentIntentId: nil,
                error: .stripeConfigurationError,
                paymentMethod: nil
            )
        }
        
        isProcessingPayment = true
        defer { isProcessingPayment = false }
        
        // Simulate payment processing
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Mock successful payment for development
        let result = PaymentResult(
            success: true,
            paymentIntentId: extractPaymentIntentId(from: config.paymentIntentClientSecret),
            error: nil,
            paymentMethod: .card
        )
        
        lastPaymentResult = result
        return result
    }
    
    /// Confirm payment completion with backend
    func confirmPayment(paymentIntentId: String) async throws -> Bool {
        let request = ConfirmPaymentRequest(paymentIntentId: paymentIntentId)
        
        do {
            let response: ConfirmPaymentResponse = try await supabaseService.client
                .functions
                .invoke("payments", with: request)
            
            return response.success
            
        } catch {
            print("⚠️ Failed to confirm payment: \(error)")
            throw PaymentError.networkError(error.localizedDescription)
        }
    }
    
    /// Check if Apple Pay is available
    var isApplePayAvailable: Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }
    
    /// Check if user has sufficient credits
    func hasSufficientCredits(for amount: Double) -> Bool {
        creditService.totalCredits >= Int(amount)
    }
    
    // MARK: - Private Methods
    
    private func loadStripeConfiguration() {
        // In a real implementation, this would load from secure configuration
        // For now, this is a placeholder
        publishableKey = "pk_test_placeholder"
    }
    
    private func extractPaymentIntentId(from clientSecret: String) -> String {
        // Extract payment intent ID from client secret
        let components = clientSecret.components(separatedBy: "_secret_")
        return components.first ?? clientSecret
    }
}

// MARK: - Request/Response Models

private struct CreatePaymentIntentRequest: Codable {
    let action = "create_payment_intent"
    let amount: Int
    let currency: String
    let classId: String
    let participantCount: Int
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case action
        case amount
        case currency
        case classId = "class_id"
        case participantCount = "participant_count"
        case userId = "user_id"
    }
}

private struct CreatePaymentIntentResponse: Codable {
    let success: Bool
    let paymentIntentId: String
    let clientSecret: String
    let customerId: String?
    let ephemeralKeySecret: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case paymentIntentId = "payment_intent_id"
        case clientSecret = "client_secret"
        case customerId = "customer_id"
        case ephemeralKeySecret = "ephemeral_key_secret"
        case error
    }
}

private struct ConfirmPaymentRequest: Codable {
    let action = "confirm_payment"
    let paymentIntentId: String
    
    enum CodingKeys: String, CodingKey {
        case action
        case paymentIntentId = "payment_intent_id"
    }
}

private struct ConfirmPaymentResponse: Codable {
    let success: Bool
    let error: String?
}

// MARK: - Apple Pay Support

extension PaymentService {
    /// Create Apple Pay request for booking
    func createApplePayRequest(
        for amount: Double,
        currency: String = "CAD",
        classTitle: String
    ) -> PKPaymentRequest? {
        guard isApplePayAvailable else { return nil }
        
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.hobbyapp" // Configure in capabilities
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.supportedCountries = Set(["CA", "US"])
        request.merchantCapabilities = .capability3DS
        request.countryCode = "CA"
        request.currencyCode = currency
        
        let classItem = PKPaymentSummaryItem(
            label: classTitle,
            amount: NSDecimalNumber(value: amount)
        )
        
        let total = PKPaymentSummaryItem(
            label: "HobbyApp",
            amount: NSDecimalNumber(value: amount)
        )
        
        request.paymentSummaryItems = [classItem, total]
        return request
    }
    
    /// Process Apple Pay payment
    func processApplePayPayment(
        payment: PKPayment,
        for amount: Double,
        classId: String,
        participantCount: Int
    ) async throws -> PaymentResult {
        isProcessingPayment = true
        defer { isProcessingPayment = false }
        
        // Convert payment token to payment intent
        // This would integrate with Stripe's Apple Pay handling
        
        // Mock implementation for now
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        let result = PaymentResult(
            success: true,
            paymentIntentId: "pi_applepay_\(UUID().uuidString)",
            error: nil,
            paymentMethod: .applePay
        )
        
        lastPaymentResult = result
        return result
    }
}