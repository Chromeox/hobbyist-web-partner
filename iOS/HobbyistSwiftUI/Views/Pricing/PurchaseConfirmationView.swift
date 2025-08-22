import SwiftUI
import StoreKit

struct PurchaseConfirmationView: View {
    let package: CreditPackage?
    let subscription: Subscription?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var hapticService: HapticFeedbackService
    @StateObject private var stripeService = StripePaymentService.shared
    @StateObject private var iapService = IAPService.shared
    @StateObject private var pricingService = PricingService.shared
    
    @State private var selectedPaymentMethod: PaymentMethod = .applePay
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var addInsurance = false
    @State private var selectedInsurance: CreditInsurance = .none
    
    enum PaymentMethod: String, CaseIterable {
        case applePay = "Apple Pay"
        case creditCard = "Credit Card"
        
        var icon: String {
            switch self {
            case .applePay: return "applelogo"
            case .creditCard: return "creditcard"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Order Summary
                    orderSummarySection
                    
                    // Insurance Upsell
                    if package != nil {
                        insuranceUpsellSection
                    }
                    
                    // Payment Method Selection
                    paymentMethodSection
                    
                    // Price Breakdown
                    priceBreakdownSection
                    
                    // Terms
                    termsSection
                    
                    // Purchase Button
                    purchaseButton
                }
                .padding()
            }
            .navigationTitle("Confirm Purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        hapticService.playLight()
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showSuccess) {
                PurchaseSuccessView(
                    package: package,
                    subscription: subscription,
                    creditsAdded: calculateTotalCredits()
                )
            }
            .disabled(isProcessing)
            .overlay {
                if isProcessing {
                    ProcessingOverlay()
                }
            }
        }
    }
    
    // MARK: - Order Summary
    
    private var orderSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Summary")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                if let package = package {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(package.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("\(package.credits) credits")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let savings = package.savings {
                                Text("Save \(savings)%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                        
                        Text("$\(package.price, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                } else if let subscription = subscription {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(subscription.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("\(subscription.monthlyCredits) credits/month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Rolls over \(subscription.rolloverLimit) credits")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("$\(subscription.monthlyPrice, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("/month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Seasonal bonus
                if let bonus = getSeasonalBonus(), bonus > 0 {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Winter Bonus: +\(Int(Double(package?.credits ?? 0) * bonus)) credits!")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Insurance Upsell
    
    private var insuranceUpsellSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(.blue)
                Text("Protect Your Credits")
                    .font(.headline)
            }
            
            Text("Never lose unused credits with our insurance plans")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach([CreditInsurance.none, .basic, .plus, .premium], id: \.self) { insurance in
                    HStack {
                        Image(systemName: selectedInsurance == insurance ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedInsurance == insurance ? .blue : .gray)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(insuranceName(for: insurance))
                                    .font(.subheadline)
                                    .fontWeight(insurance == .plus ? .semibold : .regular)
                                
                                if insurance == .plus {
                                    Text("RECOMMENDED")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue)
                                        .cornerRadius(4)
                                }
                            }
                            
                            if insurance != .none {
                                Text(insuranceDescription(for: insurance))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(insurancePrice(for: insurance))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hapticService.playLight()
                        withAnimation {
                            selectedInsurance = insurance
                            addInsurance = insurance != .none
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Payment Method
    
    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    PaymentMethodButton(
                        method: method,
                        isSelected: selectedPaymentMethod == method
                    ) {
                        hapticService.playLight()
                        selectedPaymentMethod = method
                    }
                }
            }
        }
    }
    
    // MARK: - Price Breakdown
    
    private var priceBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price Breakdown")
                .font(.headline)
            
            VStack(spacing: 8) {
                // Main item
                HStack {
                    Text(package?.name ?? subscription?.name ?? "")
                    Spacer()
                    Text("$\(basePrice(), specifier: "%.2f")")
                }
                .font(.subheadline)
                
                // Insurance if selected
                if addInsurance && selectedInsurance != .none {
                    HStack {
                        Text("Credit Insurance (\(selectedInsurance.rawValue.capitalized))")
                        Spacer()
                        Text("+$\(selectedInsurance.monthlyPrice, specifier: "%.2f")/mo")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Total
                HStack {
                    Text("Total")
                        .fontWeight(.semibold)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("$\(calculateTotal(), specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        if subscription != nil || (addInsurance && selectedInsurance != .none) {
                            Text("per month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Terms
    
    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if subscription != nil {
                Label("Cancel anytime", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Label("Credits refresh monthly", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Label("Unused credits roll over up to \(subscription?.rolloverLimit ?? 0)", systemImage: "arrow.right.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            } else {
                Label("Credits valid for 6 months", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("One-time purchase", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            if addInsurance && selectedInsurance != .none {
                Label("Insurance can be cancelled anytime", systemImage: "shield")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        Button(action: processPurchase) {
            HStack {
                if selectedPaymentMethod == .applePay {
                    Image(systemName: "applelogo")
                }
                
                Text(isProcessing ? "Processing..." : "Complete Purchase")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isProcessing)
    }
    
    // MARK: - Helper Functions
    
    private func processPurchase() {
        hapticService.playMedium()
        isProcessing = true
        
        Task {
            do {
                if selectedPaymentMethod == .applePay {
                    // Use Apple Pay via StoreKit
                    if let package = package,
                       let identifier = ProductIdentifier.allCases.first(where: { 
                           ProductDetails.details(for: $0)?.credits == package.credits 
                       }) {
                        try await iapService.purchaseCreditPackage(identifier)
                    } else if let subscription = subscription,
                              let identifier = ProductIdentifier.allCases.first(where: {
                                  ProductDetails.details(for: $0)?.name == subscription.name
                              }) {
                        try await iapService.subscribeToMembership(identifier)
                    }
                    
                    // Add insurance if selected
                    if addInsurance && selectedInsurance != .none {
                        let insuranceId = insuranceIdentifier(for: selectedInsurance)
                        try await iapService.purchaseInsurance(insuranceId)
                    }
                } else {
                    // Use Stripe for credit card
                    // This would open the Stripe payment sheet
                    // Implementation depends on your Stripe setup
                }
                
                hapticService.playPaymentSuccess()
                showSuccess = true
                
            } catch {
                hapticService.playError()
                errorMessage = error.localizedDescription
            }
            
            isProcessing = false
        }
    }
    
    private func basePrice() -> Double {
        return package?.price ?? subscription?.monthlyPrice ?? 0
    }
    
    private func calculateTotal() -> Double {
        var total = basePrice()
        
        if addInsurance && selectedInsurance != .none {
            if subscription != nil {
                total += selectedInsurance.monthlyPrice
            }
        }
        
        return total
    }
    
    private func calculateTotalCredits() -> Int {
        let baseCredits = package?.credits ?? subscription?.monthlyCredits ?? 0
        if let bonus = getSeasonalBonus() {
            return baseCredits + Int(Double(baseCredits) * bonus)
        }
        return baseCredits
    }
    
    private func getSeasonalBonus() -> Double? {
        let month = Calendar.current.component(.month, from: Date())
        if month >= 11 || month <= 2 {
            return 0.2 // 20% winter bonus
        }
        return nil
    }
    
    private func insuranceName(for insurance: CreditInsurance) -> String {
        switch insurance {
        case .none: return "No Insurance"
        case .basic: return "Basic Insurance"
        case .plus: return "Plus Insurance"
        case .premium: return "Premium Insurance"
        }
    }
    
    private func insuranceDescription(for insurance: CreditInsurance) -> String {
        switch insurance {
        case .none: return ""
        case .basic: return "Credits rollover 1 extra month"
        case .plus: return "Unlimited rollover, gift credits, pause anytime"
        case .premium: return "Everything in Plus + priority booking + gift cards"
        }
    }
    
    private func insurancePrice(for insurance: CreditInsurance) -> String {
        switch insurance {
        case .none: return "No charge"
        case .basic: return "+$3/mo"
        case .plus: return "+$5/mo"
        case .premium: return "+$8/mo"
        }
    }
    
    private func insuranceIdentifier(for insurance: CreditInsurance) -> ProductIdentifier {
        switch insurance {
        case .none: return .basicInsurance // Shouldn't happen
        case .basic: return .basicInsurance
        case .plus: return .plusInsurance
        case .premium: return .premiumInsurance
        }
    }
}

// MARK: - Supporting Views

struct PaymentMethodButton: View {
    let method: PurchaseConfirmationView.PaymentMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: method.icon)
                    .font(.title2)
                
                Text(method.rawValue)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                
                Text("Processing Payment...")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}

// MARK: - Preview

struct PurchaseConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseConfirmationView(
            package: CreditPackage.packages[2],
            subscription: nil
        )
        .environmentObject(HapticFeedbackService.shared)
    }
}