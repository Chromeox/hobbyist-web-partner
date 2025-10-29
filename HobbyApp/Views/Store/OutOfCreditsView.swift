import SwiftUI

struct OutOfCreditsView: View {
    @Environment(\.dismiss) private var dismiss

    let requiredAdditionalCredits: Int
    @State private var navigationTarget: StoreCategory?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("You're out of credits")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("You need \(requiredAdditionalCredits) more credit\(requiredAdditionalCredits == 1 ? "" : "s") to complete this booking.")
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 16) {
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

                VStack(alignment: .leading, spacing: 8) {
                    Label("Need help deciding?", systemImage: "lightbulb")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Subscriptions keep you topped up automatically, while credit packs are perfect for occasional bookings.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

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
                            .font(.body.weight(.semibold))
                    }
                    .tint(.primary)
                }
            }
            .navigationDestination(item: $navigationTarget) { destination in
                StoreView(initialCategory: destination)
            }
        }
    }
}
