import SwiftUI

struct SubscriptionPlanCard: View {
    let plan: Subscription
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 20) {
                // Popular Badge
                if plan.popular {
                    HStack {
                        Text("MOST POPULAR")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(12)
                        
                        Spacer()
                    }
                }
                
                // Plan Header
                VStack(spacing: 8) {
                    Text(plan.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    // Price
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("$\(plan.monthlyPrice, specifier: "%.0f")")
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("CAD")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("/month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .offset(y: -4)
                    }
                    
                    // Credits per month
                    Text("\(plan.monthlyCredits) credits/month")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    // Value calculation
                    Text("$\(pricePerCredit, specifier: "%.2f") per credit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Perks Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)
                        Text("Roll over up to \(plan.rolloverLimit) credits")
                            .font(.subheadline)
                        Spacer()
                    }
                    
                    ForEach(plan.perks, id: \.self) { perk in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                                .offset(y: 2)
                            
                            Text(perk)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 4)
                
                // Annual Savings (if any)
                if plan.monthlyPrice > 50 {
                    annualSavingsSection
                }
                
                // Subscribe Button
                HStack {
                    Text(isSelected ? "Selected" : "Start Subscription")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    if !isSelected {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(12)
                
                // Cancellation note
                Text("Cancel anytime. No commitment.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.1),
                        radius: isSelected ? 15 : 8,
                        x: 0,
                        y: isSelected ? 8 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.blue : (plan.popular ? Color.blue.opacity(0.5) : Color.clear),
                        lineWidth: isSelected ? 3 : (plan.popular ? 2 : 0)
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
    
    private var pricePerCredit: Double {
        plan.monthlyPrice / Double(plan.monthlyCredits)
    }
    
    private var annualSavingsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.orange)
                Text("Annual Savings")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            Text("Save $\(annualSavings, specifier: "%.0f") with annual billing")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var annualSavings: Double {
        // Estimate 15% savings on annual plans
        return plan.monthlyPrice * 12 * 0.15
    }
}

// MARK: - Preview

struct SubscriptionPlanCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(Subscription.plans) { plan in
                    SubscriptionPlanCard(
                        plan: plan,
                        isSelected: plan.popular,
                        onSelect: { }
                    )
                }
            }
            .padding()
        }
    }
}