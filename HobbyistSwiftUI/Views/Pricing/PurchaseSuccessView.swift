import SwiftUI
import ConfettiSwiftUI

struct PurchaseSuccessView: View {
    let package: CreditPackage?
    let subscription: Subscription?
    let creditsAdded: Int
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var hapticService: HapticFeedbackService
    @State private var confettiCounter = 0
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success Icon
            successIcon
            
            // Success Message
            successMessage
            
            // Credits Display
            creditsDisplay
            
            // Benefits List
            benefitsList
            
            Spacer()
            
            // Actions
            actionButtons
        }
        .padding()
        .confettiCannon(
            counter: $confettiCounter,
            num: 50,
            colors: [.orange, .yellow, .green, .blue],
            confettiSize: 10,
            rainHeight: 600,
            radius: 400
        )
        .onAppear {
            hapticService.playPaymentSuccess()
            confettiCounter += 1
        }
    }
    
    // MARK: - Success Icon
    
    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.8), Color.green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
            
            Image(systemName: "checkmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.white)
        }
        .shadow(color: .green.opacity(0.3), radius: 10)
    }
    
    // MARK: - Success Message
    
    private var successMessage: some View {
        VStack(spacing: 8) {
            Text("Purchase Successful!")
                .font(.title)
                .fontWeight(.bold)
            
            if let package = package {
                Text("You've purchased \(package.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if let subscription = subscription {
                Text("Welcome to \(subscription.name)!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Credits Display
    
    private var creditsDisplay: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 4) {
                Text("\(creditsAdded)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.orange)
                
                Text("credits")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .offset(y: 12)
            }
            
            if subscription != nil {
                Text("Added to your account")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Refreshes monthly")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            } else {
                Text("Added to your account")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Valid for 6 months")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Benefits List
    
    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if subscription != nil {
                BenefitRow(
                    icon: "arrow.triangle.2.circlepath",
                    text: "Credits roll over up to \(subscription?.rolloverLimit ?? 0)",
                    color: .blue
                )
                
                if subscription?.name.contains("Active") == true || 
                   subscription?.name.contains("Premium") == true ||
                   subscription?.name.contains("Elite") == true {
                    BenefitRow(
                        icon: "bolt.fill",
                        text: "Priority booking access",
                        color: .yellow
                    )
                }
                
                if subscription?.name.contains("Premium") == true ||
                   subscription?.name.contains("Elite") == true {
                    BenefitRow(
                        icon: "star.fill",
                        text: "Exclusive classes & perks",
                        color: .purple
                    )
                }
                
                BenefitRow(
                    icon: "xmark.circle.fill",
                    text: "Cancel anytime",
                    color: .green
                )
            } else {
                BenefitRow(
                    icon: "clock.fill",
                    text: "Use anytime in the next 6 months",
                    color: .blue
                )
                
                BenefitRow(
                    icon: "person.2.fill",
                    text: "Share classes with friends",
                    color: .orange
                )
                
                BenefitRow(
                    icon: "sparkles",
                    text: "Access to all partner studios",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: browseClasses) {
                Text("Browse Classes")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            HStack(spacing: 12) {
                Button(action: inviteFriends) {
                    Label("Invite Friends", systemImage: "person.badge.plus")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                Button(action: shareSuccess) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Actions
    
    private func browseClasses() {
        hapticService.playLight()
        dismiss()
        // Navigate to class list
        NotificationCenter.default.post(name: .navigateToClasses, object: nil)
    }
    
    private func inviteFriends() {
        hapticService.playLight()
        // Show referral sheet
        NotificationCenter.default.post(
            name: .showReferral,
            object: nil,
            userInfo: ["source": "purchase_success"]
        )
        dismiss()
    }
    
    private func shareSuccess() {
        hapticService.playLight()
        showShareSheet = true
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToClasses = Notification.Name("navigateToClasses")
    static let showReferral = Notification.Name("showReferral")
}

// MARK: - Preview

struct PurchaseSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseSuccessView(
            package: CreditPackage.packages[2],
            subscription: nil,
            creditsAdded: 50
        )
        .environmentObject(HapticFeedbackService.shared)
    }
}