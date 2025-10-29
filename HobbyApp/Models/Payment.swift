import Foundation

struct CreditPack: Identifiable, Decodable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let credits: Int
    let price: Double
    let pricePerCredit: Double?
    let savingsPercentage: Int?
    let isPopular: Bool
    let stripeProductId: String?
    let stripePriceId: String?
    let appleProductId: String?
    let createdAt: Date
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case credits
        case price
        case pricePerCredit = "price_per_credit"
        case savingsPercentage = "savings_percentage"
        case isPopular = "is_popular"
        case stripeProductId = "stripe_product_id"
        case stripePriceId = "stripe_price_id"
        case appleProductId = "apple_product_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var totalCredits: Int { credits }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        credits = try container.decode(Int.self, forKey: .credits)

        if let doublePrice = try? container.decode(Double.self, forKey: .price) {
            price = doublePrice
        } else if let stringPrice = try? container.decode(String.self, forKey: .price),
                  let parsed = Double(stringPrice) {
            price = parsed
        } else {
            price = 0
        }

        if let perCredit = try? container.decode(Double.self, forKey: .pricePerCredit) {
            pricePerCredit = perCredit
        } else if let perCreditString = try? container.decode(String.self, forKey: .pricePerCredit),
                  let parsed = Double(perCreditString) {
            pricePerCredit = parsed
        } else {
            pricePerCredit = nil
        }

        savingsPercentage = try container.decodeIfPresent(Int.self, forKey: .savingsPercentage)
        isPopular = try container.decodeIfPresent(Bool.self, forKey: .isPopular) ?? false
        stripeProductId = try container.decodeIfPresent(String.self, forKey: .stripeProductId)
        stripePriceId = try container.decodeIfPresent(String.self, forKey: .stripePriceId)
        appleProductId = try container.decodeIfPresent(String.self, forKey: .appleProductId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }

    var formattedPricePerCredit: String? {
        guard let pricePerCredit else { return nil }
        return String(format: "$%.2f / credit", pricePerCredit)
    }

    var savingsText: String? {
        guard let savingsPercentage, savingsPercentage > 0 else { return nil }
        return "Save \(savingsPercentage)%"
    }

    var supportsApplePay: Bool {
        appleProductId != nil
    }
}

struct CreditTransaction: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let transactionType: TransactionType
    let creditAmount: Int
    let balanceAfter: Int
    let referenceType: String?
    let referenceId: UUID?
    let description: String?
    let metadata: [String: String]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case transactionType = "transaction_type"
        case creditAmount = "credit_amount"
        case balanceAfter = "balance_after"
        case referenceType = "reference_type"
        case referenceId = "reference_id"
        case description
        case metadata
        case createdAt = "created_at"
    }
    
    var isDebit: Bool {
        creditAmount < 0
    }
    
    var formattedAmount: String {
        let sign = isDebit ? "-" : "+"
        return "\(sign)\(abs(creditAmount))"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

struct CreditPackPurchase: Identifiable, Decodable, Hashable {
    let id: UUID
    let userId: UUID
    let creditPackId: UUID
    let stripePaymentIntentId: String?
    let amountPaidCents: Int
    let creditsReceived: Int
    let bonusCredits: Int
    let status: PurchaseStatus
    let createdAt: Date
    let updatedAt: Date?
    
    var creditPack: CreditPack?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case creditPackId = "credit_pack_id"
        case stripePaymentIntentId = "stripe_payment_intent_id"
        case amountPaidCents = "amount_paid_cents"
        case creditsReceived = "credits_received"
        case bonusCredits = "bonus_credits"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case creditPack = "credit_pack"
    }
    
    var totalCredits: Int {
        creditsReceived + bonusCredits
    }
    
    var formattedAmount: String {
        let dollars = Double(amountPaidCents) / 100.0
        return String(format: "$%.2f", dollars)
    }
}

struct StudioCommissionSettings: Codable, Hashable {
    let id: UUID
    let studioId: UUID?
    let commissionRate: Decimal
    let minimumPayoutCents: Int
    let payoutFrequency: PayoutFrequency
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case studioId = "studio_id"
        case commissionRate = "commission_rate"
        case minimumPayoutCents = "minimum_payout_cents"
        case payoutFrequency = "payout_frequency"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var commissionPercentage: Double {
        NSDecimalNumber(decimal: commissionRate).doubleValue * 100
    }
    
    var formattedCommissionRate: String {
        String(format: "%.0f%%", commissionPercentage)
    }
    
    var formattedMinimumPayout: String {
        let dollars = Double(minimumPayoutCents) / 100.0
        return String(format: "$%.2f", dollars)
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case purchase = "purchase"
    case spend = "spend"
    case refund = "refund"
    case bonus = "bonus"
    case adminAdjustment = "admin_adjustment"
    
    var displayName: String {
        switch self {
        case .purchase: return "Purchase"
        case .spend: return "Class Booking"
        case .refund: return "Refund"
        case .bonus: return "Bonus"
        case .adminAdjustment: return "Adjustment"
        }
    }
    
    var iconName: String {
        switch self {
        case .purchase: return "creditcard"
        case .spend: return "minus.circle"
        case .refund: return "arrow.uturn.backward"
        case .bonus: return "gift"
        case .adminAdjustment: return "wrench"
        }
    }
}

enum PurchaseStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .refunded: return "Refunded"
        }
    }
}

enum PayoutFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}
