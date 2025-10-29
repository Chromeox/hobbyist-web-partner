import Foundation
import StoreKit

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published private(set) var creditPacks: [Product] = []
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []

    private let creditPackProductIDs: Set<String> = [
        "com.hobbyist.bookingapp.credits.pack1",
        "com.hobbyist.bookingapp.credits.pack2",
        "com.hobbyist.bookingapp.credits.pack3"
    ]

    private let subscriptionProductIDs: Set<String> = [
        "com.hobbyist.bookingapp.subscription.monthly",
        "com.hobbyist.bookingapp.subscription.yearly"
    ]

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        updateListenerTask = listenForTransactions()

        Task {
            await fetchProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func fetchProducts() async {
        do {
            let allProductIDs = creditPackProductIDs.union(subscriptionProductIDs)
            let products = try await Product.products(for: Array(allProductIDs))

            creditPacks = products
                .filter { creditPackProductIDs.contains($0.id) }
                .sorted(by: { $0.price < $1.price })

            subscriptions = products
                .filter { subscriptionProductIDs.contains($0.id) }
                .sorted(by: { $0.price < $1.price })
        } catch {
            print("StoreKitManager: Failed to fetch products - \(error.localizedDescription)")
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verificationResult):
            let transaction = try checkVerified(verificationResult)
            await handle(transaction: transaction)
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }

            for await result in Transaction.updates {
                await self.handleTransactionUpdate(result)
            }
        }
    }

    private func handleTransactionUpdate(_ transactionResult: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(transactionResult)
            await handle(transaction: transaction)
        } catch {
            print("StoreKitManager: Transaction verification failed - \(error.localizedDescription)")
        }
    }

    private func handle(transaction: Transaction) async {
        do {
            try await deliverPurchasedContent(for: transaction)
            await transaction.finish()
            await updatePurchasedProducts()
        } catch {
            print("StoreKitManager: Failed to process transaction \(transaction.id) - \(error.localizedDescription)")
        }
    }

    private func deliverPurchasedContent(for transaction: Transaction) async throws {
        guard let receiptJWS = transaction.jwsRepresentation else {
            throw StoreKitManagerError.missingReceipt
        }

        try await BackendService.validateReceipt(receiptJWS)

        if transaction.productType == .nonConsumable || transaction.productType == .autoRenewable {
            purchasedProductIDs.insert(transaction.productID)
        }
    }

    private func updatePurchasedProducts() async {
        var ownedProductIDs = Set<String>()

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .nonConsumable || transaction.productType == .autoRenewable {
                    ownedProductIDs.insert(transaction.productID)
                }
            }
        }

        purchasedProductIDs = ownedProductIDs
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let verificationError):
            throw StoreKitManagerError.failedVerification(verificationError.localizedDescription)
        }
    }
}

enum StoreKitManagerError: LocalizedError {
    case missingReceipt
    case failedVerification(String)

    var errorDescription: String? {
        switch self {
        case .missingReceipt:
            return "The transaction receipt could not be retrieved."
        case .failedVerification(let message):
            return "The App Store could not verify this purchase: \(message)"
        }
    }
}

enum BackendService {
    static func validateReceipt(_ receiptJWS: String) async throws {
        // Placeholder for backend validation. Replace with real network call when ready.
        await Task.sleep(100_000_000) // Simulate latency
    }
}
