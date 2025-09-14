import Foundation
import Combine

// MARK: - Pricing Models

enum ClassTier: String, CaseIterable, Codable {
    case creativeStarter = "creative_starter"     // 6 credits ($15-25 classes)
    case hobbyExplorer = "hobby_explorer"         // 8 credits ($25-35 classes)
    case skillBuilder = "skill_builder"           // 10 credits ($35-50 classes)
    case masterWorkshop = "master_workshop"       // 12 credits ($50-70 classes)
    case intensiveExperience = "intensive_experience" // 15 credits ($70-95 classes)
    
    var creditRequired: Double {
        switch self {
        case .creativeStarter: return 6.0
        case .hobbyExplorer: return 8.0
        case .skillBuilder: return 10.0
        case .masterWorkshop: return 12.0
        case .intensiveExperience: return 15.0
        }
    }
    
    var priceRange: ClosedRange<Double> {
        switch self {
        case .creativeStarter: return 15...25
        case .hobbyExplorer: return 25...35
        case .skillBuilder: return 35...50
        case .masterWorkshop: return 50...70
        case .intensiveExperience: return 70...95
        }
    }
    
    var studioCommission: Double {
        switch self {
        case .creativeStarter: return 0.85   // 85% to studio (15% platform fee)
        case .hobbyExplorer: return 0.85     // 85% to studio (15% platform fee)
        case .skillBuilder: return 0.85      // 85% to studio (15% platform fee)
        case .masterWorkshop: return 0.85    // 85% to studio (15% platform fee)
        case .intensiveExperience: return 0.85 // 85% to studio (15% platform fee)
        }
    }
}

struct CreditPackage: Identifiable, Codable {
    let id: String
    let name: String
    let credits: Int
    let price: Double
    let savings: Int? // Percentage saved
    let popular: Bool
    let description: String
    
    var pricePerCredit: Double {
        return price / Double(credits)
    }
    
    static let packages = [
        CreditPackage(
            id: "starter",
            name: "Try It",
            credits: 20,
            price: 25.00,
            savings: nil,
            popular: false,
            description: "Perfect for testing the waters"
        ),
        CreditPackage(
            id: "explorer",
            name: "Explore More",
            credits: 45,
            price: 55.00,
            savings: 12,
            popular: false,
            description: "Multi-class exploration"
        ),
        CreditPackage(
            id: "regular",
            name: "Get Serious",
            credits: 80,
            price: 95.00,
            savings: 24,
            popular: true,
            description: "Regular creative practice"
        ),
        CreditPackage(
            id: "enthusiast",
            name: "Go Deep",
            credits: 145,
            price: 170.00,
            savings: 32,
            popular: false,
            description: "Intensive learning"
        ),
        CreditPackage(
            id: "power",
            name: "Unlimited Creativity",
            credits: 260,
            price: 300.00,
            savings: 40,
            popular: false,
            description: "Try everything Vancouver has to offer"
        )
    ]
}

struct Subscription: Identifiable, Codable {
    let id: String
    let name: String
    let monthlyPrice: Double
    let monthlyCredits: Int
    let rolloverLimit: Int
    let perks: [String]
    let popular: Bool
    
    static let plans = [
        Subscription(
            id: "casual",
            name: "Creative Explorer",
            monthlyPrice: 39.00,
            monthlyCredits: 40,
            rolloverLimit: 20,
            perks: ["50% rollover (20 credits max)", "Community access", "Basic app features"],
            popular: false
        ),
        Subscription(
            id: "active",
            name: "Hobby Regular",
            monthlyPrice: 69.00,
            monthlyCredits: 75,
            rolloverLimit: 45,
            perks: ["60% rollover (45 credits max)", "Priority booking", "Guest passes", "Workshop discounts"],
            popular: true
        ),
        Subscription(
            id: "premium",
            name: "Creative Enthusiast",
            monthlyPrice: 119.00,
            monthlyCredits: 150,
            rolloverLimit: 112,
            perks: ["75% rollover (112 credits max)", "Premium support", "Exclusive workshops", "Multi-studio access"],
            popular: false
        ),
        Subscription(
            id: "elite",
            name: "Master Creator",
            monthlyPrice: 179.00,
            monthlyCredits: 250,
            rolloverLimit: 1000,
            perks: ["100% unlimited rollover", "Concierge service", "Private workshop access", "All premium features"],
            popular: false
        )
    ]
}

enum CreditInsurance: String, CaseIterable, Codable {
    case none = "none"
    case basic = "basic"      // $3/month
    case plus = "plus"        // $5/month
    case premium = "premium"  // $8/month
    
