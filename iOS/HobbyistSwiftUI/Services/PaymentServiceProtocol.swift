import Foundation
import StripePaymentSheet
import PassKit

protocol PaymentServiceProtocol {
    // Payment Methods
    func fetchPaymentMethods() async throws -> [PaymentMethod]
    func addPaymentMethod(card: CardDetails) async throws -> PaymentMethod
    func removePaymentMethod(id: String) async throws
    func setDefaultPaymentMethod(id: String) async throws
    
    // Payments
    func processPayment(amount: Double, currency: String, description: String) async throws -> PaymentResult
    func processClassBooking(classId: String, paymentMethodId: String?) async throws -> PaymentResult
    func purchaseCreditPack(packId: String, paymentMethodId: String?) async throws -> PaymentResult
    
    // Apple Pay
    func setupApplePay() async throws
    func processApplePayment(amount: Double, description: String) async throws -> PaymentResult
    func isApplePayAvailable() -> Bool
    
    // Stripe Payment Sheet
    func preparePaymentSheet(for amount: Double) async throws -> PaymentSheet.IntentConfiguration
    func presentPaymentSheet() async throws -> PaymentSheet.PaymentSheetResult
    
    // Refunds
    func requestRefund(paymentId: String, reason: String) async throws -> RefundResult
    
    // Payment History
    func fetchPaymentHistory() async throws -> [Transaction]
}

// MARK: - Payment Models

struct PaymentMethod: Identifiable, Codable {
    let id: String
    let type: PaymentMethodType
    let last4: String
    let brand: String?
    let expiryMonth: Int?
    let expiryYear: Int?
    let isDefault: Bool
    let createdAt: Date
    
    enum PaymentMethodType: String, Codable {
        case card = "card"
        case applePay = "apple_pay"
        case bankAccount = "bank_account"
    }
}

struct CardDetails {
    let number: String
    let expiryMonth: Int
    let expiryYear: Int
    let cvc: String
    let name: String
    let postalCode: String
}

struct PaymentResult: Codable {
    let id: String
    let status: PaymentStatus
    let amount: Double
    let currency: String
    let description: String
    let receiptURL: String?
    let createdAt: Date
    
    enum PaymentStatus: String, Codable {
        case succeeded = "succeeded"
        case processing = "processing"
        case requiresAction = "requires_action"
        case failed = "failed"
        case cancelled = "cancelled"
    }
}

struct RefundResult: Codable {
    let id: String
    let paymentId: String
    let amount: Double
    let status: RefundStatus
    let reason: String
    let createdAt: Date
    
    enum RefundStatus: String, Codable {
        case pending = "pending"
        case succeeded = "succeeded"
        case failed = "failed"
        case cancelled = "cancelled"
    }
}

struct Transaction: Identifiable, Codable {
    let id: String
    let type: TransactionType
    let amount: Double
    let currency: String
    let description: String
    let status: String
    let createdAt: Date
    let relatedId: String? // Class ID, Credit Pack ID, etc.
    
    enum TransactionType: String, Codable {
        case classBooking = "class_booking"
        case creditPurchase = "credit_purchase"
        case refund = "refund"
        case subscription = "subscription"
    }
}

// MARK: - Credit Pack Models

struct CreditPack: Identifiable, Codable {
    let id: String
    let name: String
    let credits: Int
    let price: Double
    let bonusCredits: Int
    let description: String
    let validityDays: Int
    let isPopular: Bool
    
    var totalCredits: Int {
        credits + bonusCredits
    }
    
    var pricePerCredit: Double {
        price / Double(totalCredits)
    }
}

// Available Credit Packs
extension CreditPack {
    static let starter = CreditPack(
        id: "pack_starter",
        name: "Starter Pack",
        credits: 5,
        price: 25.00,
        bonusCredits: 0,
        description: "Perfect for trying out new classes",
        validityDays: 30,
        isPopular: false
    )
    
    static let value = CreditPack(
        id: "pack_value",
        name: "Value Pack",
        credits: 10,
        price: 50.00,
        bonusCredits: 2,
        description: "Most popular choice",
        validityDays: 60,
        isPopular: true
    )
    
    static let premium = CreditPack(
        id: "pack_premium",
        name: "Premium Pack",
        credits: 20,
        price: 90.00,
        bonusCredits: 5,
        description: "Best value for regular attendees",
        validityDays: 90,
        isPopular: false
    )
    
    static let all = [starter, value, premium]
}