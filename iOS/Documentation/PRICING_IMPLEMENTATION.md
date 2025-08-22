# Pricing Implementation Guide

## 💰 Quick Reference - Optimal Pricing Structure

### Credit Packages (Pay-As-You-Go)
```
┌─────────────────────────────────────────────────────────┐
│  Package    Credits   Price    Per Credit   Savings     │
├─────────────────────────────────────────────────────────┤
│  Trial         5      $19      $3.80         -          │
│  Casual       15      $49      $3.27        14%         │
│  Regular ⭐   30      $89      $2.97        22%         │
│  Power 💎     60      $159     $2.65        30%         │
│  Studio      100      $239     $2.39        37%         │
└─────────────────────────────────────────────────────────┘
```

### Subscription Plans (Monthly)
```
┌─────────────────────────────────────────────────────────┐
│  Plan       Price/mo  Credits  Perks                    │
├─────────────────────────────────────────────────────────┤
│  Basic      $49       15       Standard access           │
│  Plus ⭐    $79       25       +Rollover, Priority       │
│  Premium    $149      50       +Equipment, Exclusive     │
│  Unlimited  $199      ∞        Everything included       │
└─────────────────────────────────────────────────────────┘
```

## 📊 Revenue Comparison Analysis

### Scenario 1: Casual User (4 classes/month)
- **Drop-in**: 4 × $25 = $100/month
- **Credits**: Buy 15 for $49 (best deal)
- **Subscription**: Basic at $49/month
- **Savings**: 51% vs drop-in pricing

### Scenario 2: Regular User (8 classes/month)
- **Drop-in**: 8 × $25 = $200/month
- **Credits**: Buy 30 for $89 (lasts 3.75 months)
- **Subscription**: Plus at $79/month
- **Savings**: 60% vs drop-in pricing

### Scenario 3: Power User (20 classes/month)
- **Drop-in**: 20 × $25 = $500/month
- **Credits**: Buy 60 for $159 (lasts 3 months)
- **Subscription**: Premium at $149/month
- **Savings**: 70% vs drop-in pricing

## 🎯 Implementation Steps

### Phase 1: MVP Launch (Week 1-2)

```swift
// PricingService.swift
struct PricingService {
    static let packages = [
        CreditPackage(id: "trial", credits: 5, price: 19.00),
        CreditPackage(id: "regular", credits: 30, price: 89.00),
        CreditPackage(id: "power", credits: 60, price: 159.00)
    ]
    
    static let subscriptions = [
        Subscription(id: "plus", monthlyPrice: 79.00, credits: 25)
    ]
}
```

### Phase 2: A/B Testing (Week 3-4)

Test different price points:
- **Group A**: Current pricing
- **Group B**: 10% higher prices
- **Group C**: Fewer tiers (3 instead of 5)

Metrics to track:
- Conversion rate
- Average order value
- Customer lifetime value
- Churn rate

### Phase 3: Dynamic Pricing (Week 5-6)

Implement time-based pricing:
```swift
func calculateCreditsNeeded(for classTime: Date) -> Double {
    let hour = Calendar.current.component(.hour, from: classTime)
    
    switch hour {
    case 6...8, 17...19:  // Peak hours
        return 1.5
    case 11...14:         // Off-peak
        return 0.5
    default:              // Standard
        return 1.0
    }
}
```

## 💳 Stripe Integration

### Create Products & Prices

```bash
# Create products in Stripe
stripe products create \
  --name="30 Class Credits" \
  --description="Our most popular package"

# Create prices
stripe prices create \
  --product=prod_xxx \
  --unit-amount=8900 \
  --currency=usd
```

### Payment Flow

```swift
// StripePaymentService.swift
func purchaseCredits(package: CreditPackage) async throws {
    // 1. Create payment intent
    let intent = try await createPaymentIntent(
        amount: package.price,
        metadata: [
            "type": "credit_package",
            "package_id": package.id,
            "credits": String(package.credits)
        ]
    )
    
    // 2. Present payment sheet
    let result = await presentPaymentSheet(intent)
    
    // 3. On success, add credits
    if case .success = result {
        await addCreditsToUser(package.credits)
    }
}
```