    var monthlyPrice: Double {
        switch self {
        case .none: return 0
        case .basic: return 3.00
        case .plus: return 5.00
        case .premium: return 8.00
        }
    }
    
    var features: [String] {
        switch self {
        case .none:
            return []
        case .basic:
            return ["Credits rollover 1 extra month", "Emergency pause (once/year)"]
        case .plus:
            return ["Unlimited rollover", "Gift unused credits", "Pause anytime", "Credit refund (once/year)"]
        case .premium:
            return ["Everything in Plus", "Convert to gift cards", "Priority booking", "Exclusive sessions"]
        }
    }
}

// MARK: - Pricing Service Protocol

protocol PricingServiceProtocol {
    func calculateCreditsNeeded(for classPrice: Double, tier: ClassTier, time: Date) -> Double
    func getOptimalPackage(for monthlyClasses: Int) -> CreditPackage
    func calculateSavings(package: CreditPackage, vsDropIn average: Double) -> Double
    func calculateStudioPayout(classPrice: Double, tier: ClassTier) -> Double
    func getRolloverAmount(unusedCredits: Int, membershipMonths: Int, insurance: CreditInsurance) -> Int
    func shouldShowPromotion(for user: User?) -> Promotion?
    func calculateValueProposition(monthlySpend: Double) -> ValueProposition
}

// MARK: - Pricing Service Implementation

@MainActor
class PricingService: ObservableObject, PricingServiceProtocol {
    static let shared = PricingService()
    
    @Published var currentPromotion: Promotion?
    @Published var userCredits: Int = 0
    @Published var creditHistory: [CreditTransaction] = []
    
    private let calendar = Calendar.current
    
    // MARK: - Credit Calculations
    
    func calculateCreditsNeeded(for classPrice: Double, tier: ClassTier, time: Date) -> Double {
        var baseCredits = tier.creditRequired
        
        // Apply time-based multipliers (peak/off-peak pricing)
        let hour = calendar.component(.hour, from: time)
        let dayOfWeek = calendar.component(.weekday, from: time)
        
        // Peak hours (6-8am, 5-7pm on weekdays)
        if dayOfWeek >= 2 && dayOfWeek <= 6 { // Monday to Friday
            if (hour >= 6 && hour < 8) || (hour >= 17 && hour < 19) {
                baseCredits *= 1.25 // 25% more credits during peak
            }
        }
        
        // Off-peak discount (11am-2pm weekdays)
        if dayOfWeek >= 2 && dayOfWeek <= 6 {
            if hour >= 11 && hour < 14 {
                baseCredits *= 0.75 // 25% fewer credits off-peak
            }
        }
        
        // Weekend mornings slight premium
        if dayOfWeek == 1 || dayOfWeek == 7 { // Sunday or Saturday
            if hour >= 9 && hour < 12 {
                baseCredits *= 1.1 // 10% more for popular weekend slots
            }
        }
        
        return baseCredits
    }
    
    // MARK: - Package Recommendations
    
    func getOptimalPackage(for monthlyClasses: Int) -> CreditPackage {
        let creditsNeeded = monthlyClasses // Assuming standard classes
        
        // Find the most economical package
        let sortedPackages = CreditPackage.packages.sorted { $0.pricePerCredit < $1.pricePerCredit }
        
        for package in sortedPackages {
            if package.credits >= creditsNeeded {
                return package
            }
        }
        
        return CreditPackage.packages.last! // Return largest if none sufficient
    }
    
    // MARK: - Savings Calculations
    
    func calculateSavings(package: CreditPackage, vsDropIn average: Double = 30.0) -> Double {
        let dropInCost = Double(package.credits) * average
        let packageCost = package.price
        let savings = dropInCost - packageCost
        return max(0, savings)
    }
    
    func calculateSavingsPercentage(package: CreditPackage, vsDropIn average: Double = 30.0) -> Int {
        let dropInCost = Double(package.credits) * average
        let packageCost = package.price
        let savingsPercent = ((dropInCost - packageCost) / dropInCost) * 100
        return Int(max(0, savingsPercent))
    }
    
    // MARK: - Studio Economics
    
    func calculateStudioPayout(classPrice: Double, tier: ClassTier) -> Double {
        return classPrice * tier.studioCommission
    }
    
    func calculatePlatformRevenue(classPrice: Double, tier: ClassTier) -> Double {
        return classPrice * (1 - tier.studioCommission)
    }
    
    // MARK: - Rollover Logic
    
