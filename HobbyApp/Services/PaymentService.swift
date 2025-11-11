import Foundation
import Combine
import PassKit
import Supabase

// ============================================================================
// PAYMENT SERVICE - TEMPORARILY DISABLED
// ============================================================================
// This service requires Stripe SDK which is causing build issues.
// For alpha testing, use credits-only system (StoreKit for credit packs).
// Re-enable this when you're ready to accept direct card payments.
// ============================================================================

// MARK: - Payment Models (Stubbed)

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
    let paymentMethod: String? // Using String instead of enum to avoid conflicts
}

// PaymentMethodType moved to Models/Booking.swift to avoid duplicate definition

enum PaymentError: LocalizedError {
    case cancelled
    case failed(String)
    case networkError
    case invalidAmount
    case configurationError

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Payment was cancelled"
        case .failed(let message):
            return "Payment failed: \(message)"
        case .networkError:
            return "Network error occurred"
        case .invalidAmount:
            return "Invalid payment amount"
        case .configurationError:
            return "Payment configuration error"
        }
    }
}

// MARK: - Payment Service (Stubbed)

final class PaymentService: ObservableObject {
    static let shared = PaymentService()

    @Published var isProcessingPayment = false
    @Published var paymentSheetConfiguration: PaymentSheetConfiguration?
    @Published var lastPaymentResult: PaymentResult?
    @Published var publishableKey: String?

    private init() {
        print("⚠️ PaymentService initialized but Stripe is disabled - use credits only")
    }

    // Stubbed method - returns error
    func processPayment(amount: Int, currency: String = "usd") async -> PaymentResult {
        print("⚠️ Direct card payments disabled - use credits instead")
        return PaymentResult(
            success: false,
            paymentIntentId: nil,
            error: .configurationError,
            paymentMethod: nil
        )
    }
}
