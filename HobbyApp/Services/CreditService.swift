import Foundation
import Combine
import Supabase

struct PaymentSheetSetupResponse: Decodable {
    let success: Bool
    let message: String?
    let publishableKey: String?
    let paymentIntentClientSecret: String
    let paymentIntentId: String
    let customerId: String
    let ephemeralKeySecret: String
    let amountCents: Int
    let credits: Int
    let bonusCredits: Int
    let totalCredits: Int

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case publishableKey = "publishable_key"
        case paymentIntentClientSecret = "payment_intent_client_secret"
        case paymentIntentId = "payment_intent_id"
        case customerId = "customer_id"
        case ephemeralKeySecret = "ephemeral_key_secret"
        case amountCents = "amount_cents"
        case credits
        case bonusCredits = "bonus_credits"
        case totalCredits = "total_credits"
    }
}

struct FinalizePurchaseResponse: Decodable {
    let success: Bool
    let message: String?
    let paymentIntentId: String?
    let creditsAdded: Int?
    let bonusCredits: Int?
    let squadBonus: Int?
    let totalCreditsAdded: Int?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case paymentIntentId = "payment_intent_id"
        case creditsAdded = "credits_added"
        case bonusCredits = "bonus_credits"
        case squadBonus = "squad_bonus"
        case totalCreditsAdded = "total_credits_added"
    }
}

private struct PaymentSheetRequest: Encodable {
    let action = "create_payment_sheet"
    let package_id: String

    init(packageId: UUID) {
        self.package_id = packageId.uuidString
    }
}

private struct FinalizePurchaseRequest: Encodable {
    let action = "finalize_purchase"
    let payment_intent_id: String

    init(paymentIntentId: String) {
        self.payment_intent_id = paymentIntentId
    }
}

private struct UserCreditsRecord: Decodable {
    let credit_balance: Int
    let current_month_credits: Int?
    let rollover_credits: Int?
    let credits_used_this_month: Int?
    let next_rollover_at: Date?
    let has_active_subscription: Bool?
    let subscription_plan_name: String?
    let rollover_percentage: Int?
}

enum CreditServiceError: LocalizedError {
    case userNotAuthenticated
    case paymentSetupFailed(String)
    case purchaseFailed(String)

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "Please sign in to purchase credits."
        case .paymentSetupFailed(let message):
            return message
        case .purchaseFailed(let message):
            return message
        }
    }
}

@MainActor
final class CreditService: ObservableObject {
    static let shared = CreditService()

    @Published var totalCredits: Int = 0
    @Published var currentMonthCredits: Int = 0
    @Published var rolloverCredits: Int = 0
    @Published var creditsUsedThisMonth: Int = 0
    @Published var hasActiveSubscription: Bool = false
    @Published var subscriptionPlanName: String = ""
    @Published var rolloverPercentage: Int = 0
    @Published var nextRolloverDate: Date? = nil
    @Published var creditHistory: [CreditTransactionDisplay] = []
    @Published var upcomingExpirations: [CreditExpiration] = []

    @Published var availableCreditPacks: [CreditPack] = []
    @Published var isLoadingPacks: Bool = false
    @Published var packsError: String?
    @Published var purchaseMessage: String?

    private let supabaseService = SimpleSupabaseService.shared
    private let decoder: JSONDecoder

    private init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Computed Properties

    var hasRolloverCredits: Bool {
        rolloverCredits > 0
    }

    var estimatedClasses: Int {
        Int(Double(totalCredits) / 8.0)
    }

    var estimatedSavings: Double {
        let dropInCost = Double(totalCredits) * 5.0
        let creditCost = Double(totalCredits) * 1.20
        return max(0, dropInCost - creditCost)
    }

    // MARK: - Public Methods

    func refreshCredits() {
        Task {
            await loadCreditSummary()
        }
    }

    func loadCreditSummary() async {
        guard let userId = supabaseService.currentUser?.id else {
            loadMockData()
            return
        }

        do {
            let client = supabaseService.client
            let response = try await client
                .from("user_credits")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()

            let record = try decoder.decode(UserCreditsRecord.self, from: response.data)
            totalCredits = record.credit_balance
            currentMonthCredits = record.current_month_credits ?? record.credit_balance
            rolloverCredits = record.rollover_credits ?? 0
            creditsUsedThisMonth = record.credits_used_this_month ?? 0
            nextRolloverDate = record.next_rollover_at
            hasActiveSubscription = record.has_active_subscription ?? false
            subscriptionPlanName = record.subscription_plan_name ?? ""
            rolloverPercentage = record.rollover_percentage ?? 0

            // TODO: Replace with real history + expirations when endpoints are available
            creditHistory = []
            upcomingExpirations = []
        } catch {
            print("⚠️ Failed to load credits from Supabase: \(error)")
            totalCredits = 0
            currentMonthCredits = 0
            rolloverCredits = 0
            creditsUsedThisMonth = 0
            nextRolloverDate = nil
            hasActiveSubscription = false
            subscriptionPlanName = ""
            rolloverPercentage = 0
            creditHistory = []
            upcomingExpirations = []
        }
    }

