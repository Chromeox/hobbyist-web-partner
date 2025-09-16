import Foundation
import StripePaymentSheet
import StripeApplePay
import PassKit

class PaymentService: NSObject, PaymentServiceProtocol {
    private let supabase = SupabaseManager.shared.client
    private var paymentSheet: PaymentSheet?
    private var currentPaymentCompletion: ((Result<PaymentResult, Error>) -> Void)?
    
    override init() {
        super.init()
        configureStripe()
    }
    
    private func configureStripe() {
        // Configure Stripe with publishable key
        let stripePublishableKey = Configuration.shared.stripePublishableKey
        if !stripePublishableKey.isEmpty && !stripePublishableKey.contains("YOUR_") {
            StripeAPI.defaultPublishableKey = stripePublishableKey
        }
        
        // Configure Apple Pay
        if isApplePayAvailable() {
            StripeAPI.defaultAppleMerchantIdentifier = Configuration.shared.appleMerchantId
        }
    }
    
    // MARK: - Payment Methods
    
    func fetchPaymentMethods() async throws -> [PaymentMethod] {
        guard let supabase = supabase else { throw PaymentError.notInitialized }
        
        let response = try await supabase.database
            .from("payment_methods")
            .select("*")
            .eq("user_id", value: try await getCurrentUserId())
            .order("created_at", ascending: false)
            .execute()
        
        let methods = try response.decoded(to: [PaymentMethod].self)
        return methods
    }
    
    func addPaymentMethod(card: CardDetails) async throws -> PaymentMethod {
        guard let supabase = supabase else { throw PaymentError.notInitialized }
        
        // Create payment method with Stripe
        let response = try await supabase.functions
            .invoke("create-payment-method", options: FunctionInvokeOptions(
                body: [
                    "card": [
                        "number": card.number,
                        "exp_month": card.expiryMonth,
                        "exp_year": card.expiryYear,
                        "cvc": card.cvc
                    ],
                    "billing_details": [
                        "name": card.name,
                        "address": ["postal_code": card.postalCode]
                    ]
                ]
            ))
        
        let paymentMethod = try response.decoded(to: PaymentMethod.self)
        return paymentMethod
    }
    
    func removePaymentMethod(id: String) async throws {
        guard let supabase = supabase else { throw PaymentError.notInitialized }
        
        _ = try await supabase.functions
            .invoke("delete-payment-method", options: FunctionInvokeOptions(
                body: ["payment_method_id": id]
            ))
    }
    
