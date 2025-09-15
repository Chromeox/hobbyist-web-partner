import SwiftUI

struct CreditPackageCard: View {
    let package: CreditPackage
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 16) {
                // Popular Badge
                if package.popular {
                    HStack {
                        Text("MOST POPULAR")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(12)
                        
                        Spacer()
                    }
                }
                
                // Package Info
                VStack(spacing: 12) {
                    Text(package.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(package.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Price Display
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("$\(package.price, specifier: "%.0f")")
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundColor(.primary)
                        
                        Text("CAD")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .offset(y: -8)
                    }
                    
                    // Credits
                    Text("\(package.credits) credits")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    // Savings
                    if let savings = package.savings {
                        VStack(spacing: 4) {
                            Text("Save \(savings)%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                            
                            Text("vs. individual classes")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Price per credit
                    Text("$\(package.pricePerCredit, specifier: "%.2f") per credit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Value proposition
                    valueProposition
                }
                
                // Select Button
                HStack {
                    Text(isSelected ? "Selected" : "Select Package")
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
                .padding(.vertical, 12)
                .background(isSelected ? Color.orange : Color(.systemGray5))
                .cornerRadius(10)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: isSelected ? Color.orange.opacity(0.3) : Color.black.opacity(0.1),
                        radius: isSelected ? 10 : 5,
                        x: 0,
                        y: isSelected ? 5 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.orange : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
    
    private var valueProposition: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            Text(estimatedClasses)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var estimatedClasses: String {
        // Estimate classes based on credit amount
        // Assuming average class costs 8-12 credits
        let minClasses = package.credits / 12
        let maxClasses = package.credits / 8
        
        if minClasses == maxClasses {
            return "≈ \(minClasses) classes"
        } else {
            return "≈ \(minClasses)-\(maxClasses) classes"
        }
    }
}

// MARK: - Preview

struct CreditPackageCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(CreditPackage.packages) { package in
                    CreditPackageCard(
                        package: package,
                        isSelected: package.popular,
                        onSelect: { }
                    )
                }
            }
            .padding()
        }
    }
}