    func getRolloverAmount(unusedCredits: Int, membershipMonths: Int, insurance: CreditInsurance) -> Int {
        switch insurance {
        case .none:
            // Loyalty-based rollover without insurance
            if membershipMonths < 3 {
                return Int(Double(unusedCredits) * 0.25) // 25% rollover
            } else if membershipMonths < 6 {
                return Int(Double(unusedCredits) * 0.50) // 50% rollover
            } else if membershipMonths < 12 {
                return Int(Double(unusedCredits) * 0.75) // 75% rollover
            } else {
                return unusedCredits // 100% rollover for 1+ year members
            }
            
        case .basic:
            return unusedCredits // Full rollover for 1 month
            
        case .plus, .premium:
            return unusedCredits // Unlimited rollover
        }
    }
    
    // MARK: - Promotions Engine
    
    func shouldShowPromotion(for user: User?) -> Promotion? {
        guard let user = user else {
            // New user promotion
            return Promotion(
                id: "new_user",
                title: "Welcome! 50% off your first package",
                discount: 0.5,
                validUntil: Date().addingTimeInterval(72 * 3600), // 72 hours
                code: "WELCOME50"
            )
        }
        
        // Check various promotion triggers
        if user.daysSinceLastClass > 14 {
            return Promotion(
                id: "win_back",
                title: "We miss you! 5 bonus credits on your next purchase",
                bonusCredits: 5,
                validUntil: Date().addingTimeInterval(7 * 24 * 3600),
                code: "COMEBACK5"
            )
        }
        
        // Seasonal promotions
        let month = calendar.component(.month, from: Date())
        switch month {
        case 1: // January
            return Promotion(
                id: "new_year",
                title: "New Year Special: 30% off all packages",
                discount: 0.3,
                validUntil: calendar.date(byAdding: .day, value: 31, to: Date())!,
                code: "NEWYEAR30"
            )
        case 11: // November
            return Promotion(
                id: "black_friday",
                title: "Black Friday: 40% off everything!",
                discount: 0.4,
                validUntil: calendar.date(byAdding: .day, value: 4, to: Date())!,
                code: "BLACK40"
            )
        default:
            break
        }
        
        return nil
    }
    
    // MARK: - Value Proposition
    
    func calculateValueProposition(monthlySpend: Double) -> ValueProposition {
        // Calculate savings vs drop-in pricing
        let averageClassPrice = 30.0
        let classesAfforded = monthlySpend / averageClassPrice
        
        // Find best package for this spend
        let optimalPackage = CreditPackage.packages.first { $0.price <= monthlySpend } ?? CreditPackage.packages[0]
        let creditsReceived = Int((monthlySpend / optimalPackage.price) * Double(optimalPackage.credits))
        
        let classesWithPlatform = creditsReceived // Assuming 1 credit per class average
        let additionalClasses = classesWithPlatform - Int(classesAfforded)
        let savingsAmount = (Double(classesWithPlatform) * averageClassPrice) - monthlySpend
        
        return ValueProposition(
            monthlySpend: monthlySpend,
            classesWithoutPlatform: Int(classesAfforded),
            classesWithPlatform: classesWithPlatform,
            additionalClasses: max(0, additionalClasses),
            savingsAmount: max(0, savingsAmount),
            savingsPercentage: Int((savingsAmount / (Double(classesWithPlatform) * averageClassPrice)) * 100)
        )
    }
    
    // MARK: - Winter Program Adjustments
    
    func getSeasonalAdjustment(for date: Date = Date()) -> SeasonalAdjustment {
        let month = calendar.component(.month, from: date)
        
        switch month {
        case 11...2: // November to February (Winter)
            return SeasonalAdjustment(
                creditBonus: 0.2, // 20% more credits
                indoorPriority: true,
                weatherProtection: true,
                specialPrograms: ["Winter Warrior", "Cozy Classes"]
            )
        case 6...8: // June to August (Summer)
            return SeasonalAdjustment(
                creditBonus: 0,
                outdoorPriority: true,
                flexibleCancellation: true,
                specialPrograms: ["Summer Flex", "Outdoor Adventures"]
            )
        default:
            return SeasonalAdjustment()
        }
    }
    
    // MARK: - IAP Integration Methods
    
    func addCredits(_ amount: Int, source: String, transactionId: String) async {
        userCredits += amount
        
        let transaction = CreditTransaction(
            date: Date(),
            type: .purchase,
            amount: amount,
            description: "Credits purchased via \(source)",
            balance: userCredits
        )
        creditHistory.append(transaction)
        
        // Sync with backend
        await syncCreditsWithBackend(credits: userCredits, transactionId: transactionId)
        
        print("Added \(amount) credits. New balance: \(userCredits)")
    }
    
