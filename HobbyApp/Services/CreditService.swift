import Foundation
import Combine

@MainActor
class CreditService: ObservableObject {
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

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Load mock data for development
        loadMockData()
    }

    // MARK: - Computed Properties

    var hasRolloverCredits: Bool {
        rolloverCredits > 0
    }

    var estimatedClasses: Int {
        // Using average of 8 credits per class (middle of 6-15 range)
        Int(Double(totalCredits) / 8.0)
    }

    var estimatedSavings: Double {
        // Assuming average class price of $40 vs $1.20 per credit
        let dropInCost = Double(totalCredits) * 5.0 // $5 per credit equivalent at $40/8 credits
        let creditCost = Double(totalCredits) * 1.20 // Our average credit cost
        return max(0, dropInCost - creditCost)
    }

    // MARK: - Public Methods

    func refreshCredits() {
        // In a real app, this would fetch from Supabase
        // For now, simulate loading with mock data
        Task {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            loadMockData()
        }
    }

    func purchaseCredits(packageId: String, completion: @escaping (Bool) -> Void) {
        // Simulate purchase process
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay

            // Add credits based on package
            let creditsToAdd = getCreditAmountForPackage(packageId)
            currentMonthCredits += creditsToAdd
            totalCredits += creditsToAdd

            // Add transaction to history
            let transaction = CreditTransactionDisplay(
                description: "Credit Package Purchase",
                date: Date(),
                amount: creditsToAdd,
                balanceAfter: totalCredits,
                type: .purchase
            )
            creditHistory.insert(transaction, at: 0)

            completion(true)
        }
    }

    func useCredits(amount: Int, for activity: String, completion: @escaping (Bool) -> Void) {
        guard totalCredits >= amount else {
            completion(false)
            return
        }

        // Deduct credits (prioritize rollover credits first)
        if rolloverCredits >= amount {
            rolloverCredits -= amount
        } else {
            let remaining = amount - rolloverCredits
            rolloverCredits = 0
            currentMonthCredits -= remaining
        }

        totalCredits -= amount
        creditsUsedThisMonth += amount

        // Add transaction to history
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
        // Simulate user with Creative Enthusiast subscription
        hasActiveSubscription = true
        subscriptionPlanName = "Creative Enthusiast"
        rolloverPercentage = 75
        nextRolloverDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())

        // Mock credit amounts (reflecting new system)
        currentMonthCredits = 120 // Some used from 150 monthly credits
        rolloverCredits = 45     // Rollover from previous month
        totalCredits = currentMonthCredits + rolloverCredits
        creditsUsedThisMonth = 30

        // Mock transaction history with fixed data types
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

        // Mock upcoming expirations (empty for subscription users with good rollover)
        upcomingExpirations = []
    }

    private func getCreditAmountForPackage(_ packageId: String) -> Int {
        // Map package IDs to credit amounts (matching our new system)
        switch packageId {
        case "starter": return 20
        case "explorer": return 45
        case "regular": return 80
        case "enthusiast": return 145
        case "power": return 260
        default: return 20
        }
    }
}

// MARK: - Real Supabase Integration (commented for now)

extension CreditService {
    /*
    private func fetchCreditsFromSupabase() async throws {
        // This would integrate with the Supabase user_credits table
        let supabase = SupabaseClient.shared

        let userCredits: UserCredits = try await supabase
            .from("user_credits")
            .select()
            .eq("user_id", AuthenticationManager.shared.currentUser?.id ?? "")
            .single()
            .execute()
            .value

        await MainActor.run {
            self.totalCredits = userCredits.total_credits
            self.rolloverCredits = userCredits.rollover_credits
            // ... etc
        }
    }

    private func fetchCreditHistory() async throws {
        // This would fetch from credit_transactions table
        let transactions: [CreditTransaction] = try await supabase
            .from("credit_transactions")
            .select()
            .eq("user_id", AuthenticationManager.shared.currentUser?.id ?? "")
            .order("created_at", ascending: false)
            .limit(20)
            .execute()
            .value

        // Transform to display models...
    }
    */
}