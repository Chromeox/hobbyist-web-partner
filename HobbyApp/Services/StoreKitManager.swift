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
        guard let url = URL(string: "https://mcjqvdzdhtcvbrejvrtp.supabase.co/functions/v1/validate-receipt") else {
            throw BackendError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Configuration.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        let payload = ["receipt": receiptJWS]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw BackendError.validationFailed(statusCode: httpResponse.statusCode)
        }
        
        // Parse response to ensure validation succeeded
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let success = result?["success"] as? Bool, success else {
            throw BackendError.receiptInvalid
        }
    }
}

enum BackendError: LocalizedError {
    case invalidURL
    case invalidResponse
    case validationFailed(statusCode: Int)
    case receiptInvalid
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL configuration"
        case .invalidResponse:
            return "Invalid response from backend"
        case .validationFailed(let statusCode):
            return "Receipt validation failed with status code \(statusCode)"
        case .receiptInvalid:
            return "Receipt validation returned invalid"
        }
    }
}
