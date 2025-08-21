import Foundation
import StripePaymentSheet
import PassKit
import Combine

// MARK: - Stripe Payment Service
@MainActor
class StripePaymentService: ObservableObject {
    static let shared = StripePaymentService()
    
    // Published states
    @Published var paymentSheet: PaymentSheet?
    @Published var isProcessing = false
    @Published var paymentResult: PaymentResult?
    @Published var savedCards: [SavedCard] = []
    
    // Apple Pay
    private var applePayContext: STPApplePayContext?
    
    // Configuration
    private let backendUrl = "https://mcjqvdzdhtcvbrejvrtp.supabase.co/functions/v1"
    private var publishableKey: String {
        // In production, fetch from secure configuration
        return ProcessInfo.processInfo.environment["STRIPE_PUBLISHABLE_KEY"] ?? ""
    }
    
    init() {
        configureStripe()
        loadSavedPaymentMethods()
    }
    
    // MARK: - Configuration
    
    private func configureStripe() {
        StripeAPI.defaultPublishableKey = publishableKey
        
        // Configure Apple Pay
        let merchantId = "merchant.com.hobbyist.app"
        let companyName = "HobbyistSwiftUI"
        
        if StripeAPI.deviceSupportsApplePay() {
            // Apple Pay is available
            print("Apple Pay is available on this device")
        }
    }
    
    // MARK: - Payment Intent
    
    func createPaymentIntent(
        amount: Double,
        classId: String,
        userId: String,
        participantCount: Int
    ) async throws -> PaymentIntentResponse {
        
        let url = URL(string: "\(backendUrl)/create-payment-intent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get Supabase auth token
        if let token = try? await SupabaseManager.shared.client.auth.session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = [
            "amount": Int(amount * 100), // Convert to cents
            "currency": "usd",
            "metadata": [
                "class_id": classId,
                "user_id": userId,
                "participant_count": String(participantCount)
            ]
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PaymentError.serverError
        }
        
        return try JSONDecoder().decode(PaymentIntentResponse.self, from: data)
    }
    
    // MARK: - Payment Sheet
    
    func preparePaymentSheet(
        for amount: Double,
        classId: String,
        className: String
    ) async throws {
        isProcessing = true
        
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
            throw PaymentError.authRequired
        }
        
        // Create payment intent
        let paymentIntent = try await createPaymentIntent(
            amount: amount,
            classId: classId,
            userId: userId.uuidString,
            participantCount: 1
        )
        
        // Configure payment sheet
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "HobbyistSwiftUI"
        configuration.returnURL = "hobbyist://payment-return"
        
        // Enable Apple Pay
        configuration.applePay = .init(
            merchantId: "merchant.com.hobbyist.app",
            merchantCountryCode: "US"
        )
        
        // Customer configuration
        if let customerId = paymentIntent.customerId,
           let customerEphemeralKey = paymentIntent.ephemeralKey {
            configuration.customer = .init(
                id: customerId,
                ephemeralKeySecret: customerEphemeralKey
            )
        }
        
        // Allow saving cards
        configuration.allowsDelayedPaymentMethods = true
        configuration.savePaymentMethodOptInBehavior = .automatic
        
        // Create payment sheet
        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: paymentIntent.clientSecret,
            configuration: configuration
        )
        
