import SwiftUI
import StoreKit

enum StoreCategory: String, CaseIterable, Identifiable {
    case creditPacks = "Credit Packs"
    case subscriptions = "Subscriptions"

    var id: String { rawValue }

    var title: String { rawValue }
}

struct StoreView: View {
    @StateObject private var viewModel: StoreViewModel
    @State private var selectedCategory: StoreCategory

    private let bestValueSubscriptionID = "com.hobbyist.bookingapp.subscription.yearly"

    init(viewModel: StoreViewModel = StoreViewModel(), initialCategory: StoreCategory = .creditPacks) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedCategory = State(initialValue: initialCategory)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("Product Category", selection: $selectedCategory) {
                    ForEach(StoreCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                .pickerStyle(.segmented)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BrandConstants.Typography.footnote)
                        .foregroundColor(BrandConstants.Colors.error)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }

                ScrollView {
                    LazyVStack(spacing: 16) {
                        switch selectedCategory {
                        case .creditPacks:
                            creditPackSection
                        case .subscriptions:
                            subscriptionSection
                        }
                    }
                    .padding(.vertical, 4)
                }

                Button {
                    Task { await viewModel.restorePurchases() }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                        Text("Restore Purchases")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)
            }
            .padding()
            .navigationTitle("HobbyApp Store")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.fetchProducts()
            }
        }
    }

    @ViewBuilder
    private var creditPackSection: some View {
        if viewModel.creditPacks.isEmpty {
            placeholderState(text: "Credit packs are loading. Please try again in a moment.")
        } else {
            ForEach(viewModel.creditPacks, id: \.id) { product in
                StoreProductCard(
                    product: product,
                    actionTitle: "Purchase",
                    isProcessing: viewModel.isLoading
                ) {
                    Task { await viewModel.purchase(product) }
                }
            }
        }
    }

    @ViewBuilder
    private var subscriptionSection: some View {
        if viewModel.subscriptions.isEmpty {
            placeholderState(text: "Subscriptions are loading. Please try again in a moment.")
        } else {
            ForEach(viewModel.subscriptions, id: \.id) { product in
                StoreProductCard(
                    product: product,
                    actionTitle: viewModel.purchasedProductIDs.contains(product.id) ? "Active" : "Subscribe",
                    isProcessing: viewModel.isLoading,
                    isHighlighted: product.id == bestValueSubscriptionID,
                    isOwned: viewModel.purchasedProductIDs.contains(product.id)
                ) {
                    guard !viewModel.purchasedProductIDs.contains(product.id) else { return }
                    Task { await viewModel.purchase(product) }
                }
            }
        }
    }

    private func placeholderState(text: String) -> some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(text)
                .font(BrandConstants.Typography.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(BrandConstants.Colors.secondaryText)
        }
        .padding(.vertical, 40)
    }
}

private struct StoreProductCard: View {
    let product: Product
    let actionTitle: String
    let isProcessing: Bool
    var isHighlighted: Bool = false
    var isOwned: Bool = false
    let action: () -> Void

    private var borderColor: Color {
        isHighlighted ? Color.accentColor : Color(.systemGray5)
    }

    private var backgroundColor: Color {
        isHighlighted ? Color.accentColor.opacity(0.08) : Color(.systemGray6)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isHighlighted {
                Text("Most Popular")
                    .font(BrandConstants.Typography.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.18))
                    )
                    .foregroundColor(.accentColor)
            }

            HStack {
                Text(product.displayName)
                    .font(BrandConstants.Typography.headline)
                    .foregroundColor(BrandConstants.Colors.text)

                Spacer()

                if isOwned {
                    Label("Owned", systemImage: "checkmark.seal.fill")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(BrandConstants.Colors.success)
                        .labelStyle(.titleAndIcon)
                }
            }

            Text(product.description)
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(BrandConstants.Colors.secondaryText)

            Text(product.displayPrice)
                .font(BrandConstants.Typography.title3)
                .fontWeight(.semibold)

            Button(action: action) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .tint(BrandConstants.Colors.surface)
                    }
                    Text(actionTitle)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing || isOwned)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                .stroke(borderColor, lineWidth: isHighlighted ? 2 : 1)
        )
    }
}
