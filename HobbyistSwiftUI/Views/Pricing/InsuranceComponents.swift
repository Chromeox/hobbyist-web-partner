import SwiftUI

// MARK: - Insurance Tier Badge

struct InsuranceTierBadge: View {
    let tier: CreditInsurance
    let price: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
            
            Text(tierName)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(price)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var tierName: String {
        switch tier {
        case .basic: return "Basic"
        case .plus: return "Plus"
        case .premium: return "Premium"
        case .none: return "None"
        }
    }
    
    private var iconName: String {
        switch tier {
        case .basic: return "shield"
        case .plus: return "shield.fill"
        case .premium: return "shield.checkered"
        case .none: return "xmark.shield"
        }
    }
    
    private var color: Color {
        switch tier {
        case .basic: return .blue
        case .plus: return .green
        case .premium: return .purple
        case .none: return .gray
        }
    }
}

// MARK: - Insurance Info View

struct InsuranceInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Benefits Comparison
                    benefitsComparisonSection
                    
                    // Why Insurance?
                    whyInsuranceSection
                    
                    // How It Works
                    howItWorksSection
                    
                    // FAQ
                    faqSection
                }
                .padding()
            }
            .navigationTitle("Credit Insurance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Never Lose Your Credits")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Credit Insurance protects your investment and gives you peace of mind when life gets in the way of your hobbies.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Benefits Comparison
    
    private var benefitsComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Compare Plans")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Feature")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Basic")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(width: 60)
                    
                    Text("Plus")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(width: 60)
                    
                    Text("Premium")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(width: 60)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Features
                ComparisonRow(
                    feature: "Credit Rollover",
                    basic: "1 month",
                    plus: "Unlimited",
                    premium: "Unlimited"
                )
                
                ComparisonRow(
                    feature: "Emergency Pause",
                    basic: "1x/year",
                    plus: "Anytime",
                    premium: "Anytime"
                )
                
                ComparisonRow(
                    feature: "Gift Credits",
                    basic: "✗",
                    plus: "✓",
                    premium: "✓"
                )
                
                ComparisonRow(
                    feature: "Credit Refunds",
                    basic: "✗",
                    plus: "1x/year",
                    premium: "Unlimited"
                )
                
                ComparisonRow(
                    feature: "Priority Booking",
                    basic: "✗",
                    plus: "✗",
                    premium: "✓"
                )
                
                ComparisonRow(
                    feature: "Gift Card Conversion",
                    basic: "✗",
                    plus: "✗",
                    premium: "✓"
                )
                
                // Pricing
                HStack {
                    Text("Monthly Price")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("$3")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 60)
                    
                    Text("$5")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .frame(width: 60)
                    
                    Text("$8")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                        .frame(width: 60)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Why Insurance
    
    private var whyInsuranceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why Get Credit Insurance?")
                .font(.headline)
            
            VStack(spacing: 12) {
                ReasonCard(
                    icon: "calendar.badge.exclamationmark",
                    title: "Life Happens",
                    description: "Work trips, family emergencies, illness - sometimes you can't use all your credits.",
                    color: .orange
                )
                
                ReasonCard(
                    icon: "heart.fill",
                    title: "Peace of Mind",
                    description: "Buy credits confidently knowing you're protected if plans change.",
                    color: .red
                )
                
                ReasonCard(
                    icon: "gift.fill",
                    title: "Share the Love",
                    description: "Gift unused credits to friends or convert them to gift cards.",
                    color: .green
                )
                
                ReasonCard(
                    icon: "bolt.fill",
                    title: "Priority Access",
                    description: "Premium members get first access to popular classes and workshops.",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - How It Works
    
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How It Works")
                .font(.headline)
            
            VStack(spacing: 16) {
                StepCard(
                    number: 1,
                    title: "Add Insurance",
                    description: "Choose your plan when purchasing credits or subscribing."
                )
                
                StepCard(
                    number: 2,
                    title: "Use Credits Normally",
                    description: "Book classes and workshops as usual - no changes to your routine."
                )
                
                StepCard(
                    number: 3,
                    title: "Get Protected",
                    description: "If life gets in the way, your insurance kicks in to protect your credits."
                )
            }
        }
    }
    
    // MARK: - FAQ
    
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Frequently Asked Questions")
                .font(.headline)
            
            VStack(spacing: 12) {
                FAQItem(
                    question: "Can I cancel my insurance?",
                    answer: "Yes! You can cancel anytime. Your current credits remain protected until they expire or are used."
                )
                
                FAQItem(
                    question: "What counts as an 'emergency pause'?",
                    answer: "Any situation preventing you from attending classes: illness, work travel, family emergencies, or other life events."
                )
                
                FAQItem(
                    question: "How do credit refunds work?",
                    answer: "Plus and Premium members can request refunds for unused credits. Refunds are processed back to your original payment method."
                )
                
                FAQItem(
                    question: "Can I upgrade or downgrade my plan?",
                    answer: "Yes! Changes take effect at your next billing cycle."
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct ComparisonRow: View {
    let feature: String
    let basic: String
    let plus: String
    let premium: String
    
    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(basic)
                .font(.caption)
                .frame(width: 60)
            
            Text(plus)
                .font(.caption)
                .fontWeight(plus == "✓" ? .bold : .regular)
                .foregroundColor(plus == "✓" ? .green : .primary)
                .frame(width: 60)
            
            Text(premium)
                .font(.caption)
                .fontWeight(premium == "✓" ? .bold : .regular)
                .foregroundColor(premium == "✓" ? .purple : .primary)
                .frame(width: 60)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

struct ReasonCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StepCard: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Previews

struct InsuranceComponents_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HStack {
                InsuranceTierBadge(tier: .basic, price: "$3/mo")
                InsuranceTierBadge(tier: .plus, price: "$5/mo")
                InsuranceTierBadge(tier: .premium, price: "$8/mo")
            }
            .padding()
            .previewDisplayName("Insurance Badges")
            
            InsuranceInfoView()
                .previewDisplayName("Insurance Info")
        }
    }
}