    func activateSubscription(planId: String, transactionId: String) async {
        // Activate subscription in backend
        await syncSubscriptionWithBackend(planId: planId, transactionId: transactionId)
        print("Subscription \(planId) activated with transaction: \(transactionId)")
    }
    
    func activateInsurance(planId: String, transactionId: String) async {
        // Activate insurance in backend
        await syncInsuranceWithBackend(planId: planId, transactionId: transactionId)
        print("Insurance \(planId) activated with transaction: \(transactionId)")
    }
    
    // MARK: - Backend Sync Methods
    
    private func syncCreditsWithBackend(credits: Int, transactionId: String) async {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else { return }
        
        do {
            let _ = try await SupabaseManager.shared.client
                .database
                .from("user_credits")
                .upsert([
                    "user_id": userId.uuidString,
                    "balance": credits,
                    "last_transaction_id": transactionId,
                    "updated_at": Date().ISO8601Format()
                ])
                .execute()
        } catch {
            print("Failed to sync credits with backend: \(error)")
        }
    }
    
    private func syncSubscriptionWithBackend(planId: String, transactionId: String) async {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else { return }
        
        do {
            let _ = try await SupabaseManager.shared.client
                .database
                .from("user_subscriptions")
                .upsert([
                    "user_id": userId.uuidString,
                    "plan_id": planId,
                    "transaction_id": transactionId,
                    "status": "active",
                    "activated_at": Date().ISO8601Format()
                ])
                .execute()
        } catch {
            print("Failed to sync subscription with backend: \(error)")
        }
    }
    
    private func syncInsuranceWithBackend(planId: String, transactionId: String) async {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else { return }
        
        do {
            let _ = try await SupabaseManager.shared.client
                .database
                .from("user_insurance")
                .upsert([
                    "user_id": userId.uuidString,
                    "plan_id": planId,
                    "transaction_id": transactionId,
                    "status": "active",
                    "activated_at": Date().ISO8601Format()
                ])
                .execute()
        } catch {
            print("Failed to sync insurance with backend: \(error)")
        }
    }
}

// MARK: - Supporting Models

struct User {
    let id: String
    let daysSinceLastClass: Int
    let membershipMonths: Int
    let totalClassesAttended: Int
}

struct Promotion: Identifiable {
    let id: String
    let title: String
    var discount: Double = 0
    var bonusCredits: Int = 0
    let validUntil: Date
    let code: String
}

struct ValueProposition {
    let monthlySpend: Double
    let classesWithoutPlatform: Int
    let classesWithPlatform: Int
    let additionalClasses: Int
    let savingsAmount: Double
    let savingsPercentage: Int
}

struct SeasonalAdjustment {
    var creditBonus: Double = 0
    var indoorPriority: Bool = false
    var outdoorPriority: Bool = false
    var weatherProtection: Bool = false
    var flexibleCancellation: Bool = false
    var specialPrograms: [String] = []
}

struct CreditTransaction: Identifiable {
    let id = UUID()
    let date: Date
    let type: TransactionType
    let amount: Int
    let description: String
    let balance: Int
    
    enum TransactionType: String {
        case purchase = "purchase"
        case usage = "usage"
        case bonus = "bonus"
        case refund = "refund"
        case expiry = "expiry"
        case gift = "gift"
    }
}

// MARK: - Mock Pricing Service

class MockPricingService: PricingServiceProtocol {
    func calculateCreditsNeeded(for classPrice: Double, tier: ClassTier, time: Date) -> Double {
        return tier.creditRequired
    }
    
    func getOptimalPackage(for monthlyClasses: Int) -> CreditPackage {
        return CreditPackage.packages[2] // Return "Regular" package
    }
    
    func calculateSavings(package: CreditPackage, vsDropIn average: Double) -> Double {
        return 100.0 // Mock savings
    }
    
    func calculateStudioPayout(classPrice: Double, tier: ClassTier) -> Double {
        return classPrice * 0.7
    }
    
    func getRolloverAmount(unusedCredits: Int, membershipMonths: Int, insurance: CreditInsurance) -> Int {
        return unusedCredits / 2
    }
    
    func shouldShowPromotion(for user: User?) -> Promotion? {
        return Promotion(
            id: "test",
            title: "Test Promotion",
            discount: 0.2,
            validUntil: Date().addingTimeInterval(86400),
            code: "TEST20"
        )
    }
    
    func calculateValueProposition(monthlySpend: Double) -> ValueProposition {
        return ValueProposition(
            monthlySpend: monthlySpend,
            classesWithoutPlatform: 3,
            classesWithPlatform: 5,
            additionalClasses: 2,
            savingsAmount: 50,
            savingsPercentage: 40
        )
    }
}