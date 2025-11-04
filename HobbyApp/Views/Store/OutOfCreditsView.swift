import SwiftUI

struct OutOfCreditsView: View {
    @Environment(\.dismiss) private var dismiss

    let requiredAdditionalCredits: Int
    @State private var navigationTarget: StoreCategory?

    var body: some View {
        NavigationStack {
            VStack(spacing: BrandConstants.Spacing.lg) {
                VStack(spacing: BrandConstants.Spacing.md) {
                    Text("You're out of credits")
                        .font(BrandConstants.Typography.title2)
                        .fontWeight(.semibold)

                    Text("You need \(requiredAdditionalCredits) more credit\(requiredAdditionalCredits == 1 ? "" : "s") to complete this booking.")
                        .multilineTextAlignment(.center)
                        .font(BrandConstants.Typography.body)
                        .foregroundColor(BrandConstants.Colors.secondaryText)
                }
                .padding(.top, BrandConstants.Spacing.xl)

                VStack(spacing: BrandConstants.Spacing.md) {
                    Button {
                        navigationTarget = .subscriptions
                    } label: {
                        Text("Subscribe & Save")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        navigationTarget = .creditPacks
                    } label: {
                        Text("Buy a Credit Pack")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: BrandConstants.Spacing.sm) {
                    Label("Need help deciding?", systemImage: "lightbulb")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(BrandConstants.Colors.secondaryText)
                    Text("Subscriptions keep you topped up automatically, while credit packs are perfect for occasional bookings.")
                        .font(BrandConstants.Typography.footnote)
                        .foregroundColor(BrandConstants.Colors.secondaryText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(BrandConstants.CornerRadius.md)

                Spacer()
            }
            .padding()
            .navigationTitle("Get More Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(BrandConstants.Typography.headline)
                    }
                    .tint(BrandConstants.Colors.text)
                }
            }
            .navigationDestination(item: $navigationTarget) { destination in
                StoreView(initialCategory: destination)
            }
        }
    }
}
