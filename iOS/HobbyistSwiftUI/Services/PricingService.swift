import Foundation
import Combine

// MARK: - Pricing Models

enum ClassTier: String, CaseIterable, Codable {
    case community = "community"      // 0.5 credits ($10-15 classes)
    case standard = "standard"        // 1.0 credits ($20-30 classes)
    case premium = "premium"          // 2.0 credits ($35-50 classes)
    case exclusive = "exclusive"      // 3.0 credits ($60-80 classes)
    case masterclass = "masterclass"  // 4.0 credits ($85-105 classes)
    
    var creditRequired: Double {
        switch self {
        case .community: return 0.5
        case .standard: return 1.0
        case .premium: return 2.0
        case .exclusive: return 3.0
        case .masterclass: return 4.0
        }
    }
    
    var priceRange: ClosedRange<Double> {
        switch self {
        case .community: return 10...15
        case .standard: return 20...30
        case .premium: return 35...50
        case .exclusive: return 60...80
        case .masterclass: return 85...105
        }
    }
    
    var studioCommission: Double {
        switch self {
        case .community: return 0.75  // 75% to studio
        case .standard: return 0.70   // 70% to studio
        case .premium: return 0.72    // 72% to studio
        case .exclusive: return 0.75  // 75% to studio
        case .masterclass: return 0.75 // 75% to studio
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
            name: "Starter",
            credits: 10,
            price: 25.00,
            savings: nil,
            popular: false,
            description: "Perfect for trying out"
        ),
        CreditPackage(
            id: "explorer",
            name: "Explorer",
            credits: 25,
            price: 55.00,
            savings: 12,
            popular: false,
            description: "1-2 classes per week"
        ),
        CreditPackage(
            id: "regular",
            name: "Regular",
            credits: 50,
            price: 95.00,
            savings: 24,
            popular: true,
            description: "Most popular choice"
        ),
        CreditPackage(
            id: "enthusiast",
            name: "Enthusiast",
            credits: 100,
            price: 170.00,
            savings: 32,
            popular: false,
            description: "4-5 classes per week"
        ),
        CreditPackage(
            id: "power",
            name: "Power User",
            credits: 200,
            price: 300.00,
            savings: 40,
            popular: false,
            description: "Best value for daily users"
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
            name: "Casual",
            monthlyPrice: 39.00,
            monthlyCredits: 20,
            rolloverLimit: 5,
            perks: ["Basic access"],
            popular: false
        ),
        Subscription(
            id: "active",
            name: "Active",
            monthlyPrice: 69.00,
            monthlyCredits: 40,
            rolloverLimit: 10,
            perks: ["Priority booking", "1 guest pass/month"],
            popular: true
        ),
        Subscription(
            id: "premium",
            name: "Premium",
            monthlyPrice: 119.00,
            monthlyCredits: 80,
            rolloverLimit: 20,
            perks: ["All perks", "Equipment rental", "Exclusive classes"],
            popular: false
        ),
        Subscription(
            id: "elite",
            name: "Elite",
            monthlyPrice: 179.00,
            monthlyCredits: 150,
            rolloverLimit: 30,
            perks: ["VIP treatment", "Personal trainer consultation", "3 guest passes"],
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