import SwiftUI

struct PricingView: View {
    @StateObject private var pricingService = PricingService.shared
    @EnvironmentObject var hapticService: HapticFeedbackService
    @State private var selectedTab = 0
    @State private var selectedPackage: CreditPackage?
    @State private var selectedSubscription: Subscription?
    @State private var showingPurchaseSheet = false
    @State private var showingInsuranceInfo = false
    @State private var monthlySpend: Double = 100
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Value Calculator
                valueCalculatorSection
                
                // Tab Selection
                tabSelector
                
                // Content based on tab
                if selectedTab == 0 {
                    creditPackagesSection
                } else {
                    subscriptionPlansSection
                }
                
                // Insurance Program
                insuranceProgramSection
                
                // Promotions
                if let promotion = pricingService.currentPromotion {
                    promotionBanner(promotion)
                }
            }
            .padding()
        }
        .navigationTitle("Pricing")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingPurchaseSheet) {
            PurchaseConfirmationView(
                package: selectedPackage,
                subscription: selectedSubscription
            )
        }
        .sheet(isPresented: $showingInsuranceInfo) {
            InsuranceInfoView()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Discover Vancouver's Creative Scene")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("From $15 pottery classes to $95 intensive workshops")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Social Proof
            HStack(spacing: 4) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                Text("4.9")
                    .fontWeight(.semibold)
                Text("(2,847 members)")
                    .foregroundColor(.secondary)
            }
            .font(.caption)
        }
    }
    
    // MARK: - Value Calculator
    
    private var valueCalculatorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("See Your Savings")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Slider
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monthly class budget: $\(Int(monthlySpend))")
                        .font(.subheadline)
                    
                    Slider(value: $monthlySpend, in: 50...500, step: 10)
                        .accentColor(.orange)
                        .onChange(of: monthlySpend) { _ in
                            hapticService.playLight()
                        }
                }
                
                // Results
                let proposition = pricingService.calculateValueProposition(monthlySpend: monthlySpend)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(proposition.classesWithoutPlatform)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("classes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("without us")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(proposition.classesWithPlatform)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("classes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("with Hobbyist")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("+\(proposition.additionalClasses)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("extra classes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Save \(proposition.savingsPercentage)%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        Picker("Pricing Type", selection: $selectedTab) {
            Text("Pay As You Go").tag(0)
            Text("Monthly Plans").tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedTab) { _ in
            hapticService.playSelection()
        }
    }
    
    // MARK: - Credit Packages Section
    
    private var creditPackagesSection: some View {
        VStack(spacing: 16) {
            ForEach(CreditPackage.packages) { package in
                CreditPackageCard(
                    package: package,
                    isSelected: selectedPackage?.id == package.id,
                    onSelect: {
                        selectedPackage = package
                        hapticService.playMedium()
                        showingPurchaseSheet = true
                    }
                )
            }
        }
    }
    
    // MARK: - Subscription Plans Section
    
    private var subscriptionPlansSection: some View {
        VStack(spacing: 16) {
            ForEach(Subscription.plans) { plan in
                SubscriptionPlanCard(
                    plan: plan,
                    isSelected: selectedSubscription?.id == plan.id,
                    onSelect: {
                        selectedSubscription = plan
                        hapticService.playMedium()
                        showingPurchaseSheet = true
                    }
                )
            }
        }
    }
    
    // MARK: - Insurance Program Section
    
    private var insuranceProgramSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(.blue)
                Text("Credit Insurance")
                    .font(.headline)
                Spacer()
                Button("Learn More") {
                    hapticService.playLight()
                    showingInsuranceInfo = true
                }
                .font(.caption)
            }
            
            Text("Never lose unused credits again")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                InsuranceTierBadge(tier: .basic, price: "$3/mo")
                InsuranceTierBadge(tier: .plus, price: "$5/mo")
                InsuranceTierBadge(tier: .premium, price: "$8/mo")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Promotion Banner
    
    private func promotionBanner(_ promotion: Promotion) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(promotion.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if promotion.discount > 0 {
                    Text("Save \(Int(promotion.discount * 100))%")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                if promotion.bonusCredits > 0 {
                    Text("+\(promotion.bonusCredits) bonus credits")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            Text(promotion.code)
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(6)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.orange.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - Credit Package Card

struct CreditPackageCard: View {
    let package: CreditPackage
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Popular badge
            if package.popular {
                Text("MOST POPULAR")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            
            // Credits
            Text("\(package.credits) Credits")
                .font(.title2)
                .fontWeight(.bold)
            
            // Price
            Text("$\(package.price, specifier: "%.0f")")
                .font(.largeTitle)
                .fontWeight(.heavy)
            
            // Per credit price
            Text("$\(package.pricePerCredit, specifier: "%.2f") per credit")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Savings
            if let savings = package.savings {
                Text("Save \(savings)%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
            
            // Description
            Text(package.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Select button
            Button(action: onSelect) {
                Text("Select")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(package.popular ? Color.orange : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(package.popular ? Color.orange : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Subscription Plan Card

struct SubscriptionPlanCard: View {
    let plan: Subscription
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.name)
                            .font(.headline)
                        
                        if plan.popular {
                            Text("RECOMMENDED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(6)
                        }
                    }
                    
                    Text("\(plan.monthlyCredits) credits/month")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("$\(plan.monthlyPrice, specifier: "%.0f")")
                    .font(.title2)
                    .fontWeight(.bold)
                + Text("/mo")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Perks
            VStack(alignment: .leading, spacing: 6) {
                ForEach(plan.perks, id: \.self) { perk in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(perk)
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("Roll over up to \(plan.rolloverLimit) credits")
                        .font(.caption)
                }
            }
            
            // Select button
            Button(action: onSelect) {
                Text("Choose Plan")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(plan.popular ? Color.orange : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(plan.popular ? Color.orange : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Insurance Tier Badge

struct InsuranceTierBadge: View {
    let tier: CreditInsurance
    let price: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(iconColor)
            
            Text(tier.rawValue.capitalized)
                .font(.caption2)
                .fontWeight(.semibold)
            
            Text(price)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(iconColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch tier {
        case .none: return "xmark.shield"
        case .basic: return "shield"
        case .plus: return "shield.lefthalf.filled"
        case .premium: return "shield.fill"
        }
    }
    
    private var iconColor: Color {
        switch tier {
        case .none: return .gray
        case .basic: return .blue
        case .plus: return .purple
        case .premium: return .orange
        }
    }
}

// MARK: - Preview

struct PricingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PricingView()
                .environmentObject(HapticFeedbackService.shared)
        }
    }
}