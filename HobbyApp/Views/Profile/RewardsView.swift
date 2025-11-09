import SwiftUI

struct RewardsView: View {
    private let referralCode = "HOBBY123"
    @State private var isPresentingShareSheet = false

    private let additionalRewards: [RewardAction] = [
        RewardAction(title: "Write a Review", detail: "Earn 2 credits for each approved review.", icon: "star.bubble"),
        RewardAction(title: "Host a Workshop", detail: "Host your first class and get a 20 credit bonus.", icon: "person.3.sequence"),
        RewardAction(title: "Complete Your Profile", detail: "Fill out your profile to unlock 5 extra credits.", icon: "person.crop.circle.badge.checkmark")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                referralSection
                otherWaysSection
            }
            .padding()
        }
        .navigationTitle("Rewards")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingShareSheet) {
            ShareSheet(items: ["Join me on HobbyApp! Use my referral code \(referralCode) to get bonus credits."])
        }
    }

    private var referralSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Share your referral code")
                .font(BrandConstants.Typography.headline)

            Text("Invite friends and earn rewards together. When a friend signs up and makes their first purchase, you both receive 15 free credits.")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Text(referralCode)
                    .font(BrandConstants.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                    .textCase(.uppercase)
                Spacer()
                Button {
                    isPresentingShareSheet = true
                } label: {
                    Label("Share Code", systemImage: "square.and.arrow.up")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(BrandConstants.CornerRadius.md)
    }

    private var otherWaysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Other ways to earn")
                .font(BrandConstants.Typography.headline)

            ForEach(additionalRewards) { reward in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: reward.icon)
                        .font(BrandConstants.Typography.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(reward.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(reward.detail)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
}

private struct RewardAction: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
}