## 📱 UI/UX Best Practices

### Pricing Display Component

```swift
struct PricingCard: View {
    let package: CreditPackage
    let isPopular: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            if isPopular {
                Text("MOST POPULAR")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            
            Text("\(package.credits) Credits")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("$\(package.price, specifier: "%.0f")")
                .font(.largeTitle)
                .fontWeight(.heavy)
            
            Text("$\(package.pricePerCredit, specifier: "%.2f") per class")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if package.savings > 0 {
                Text("Save \(package.savings)%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
            
            Button(action: { selectPackage(package) }) {
                Text("Select")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isPopular ? Color.orange : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPopular ? Color.orange : Color.clear, lineWidth: 2)
        )
    }
}
```

## 🔄 Conversion Optimization

### 1. Anchoring Strategy
Always display packages in this order:
1. Show most expensive first (psychological anchor)
2. Highlight middle option as "Most Popular"
3. Make cheapest option less attractive (fewer features)

### 2. Urgency Tactics
```swift
struct LimitedTimeOffer: View {
    @State private var timeRemaining = 24 * 60 * 60 // 24 hours
    
    var body: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.orange)
            
            Text("Limited Time: 20% off all packages")
                .fontWeight(.medium)
            
            Text(timeString)
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}
```

### 3. Social Proof
```swift
struct SocialProof: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                Text("4.9")
                    .fontWeight(.semibold)
            }
            
            Text("Join 12,847 happy members")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("⚡ 23 people bought this package today")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
}
```

## 📈 Analytics & Tracking

### Key Metrics to Monitor

```swift
struct PricingAnalytics {
    func trackPurchase(package: CreditPackage, user: User) {
        // Track in database
        supabase.from("pricing_analytics")
            .insert([
                "package_id": package.id,
                "user_id": user.id,
                "price": package.price,
                "credits": package.credits,
                "source": "ios_app",
                "ab_test_group": user.abTestGroup
            ])
        
        // Track in analytics service
        Analytics.track("Credit Package Purchased", properties: [
            "package_name": package.name,
            "price": package.price,
            "credits": package.credits,
            "user_segment": user.segment
        ])
    }
}
```

### Weekly Review Dashboard
- Total revenue
- Package distribution (which packages sell most)
- Conversion funnel (views → clicks → purchases)
- Churn analysis
- Credit utilization rate

## 🎁 Promotional Calendar

### Launch Promotions
```swift
enum LaunchPromo {
    case earlyBird    // First 100 users: 50% off
    case referral     // Give 5, Get 5 credits
    case firstClass   // First class free
    case bulkBonus    // Buy 60 credits, get 10 free
}
```

### Seasonal Campaigns
- **January**: New Year Resolution (30% off subscriptions)
- **Summer**: Beach Body Special (Buy 2 months, get 1 free)
- **Black Friday**: Biggest sale (40% off everything)
- **Birthday**: Personal discount on user's birthday

## ✅ Launch Checklist

- [ ] Create Stripe products and prices
- [ ] Implement credit package purchase flow
- [ ] Add subscription management
- [ ] Set up promo code system
- [ ] Implement loyalty rewards
- [ ] Create pricing analytics dashboard
- [ ] A/B test pricing tiers
- [ ] Train customer support on pricing
- [ ] Prepare launch promotions
- [ ] Monitor and optimize based on data

## 🚀 Go-Live Recommendation

**Start Simple**:
1. Launch with 3 credit packages: 5 @ $19, 30 @ $89, 60 @ $159
2. One subscription tier: $79/month for 25 credits
3. First-time user promo: 50% off first purchase
4. Monitor for 30 days, then optimize

**Success Metrics**:
- 30% of users purchase within first week
- 25% choose the middle tier (30 credits)
- 15% convert to subscription
- <10% monthly churn
- 75% credit utilization rate