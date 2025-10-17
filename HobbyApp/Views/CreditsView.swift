import SwiftUI

struct CreditsView: View {
    @StateObject private var creditService = CreditService.shared
    @EnvironmentObject var hapticService: HapticFeedbackService
    @State private var showingPurchaseView = false
    @State private var selectedTab = 0
    @State private var purchaseResultMessage = ""
    @State private var showingPurchaseResult = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Credit Balance Section
                    creditBalanceSection
                    
                    // Rollover Information
                    if creditService.hasActiveSubscription {
                        rolloverSection
                    }
                    
                    // Tab Selector
                    tabSelector
                    
                    // Content based on selected tab
                    if selectedTab == 0 {
                        creditHistorySection
                    } else {
                        upcomingExpirations
                    }
                }
                .padding()
            }
            .navigationTitle("My Credits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Buy Credits") {
                        hapticService.playLight()
                        showingPurchaseView = true
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .sheet(isPresented: $showingPurchaseView) {
                CreditPurchaseView()
            }
            .onAppear {
                creditService.refreshCredits()
            }
            .task {
                await creditService.loadCreditPacks(force: true)
            }
            .onChange(of: creditService.purchaseMessage) { newValue in
                guard let message = newValue else { return }
                purchaseResultMessage = message
                showingPurchaseResult = true
                creditService.purchaseMessage = nil
            }
            .alert(purchaseResultMessage, isPresented: $showingPurchaseResult) {
                Button("OK") { showingPurchaseResult = false }
            }
        }
    }
    
    // MARK: - Credit Balance Section
    
    private var creditBalanceSection: some View {
        VStack(spacing: 20) {
            // Total Credits Card
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Total Credits")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(creditService.totalCredits)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                    
                    if creditService.totalCredits > 0 {
                        Text("≈ \(creditService.estimatedClasses) classes available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Credit Breakdown
                if creditService.hasRolloverCredits {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Month")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(creditService.currentMonthCredits)")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: "plus")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Rollover")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(creditService.rolloverCredits)")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
            )
            
            // Quick Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                CreditsStatCard(
                    title: "This Month",
                    value: "\(creditService.creditsUsedThisMonth)",
                    subtitle: "credits used",
                    icon: "minus.circle.fill",
                    color: .red
                )
                
                CreditsStatCard(
                    title: "Savings",
                    value: String(format: "$%.0f", creditService.estimatedSavings),
                    subtitle: "vs drop-in",
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - Rollover Section
    
    private var rolloverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.orange)
                Text("Credit Rollover")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Your \(creditService.subscriptionPlanName) plan includes \(creditService.rolloverPercentage)% rollover")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if creditService.rolloverCredits > 0 {
                    HStack {
                        Text("Current rollover credits:")
                            .font(.subheadline)
                        Spacer()
                        Text("\(creditService.rolloverCredits) credits")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
                
                if let nextRolloverDate = creditService.nextRolloverDate {
                    HStack {
                        Text("Next rollover:")
                            .font(.subheadline)
                        Spacer()
                        Text(nextRolloverDate, style: .date)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        Picker("Credit History", selection: $selectedTab) {
            Text("Recent Activity").tag(0)
            Text("Expirations").tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedTab) { _ in
            hapticService.playSelection()
        }
    }
    
    // MARK: - Credit History Section
    
    private var creditHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
            
            if creditService.creditHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No recent activity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(creditService.creditHistory) { transaction in
                    CreditTransactionRow(transaction: transaction)
                }
            }
        }
    }
    
    // MARK: - Upcoming Expirations
    
    private var upcomingExpirations: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Credit Expirations")
                .font(.headline)
            
            if creditService.upcomingExpirations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text("No credits expiring soon")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Your credits are protected!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(creditService.upcomingExpirations, id: \.id) { expiration in
                    ExpirationRow(expiration: expiration)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CreditsStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CreditTransactionRow: View {
    let transaction: CreditTransactionDisplay
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.iconName)
                .font(.title3)
                .foregroundColor(transaction.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.subheadline)
                
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.amountText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.color)
                
                Text("\(transaction.balanceAfter) total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ExpirationRow: View {
    let expiration: CreditExpiration
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.title3)
                .foregroundColor(expiration.isUrgent ? .red : .orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(expiration.credits) credits expiring")
                    .font(.subheadline)
                
                Text(expiration.expirationDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if expiration.isUrgent {
                Text("Urgent")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Mock Credit Service Data Models

struct CreditExpiration: Identifiable {
    let id = UUID()
    let credits: Int
    let expirationDate: Date
    
    var isUrgent: Bool {
        expirationDate.timeIntervalSinceNow < 7 * 24 * 60 * 60 // 7 days
    }
}

// MARK: - Preview

struct CreditsView_Previews: PreviewProvider {
    static var previews: some View {
        CreditsView()
            .environmentObject(HapticFeedbackService.shared)
    }
}