    func setDefaultPaymentMethod(id: String) async throws {
        guard let supabase = supabase else { throw PaymentError.notInitialized }
        
        _ = try await supabase.database
            .from("payment_methods")
            .update(["is_default": false])
            .eq("user_id", value: try await getCurrentUserId())
            .execute()
        
        _ = try await supabase.database
            .from("payment_methods")
            .update(["is_default": true])
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Payments
    
    func processPayment(amount: Double, currency: String = "USD", description: String) async throws -> PaymentResult {
        guard let supabase = supabase else { throw PaymentError.notInitialized }
        
        let response = try await supabase.functions
            .invoke("process-payment", options: FunctionInvokeOptions(
                body: [
                    "amount": Int(amount * 100), // Convert to cents
                    "currency": currency.lowercased(),
                    "description": description
                ]
            ))
        
        let result = try response.decoded(to: PaymentResult.self)
        return result
    }
    
    func processClassBooking(classId: String, paymentMethodId: String?) async throws -> PaymentResult {
        guard let supabase = supabase else { throw PaymentError.notInitialized }
        
        let response = try await supabase.functions
            .invoke("book-class", options: FunctionInvokeOptions(
                body: [
                    "class_id": classId,
                    "payment_method_id": paymentMethodId ?? "",
                    "use_credits": paymentMethodId == nil
                ]
            ))
        
        let result = try response.decoded(to: PaymentResult.self)
        return result
    }
    
    func purchaseCreditPack(packId: String, paymentMethodId: String?) async throws -> PaymentResult {
        guard let supabase = supabase else { throw PaymentError.notInitialized }
        
        // Get credit pack details
        guard let pack = CreditPackage.packages.first(where: { $0.id == packId }) else {
            throw PaymentError.invalidCreditPack
        }
        
        let response = try await supabase.functions
            .invoke("purchase-credits", options: FunctionInvokeOptions(
                body: [
                    "pack_id": packId,
                    "amount": Int(pack.price * 100),
                    "credits": pack.credits,
                    "payment_method_id": paymentMethodId ?? ""
                ]
            ))
        
        let result = try response.decoded(to: PaymentResult.self)
        return result
    }
    
    // MARK: - Apple Pay
    
    func setupApplePay() async throws {
        // Apple Pay is configured in configureStripe()
        guard isApplePayAvailable() else {
            throw PaymentError.applePayNotAvailable
        }
    }
    
    func processApplePayment(amount: Double, description: String) async throws -> PaymentResult {
        guard isApplePayAvailable() else {
            throw PaymentError.applePayNotAvailable
        }
        
        guard let supabase = supabase else { throw PaymentError.notInitialized }
        
        // Create payment intent
        let response = try await supabase.functions
            .invoke("create-payment-intent", options: FunctionInvokeOptions(
                body: [
                    "amount": Int(amount * 100),
                    "currency": "usd",
                    "description": description,
                    "payment_method_types": ["apple_pay"]
                ]
            ))
        
        let clientSecret = try response.decoded(to: String.self)
        
        // Process with Apple Pay
        return try await withCheckedThrowingContinuation { continuation in
            processApplePayWithClientSecret(clientSecret, amount: amount, description: description) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func isApplePayAvailable() -> Bool {
        return PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amEx])
    }
    
    private func processApplePayWithClientSecret(_ clientSecret: String, amount: Double, description: String, completion: @escaping (Result<PaymentResult, Error>) -> Void) {
        // Implementation would use PKPaymentAuthorizationController
        // This is a simplified version
        let result = PaymentResult(
            id: UUID().uuidString,
            status: .succeeded,
            amount: amount,
            currency: "USD",
            description: description,
            receiptURL: nil,
            createdAt: Date()
        )
        completion(.success(result))
    }
    
    // MARK: - Stripe Payment Sheet
    
    func preparePaymentSheet(for amount: Double) async throws -> PaymentSheet.IntentConfiguration {
        guard let supabase = supabase else { throw PaymentError.notInitialized }
        
        // Create payment intent
        let response = try await supabase.functions
            .invoke("create-payment-intent", options: FunctionInvokeOptions(
                body: [
                    "amount": Int(amount * 100),
                    "currency": "usd"
                ]
            ))
        
        let data = try response.decoded(to: PaymentSheetData.self)
        
        // Configure payment sheet
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Hobbyist"
        configuration.applePay = .init(
            merchantId: "merchant.com.hobbyist.app",
            merchantCountryCode: "US"
        )
        
        // Return intent configuration
        return PaymentSheet.IntentConfiguration(
            mode: .payment(amount: Int(amount * 100), currency: "USD"),
            confirmHandler: { paymentMethod, shouldSavePaymentMethod, intentCreationCallback in
                // Handle confirmation
                intentCreationCallback(.success(data.clientSecret))
            }
        )
    }
    
    func presentPaymentSheet() async throws -> PaymentSheet.PaymentSheetResult {
        guard paymentSheet != nil else {
            throw PaymentError.paymentSheetNotConfigured
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            paymentSheet?.present(from: getCurrentViewController()) { paymentResult in
                continuation.resume(returning: paymentResult)
            }
        }
    }
    
    // MARK: - Refunds
    
    func requestRefund(paymentId: String, reason: String) async throws -> RefundResult {
        guard let supabase = supabase else { throw PaymentError.notInitialized }
        
        let response = try await supabase.functions
            .invoke("request-refund", options: FunctionInvokeOptions(
                body: [
                    "payment_id": paymentId,
                    "reason": reason
                ]
            ))
        
        let result = try response.decoded(to: RefundResult.self)
        return result
    }
    
    // MARK: - Payment History
    
    func fetchPaymentHistory() async throws -> [Transaction] {
        guard let supabase = supabase else { throw PaymentError.notInitialized }
        
        let response = try await supabase.database
            .from("transactions")
            .select("*")
            .eq("user_id", value: try await getCurrentUserId())
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
        
        let transactions = try response.decoded(to: [Transaction].self)
        return transactions
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() async throws -> String {
        guard let supabase = supabase else { throw PaymentError.notInitialized }
        
        let session = try await supabase.auth.session
        guard let userId = session?.user.id.uuidString else {
            throw PaymentError.userNotAuthenticated
        }
        
        return userId
    }
    
    private func getCurrentViewController() -> UIViewController {
        // Get the current view controller
        // This is a simplified version - in production, you'd get the actual top VC
        return UIViewController()
    }
}

// MARK: - Supporting Types

struct PaymentSheetData: Codable {
    let clientSecret: String
    let ephemeralKey: String
    let customerId: String
}

enum PaymentError: LocalizedError {
    case notInitialized
    case userNotAuthenticated
    case invalidCreditPack
    case applePayNotAvailable
    case paymentSheetNotConfigured
    case paymentFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Payment service not initialized"
        case .userNotAuthenticated:
            return "User must be authenticated to make payments"
        case .invalidCreditPack:
            return "Invalid credit pack selected"
        case .applePayNotAvailable:
            return "Apple Pay is not available on this device"
        case .paymentSheetNotConfigured:
            return "Payment sheet not configured"
        case .paymentFailed(let reason):
            return "Payment failed: \(reason)"
        }
    }
}