    func loadCreditPacks(force: Bool = false) async {
        if !force && !availableCreditPacks.isEmpty { return }
        guard supabaseService.isAuthenticated else {
            packsError = "Sign in to view credit packs."
            return
        }

        isLoadingPacks = true
        packsError = nil

        do {
            let client = supabaseService.client
            let response = try await client
                .from("credit_packs")
                .select()
                .eq("is_active", value: true)
                .order("display_order", ascending: true)
                .execute()

            let packs = try decoder.decode([CreditPack].self, from: response.data)
            availableCreditPacks = packs
        } catch {
            print("⚠️ Failed to load credit packs: \(error)")
            packsError = "Unable to load credit packs right now."
        }

        isLoadingPacks = false
    }

    func preparePaymentSheet(for pack: CreditPack) async throws -> PaymentSheetSetupResponse {
        guard supabaseService.isAuthenticated else {
            throw CreditServiceError.userNotAuthenticated
        }

        let request = PaymentSheetRequest(packageId: pack.id)
        let client = supabaseService.client
        let response: PaymentSheetSetupResponse = try await client.functions.invoke(
            "purchase-credits",
            with: request
        )

        guard response.success else {
            throw CreditServiceError.paymentSetupFailed(response.message ?? "Unable to start purchase.")
        }

        return response
    }

    func finalizePurchase(paymentIntentId: String) async throws -> FinalizePurchaseResponse {
        guard supabaseService.isAuthenticated else {
            throw CreditServiceError.userNotAuthenticated
        }

        let request = FinalizePurchaseRequest(paymentIntentId: paymentIntentId)
        let client = supabaseService.client
        let response: FinalizePurchaseResponse = try await client.functions.invoke(
            "purchase-credits",
            with: request
        )

        guard response.success else {
            throw CreditServiceError.purchaseFailed(response.message ?? "Purchase failed.")
        }

        await loadCreditSummary()
        purchaseMessage = response.message
        return response
    }

    func useCredits(amount: Int, for activity: String, completion: @escaping (Bool) -> Void) {
        guard totalCredits >= amount else {
            completion(false)
            return
        }

        if rolloverCredits >= amount {
            rolloverCredits -= amount
        } else {
            let remaining = amount - rolloverCredits
            rolloverCredits = 0
            currentMonthCredits -= remaining
        }

        totalCredits -= amount
        creditsUsedThisMonth += amount

        let transaction = CreditTransactionDisplay(
            description: activity,
            date: Date(),
            amount: amount,
            balanceAfter: totalCredits,
            type: .usage
        )
        creditHistory.insert(transaction, at: 0)

        completion(true)
    }

    // MARK: - Private Methods

    private func loadMockData() {
        hasActiveSubscription = true
        subscriptionPlanName = "Creative Enthusiast"
        rolloverPercentage = 75
        nextRolloverDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())

        currentMonthCredits = 120
        rolloverCredits = 45
        totalCredits = currentMonthCredits + rolloverCredits
        creditsUsedThisMonth = 30

        creditHistory = [
            CreditTransactionDisplay(
                description: "Pottery Class at Claymates",
                date: Date().addingTimeInterval(-86400 * 2),
                amount: 10,
                balanceAfter: totalCredits + 10,
                type: .usage
            ),
            CreditTransactionDisplay(
                description: "Urban Photography Walk",
                date: Date().addingTimeInterval(-86400 * 5),
                amount: 8,
                balanceAfter: totalCredits + 18,
                type: .usage
            ),
            CreditTransactionDisplay(
                description: "Sourdough Bread Making",
                date: Date().addingTimeInterval(-86400 * 7),
                amount: 12,
                balanceAfter: totalCredits + 30,
                type: .usage
            ),
            CreditTransactionDisplay(
                description: "Monthly Rollover",
                date: Date().addingTimeInterval(-86400 * 10),
                amount: 45,
                balanceAfter: totalCredits + 4,
                type: .rollover
            ),
            CreditTransactionDisplay(
                description: "Monthly Subscription",
                date: Date().addingTimeInterval(-86400 * 30),
                amount: 150,
                balanceAfter: totalCredits - 41,
                type: .purchase
            )
        ]

        upcomingExpirations = []
    }
}
