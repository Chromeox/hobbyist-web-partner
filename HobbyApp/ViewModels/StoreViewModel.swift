import Foundation
import Combine
import StoreKit

@MainActor
final class StoreViewModel: ObservableObject {
    @Published var creditPacks: [Product] = []
    @Published var subscriptions: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let storeKitManager: StoreKitManager
    private var cancellables = Set<AnyCancellable>()

    init(storeKitManager: StoreKitManager = .shared) {
        self.storeKitManager = storeKitManager
        setupBindings()
    }

    func fetchProducts() async {
        guard !isLoading else { return }
        await performLoadingTask {
            await storeKitManager.fetchProducts()
        }
    }

    func purchase(_ product: Product) async {
        await performLoadingTask {
            do {
                try await storeKitManager.purchase(product)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func restorePurchases() async {
        await performLoadingTask {
            do {
                try await storeKitManager.restorePurchases()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func setupBindings() {
        storeKitManager.$creditPacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                self?.creditPacks = products
            }
            .store(in: &cancellables)

        storeKitManager.$subscriptions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                self?.subscriptions = products
            }
            .store(in: &cancellables)

        storeKitManager.$purchasedProductIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] productIDs in
                self?.purchasedProductIDs = productIDs
            }
            .store(in: &cancellables)
    }

    private func performLoadingTask(_ operation: @escaping () async -> Void) async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true

        await operation()

        isLoading = false
    }
}
