import Foundation
import StoreKit

// MARK: - Apple Pay Product Configuration
// Matches our Vancouver-based pricing model with Stripe products

enum ProductIdentifier: String, CaseIterable {
    // Credit Packages (One-time purchases)
    case starter = "com.hobbyist.app.credits.starter"        // 10 credits for $25
    case explorer = "com.hobbyist.app.credits.explorer"      // 25 credits for $55
    case regular = "com.hobbyist.app.credits.regular"        // 50 credits for $95
    case enthusiast = "com.hobbyist.app.credits.enthusiast"  // 100 credits for $170
    case power = "com.hobbyist.app.credits.power"           // 200 credits for $300
    
    // Subscriptions (Auto-renewable)
    case casualSub = "com.hobbyist.app.subscription.casual"    // $39/month for 20 credits
    case activeSub = "com.hobbyist.app.subscription.active"    // $69/month for 40 credits
    case premiumSub = "com.hobbyist.app.subscription.premium"  // $119/month for 80 credits
    case eliteSub = "com.hobbyist.app.subscription.elite"      // $179/month for 150 credits
    
    // Insurance Plans (Auto-renewable)
    case basicInsurance = "com.hobbyist.app.insurance.basic"     // $3/month
    case plusInsurance = "com.hobbyist.app.insurance.plus"       // $5/month
    case premiumInsurance = "com.hobbyist.app.insurance.premium" // $8/month
    
    var isSubscription: Bool {
        switch self {
        case .casualSub, .activeSub, .premiumSub, .eliteSub,
             .basicInsurance, .plusInsurance, .premiumInsurance:
            return true
        default:
            return false
        }
    }
    
    var productType: ProductType {
        switch self {
        case .starter, .explorer, .regular, .enthusiast, .power:
            return .creditPackage
        case .casualSub, .activeSub, .premiumSub, .eliteSub:
            return .subscription
        case .basicInsurance, .plusInsurance, .premiumInsurance:
            return .insurance
        }
    }
}

enum ProductType {
    case creditPackage
    case subscription
    case insurance
}

// MARK: - Product Details

struct ProductDetails {
    let identifier: ProductIdentifier
    let name: String
    let description: String
    let credits: Int
    let price: Decimal
    let savings: Int?
    let isPopular: Bool
    let metadata: [String: String]
    
    static let allProducts: [ProductDetails] = [
        // Credit Packages
        ProductDetails(
            identifier: .starter,
            name: "Starter Pack",
            description: "Perfect for trying out",
            credits: 10,
            price: 25.00,
            savings: nil,
            isPopular: false,
            metadata: ["stripe_product_id": "hobbyist_credit_starter"]
        ),
        ProductDetails(
            identifier: .explorer,
            name: "Explorer Pack",
            description: "1-2 classes per week",
            credits: 25,
            price: 55.00,
            savings: 12,
            isPopular: false,
            metadata: ["stripe_product_id": "hobbyist_credit_explorer"]
        ),
        ProductDetails(
            identifier: .regular,
            name: "Regular Pack",
            description: "Most popular choice",
            credits: 50,
            price: 95.00,
            savings: 24,
            isPopular: true,
            metadata: ["stripe_product_id": "hobbyist_credit_regular"]
        ),
        ProductDetails(
            identifier: .enthusiast,
            name: "Enthusiast Pack",
            description: "4-5 classes per week",
            credits: 100,
            price: 170.00,
            savings: 32,
            isPopular: false,
            metadata: ["stripe_product_id": "hobbyist_credit_enthusiast"]
        ),
        ProductDetails(
            identifier: .power,
            name: "Power User Pack",
            description: "Best value for daily users",
            credits: 200,
            price: 300.00,
            savings: 40,
            isPopular: false,
            metadata: ["stripe_product_id": "hobbyist_credit_power"]
        ),
        
        // Subscriptions
        ProductDetails(
            identifier: .casualSub,
            name: "Casual Membership",
            description: "20 credits/month",
            credits: 20,
            price: 39.00,
            savings: nil,
            isPopular: false,
            metadata: ["stripe_product_id": "hobbyist_sub_casual", "rollover": "5"]
        ),
        ProductDetails(
            identifier: .activeSub,
            name: "Active Membership",
            description: "40 credits/month + Priority",
            credits: 40,
            price: 69.00,
            savings: nil,
            isPopular: true,
            metadata: ["stripe_product_id": "hobbyist_sub_active", "rollover": "10"]
        ),
        ProductDetails(
            identifier: .premiumSub,
            name: "Premium Membership",
            description: "80 credits/month + All perks",
            credits: 80,
            price: 119.00,
            savings: nil,
            isPopular: false,
            metadata: ["stripe_product_id": "hobbyist_sub_premium", "rollover": "20"]
        ),
        ProductDetails(
            identifier: .eliteSub,
            name: "Elite Membership",
            description: "150 credits/month + VIP",
            credits: 150,
            price: 179.00,
            savings: nil,
            isPopular: false,
            metadata: ["stripe_product_id": "hobbyist_sub_elite", "rollover": "30"]
        ),
        
        // Insurance Plans
        ProductDetails(
            identifier: .basicInsurance,
            name: "Basic Credit Insurance",
            description: "Credits rollover 1 extra month",
            credits: 0,
            price: 3.00,
            savings: nil,
            isPopular: false,
            metadata: ["stripe_product_id": "hobbyist_insurance_basic"]
        ),
        ProductDetails(
            identifier: .plusInsurance,
            name: "Plus Credit Insurance",
            description: "Unlimited rollover & gifting",
            credits: 0,
            price: 5.00,
            savings: nil,
            isPopular: false,
            metadata: ["stripe_product_id": "hobbyist_insurance_plus"]
        ),
        ProductDetails(
            identifier: .premiumInsurance,
            name: "Premium Credit Insurance",
            description: "Everything + priority & gift cards",
            credits: 0,
            price: 8.00,
            savings: nil,
            isPopular: false,
            metadata: ["stripe_product_id": "hobbyist_insurance_premium"]
        )
    ]
    