        isProcessing = false
    }
    
    func presentPaymentSheet(from viewController: UIViewController) async -> PaymentResult {
        guard let paymentSheet = paymentSheet else {
            return .failed(error: PaymentError.notPrepared)
        }
        
        return await withCheckedContinuation { continuation in
            paymentSheet.present(from: viewController) { result in
                switch result {
                case .completed:
                    continuation.resume(returning: .success)
                    Task {
                        await self.handleSuccessfulPayment()
                    }
                case .canceled:
                    continuation.resume(returning: .canceled)
                case .failed(let error):
                    continuation.resume(returning: .failed(error: error))
                }
            }
        }
    }
    
    // MARK: - Apple Pay
    
    func processApplePayPayment(
        for amount: Double,
        classId: String,
        className: String,
        from viewController: UIViewController
    ) async throws {
        
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
            throw PaymentError.authRequired
        }
        
        // Create payment intent first
        let paymentIntent = try await createPaymentIntent(
            amount: amount,
            classId: classId,
            userId: userId.uuidString,
            participantCount: 1
        )
        
        // Configure Apple Pay request
        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: "merchant.com.hobbyist.app",
            country: "US",
            currency: "USD"
        )
        
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(
                label: className,
                amount: NSDecimalNumber(value: amount),
                type: .final
            ),
            PKPaymentSummaryItem(
                label: "HobbyistSwiftUI",
                amount: NSDecimalNumber(value: amount),
                type: .final
            )
        ]
        
        paymentRequest.requiredBillingContactFields = [.emailAddress]
        
        // Create Apple Pay context
        guard let applePayContext = STPApplePayContext(
            paymentRequest: paymentRequest,
            delegate: self
        ) else {
            throw PaymentError.applePayNotAvailable
        }
        
        self.applePayContext = applePayContext
        
        // Present Apple Pay sheet
        applePayContext.presentApplePay(from: viewController)
    }
    
    // MARK: - Saved Payment Methods
    
    func loadSavedPaymentMethods() {
        Task {
            guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                return
            }
            
            do {
                let response = try await fetchSavedPaymentMethods(for: userId.uuidString)
                self.savedCards = response.paymentMethods.map { method in
                    SavedCard(
                        id: method.id,
                        brand: method.card?.brand ?? "Card",
                        last4: method.card?.last4 ?? "****"
                    )
                }
            } catch {
                print("Failed to load saved payment methods: \(error)")
            }
        }
    }
    
    private func fetchSavedPaymentMethods(for userId: String) async throws -> PaymentMethodsResponse {
        let url = URL(string: "\(backendUrl)/list-payment-methods")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = try? await SupabaseManager.shared.client.auth.session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["user_id": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(PaymentMethodsResponse.self, from: data)
    }
    
    func processPaymentWithSavedCard(
        cardId: String,
        amount: Double,
        classId: String
    ) async throws {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
            throw PaymentError.authRequired
        }
        
        let url = URL(string: "\(backendUrl)/charge-saved-card")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = try? await SupabaseManager.shared.client.auth.session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = [
            "payment_method_id": cardId,
            "amount": Int(amount * 100),
            "class_id": classId,
            "user_id": userId.uuidString
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PaymentError.paymentFailed
        }
        
        await handleSuccessfulPayment()
    }
    
    // MARK: - Payment Completion
    
    private func handleSuccessfulPayment() async {
        // Update UI
        paymentResult = .success
        
        // Trigger haptic feedback
        await MainActor.run {
            HapticFeedbackService.shared.playPaymentSuccess()
        }
        
        // Send confirmation notification
        await sendPaymentConfirmationNotification()
    }
    
    private func sendPaymentConfirmationNotification() async {
        // This would typically be handled by your backend
        // For now, we'll schedule a local notification
        let content = UNMutableNotificationContent()
        content.title = "Payment Successful!"
        content.body = "Your class has been booked. Check your email for details."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Refunds
    
    func requestRefund(for bookingId: String, reason: String) async throws {
        let url = URL(string: "\(backendUrl)/request-refund")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = try? await SupabaseManager.shared.client.auth.session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = [
            "booking_id": bookingId,
            "reason": reason
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PaymentError.refundFailed
        }
    }
}

// MARK: - Apple Pay Delegate

extension StripePaymentService: STPApplePayContextDelegate {
    
    func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod,
        paymentInformation: PKPayment,
        completion: @escaping STPIntentClientSecretCompletionBlock
    ) {
        // This is called when Apple Pay creates a payment method
        // You would typically send this to your backend to confirm the payment
        Task {
            do {
                // For now, we'll use the existing payment intent
                // In production, you'd create a new one with the payment method
                if let paymentSheet = self.paymentSheet {
                    completion(paymentSheet.intentConfiguration.intentClientSecret, nil)
                } else {
                    completion(nil, PaymentError.notPrepared)
                }
            }
        }
    }
    
    func applePayContext(
        _ context: STPApplePayContext,
        didCompleteWith status: STPApplePayContext.PaymentStatus,
        error: Error?
    ) {
        switch status {
        case .success:
            Task {
                await handleSuccessfulPayment()
            }
            paymentResult = .success
        case .error:
            paymentResult = .failed(error: error ?? PaymentError.unknown)
        case .userCancellation:
            paymentResult = .canceled
        @unknown default:
            paymentResult = .failed(error: PaymentError.unknown)
        }
    }
}

// MARK: - Models

struct PaymentIntentResponse: Codable {
    let clientSecret: String
    let customerId: String?
    let ephemeralKey: String?
}

struct PaymentMethodsResponse: Codable {
    let paymentMethods: [PaymentMethod]
    
    struct PaymentMethod: Codable {
        let id: String
        let card: Card?
        
        struct Card: Codable {
            let brand: String
            let last4: String
        }
    }
}

enum PaymentResult {
    case success
    case canceled
    case failed(error: Error)
}

enum PaymentError: LocalizedError {
    case authRequired
    case serverError
    case notPrepared
    case applePayNotAvailable
    case paymentFailed
    case refundFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .authRequired:
            return "Please sign in to continue"
        case .serverError:
            return "Server error occurred"
        case .notPrepared:
            return "Payment not prepared"
        case .applePayNotAvailable:
            return "Apple Pay is not available"
        case .paymentFailed:
            return "Payment failed"
        case .refundFailed:
            return "Refund request failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}