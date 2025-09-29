import Foundation

struct CreditPack: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let creditAmount: Int
    let priceCents: Int
    let bonusCredits: Int
    let isActive: Bool
    let displayOrder: Int
    let popularBadge: Bool?
    let savingsPercentage: Int?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case creditAmount = "credit_amount"
        case priceCents = "price_cents"
        case bonusCredits = "bonus_credits"
        case isActive = "is_active"
        case displayOrder = "display_order"
        case popularBadge = "popular_badge"
        case savingsPercentage = "savings_percentage"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var totalCredits: Int {
        creditAmount + bonusCredits
    }
    
    var formattedPrice: String {
        let dollars = Double(priceCents) / 100.0
        return String(format: "$%.2f", dollars)
    }
    
    var pricePerCredit: Double {
        Double(priceCents) / Double(totalCredits) / 100.0
    }
    
    var formattedPricePerCredit: String {
        String(format: "$%.2f", pricePerCredit)
    }
    
    var savingsText: String? {
        guard bonusCredits > 0 else { return nil }
        return "+\(bonusCredits) Bonus Credits"
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

struct CreditPackPurchase: Identifiable, Codable, Hashable {
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