    static func details(for identifier: ProductIdentifier) -> ProductDetails? {
        return allProducts.first { $0.identifier == identifier }
    }
}

// MARK: - StoreKit Configuration

struct StoreKitConfiguration {
    static let sharedSecret = ProcessInfo.processInfo.environment["APP_STORE_CONNECT_SHARED_SECRET"] ?? ""
    static let verifyReceiptURL = "https://mcjqvdzdhtcvbrejvrtp.supabase.co/functions/v1/verify-receipt"
    
    // Group identifiers for subscriptions
    static let subscriptionGroupID = "21483657" // Your App Store Connect group ID
    static let insuranceGroupID = "21483658"    // Separate group for insurance
    
    // Promotional offers
    static let introductoryOffers: [ProductIdentifier: IntroductoryOffer] = [
        .casualSub: IntroductoryOffer(type: .freeTrial, duration: 7),
        .activeSub: IntroductoryOffer(type: .freeTrial, duration: 7),
        .premiumSub: IntroductoryOffer(type: .payAsYouGo, duration: 30, price: 59.00),
        .eliteSub: IntroductoryOffer(type: .payAsYouGo, duration: 30, price: 89.00)
    ]
}

struct IntroductoryOffer {
    enum OfferType {
        case freeTrial
        case payAsYouGo
        case payUpFront
    }
    
    let type: OfferType
    let duration: Int // in days
    let price: Decimal?
    
    init(type: OfferType, duration: Int, price: Decimal? = nil) {
        self.type = type
        self.duration = duration
        self.price = price
    }
}

// MARK: - Product Validation

struct ProductValidator {
    static func validateReceipt(_ receiptData: Data) async throws -> ReceiptValidationResult {
        var request = URLRequest(url: URL(string: StoreKitConfiguration.verifyReceiptURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "receipt_data": receiptData.base64EncodedString(),
            "password": StoreKitConfiguration.sharedSecret,
            "exclude_old_transactions": true
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ValidationError.serverError
        }
        
        let result = try JSONDecoder().decode(ReceiptValidationResult.self, from: data)
        
        guard result.status == 0 else {
            throw ValidationError.invalidReceipt(status: result.status)
        }
        
        return result
    }
}

struct ReceiptValidationResult: Codable {
    let status: Int
    let receipt: Receipt?
    let latestReceiptInfo: [LatestReceiptInfo]?
    let pendingRenewalInfo: [PendingRenewalInfo]?
    
    struct Receipt: Codable {
        let bundleId: String
        let applicationVersion: String
        let inApp: [InAppPurchase]?
        
        private enum CodingKeys: String, CodingKey {
            case bundleId = "bundle_id"
            case applicationVersion = "application_version"
            case inApp = "in_app"
        }
    }
    
    struct InAppPurchase: Codable {
        let productId: String
        let transactionId: String
        let originalTransactionId: String
        let purchaseDate: String
        
        private enum CodingKeys: String, CodingKey {
            case productId = "product_id"
            case transactionId = "transaction_id"
            case originalTransactionId = "original_transaction_id"
            case purchaseDate = "purchase_date_ms"
        }
    }
    
    struct LatestReceiptInfo: Codable {
        let productId: String
        let transactionId: String
        let expiresDate: String?
        let isTrialPeriod: String
        
        private enum CodingKeys: String, CodingKey {
            case productId = "product_id"
            case transactionId = "transaction_id"
            case expiresDate = "expires_date_ms"
            case isTrialPeriod = "is_trial_period"
        }
    }
    
    struct PendingRenewalInfo: Codable {
        let productId: String
        let autoRenewStatus: String
        
        private enum CodingKeys: String, CodingKey {
            case productId = "product_id"
            case autoRenewStatus = "auto_renew_status"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case status
        case receipt
        case latestReceiptInfo = "latest_receipt_info"
        case pendingRenewalInfo = "pending_renewal_info"
    }
}

enum ValidationError: LocalizedError {
    case serverError
    case invalidReceipt(status: Int)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .serverError:
            return "Server validation error"
        case .invalidReceipt(let status):
            return "Invalid receipt with status: \(status)"
        case .networkError:
            return "Network error during validation"
        }
    }
}

// MARK: - Localized Pricing

struct LocalizedPrice {
    let locale: Locale
    let price: Decimal
    let currencyCode: String
    
    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = currencyCode
        return formatter.string(from: price as NSNumber) ?? ""
    }
    
    // Vancouver-specific pricing in CAD
    static func vancouverPrice(for usdPrice: Decimal) -> Decimal {
        // Approximate USD to CAD conversion (update with real rate)
        return usdPrice * 1.35
    }
}