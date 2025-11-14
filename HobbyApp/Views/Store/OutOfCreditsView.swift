import SwiftUI

struct OutOfCreditsView: View {
    @Environment(\.dismiss) private var dismiss

    let requiredAdditionalCredits: Int

    var body: some View {
        NavigationView {
            VStack(spacing: BrandConstants.Spacing.lg) {
                VStack(spacing: BrandConstants.Spacing.md) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 60))
                        .foregroundColor(BrandConstants.Colors.primary)

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
                        // TODO: Navigate to credit purchase screen when implemented
                        dismiss()
                    } label: {
                        Text("Buy Credits")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                }

                VStack(alignment: .leading, spacing: BrandConstants.Spacing.sm) {
                    Label("Coming Soon", systemImage: "sparkles")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(BrandConstants.Colors.secondaryText)
                    Text("Credit purchase integration is coming soon. Please contact support to add credits to your account.")
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
        }
    }
}
