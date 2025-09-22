import Foundation
import StoreKit
import Combine
import UserNotifications
import UIKit

// MARK: - In-App Purchase Service
@MainActor
class IAPService: ObservableObject {
    static let shared = IAPService()
    
    // Published properties
    @Published var products: [Product] = []
    @Published var purchasedProducts: Set<ProductIdentifier> = []
    @Published var activeSubscriptions: [Product.SubscriptionInfo.Status] = []
    @Published var isLoading = false
    @Published var purchaseError: Error?
    
    // Private properties
    private var updateListenerTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        
        do {
            let productIdentifiers = ProductIdentifier.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIdentifiers)
            
            // Sort products by type and price
            products.sort { first, second in
                let firstDetails = ProductDetails.details(for: ProductIdentifier(rawValue: first.id)!)
                let secondDetails = ProductDetails.details(for: ProductIdentifier(rawValue: second.id)!)
                
                if firstDetails?.identifier.productType != secondDetails?.identifier.productType {
                    return firstDetails?.identifier.productType == .creditPackage
                }
                
                return first.price < second.price
            }
            
            isLoading = false
        } catch {
            print("Failed to load products: \(error)")
            purchaseError = error
            isLoading = false
        }
    }
    
    // MARK: - Purchase Functions
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            // Update customer product status
            await updateCustomerProductStatus()
            
            // Sync with backend
            await syncPurchaseWithBackend(transaction, product: product)
            
            // Finish transaction
            await transaction.finish()
            
            return transaction
            
        case .userCancelled:
            return nil
            
        case .pending:
            // Handle pending transaction (parental controls, etc.)
            throw PurchaseError.pending
            
        @unknown default:
            throw PurchaseError.unknown
        }
    }
    
    func purchaseCreditPackage(_ identifier: ProductIdentifier) async throws {
        guard let product = products.first(where: { $0.id == identifier.rawValue }) else {
            throw PurchaseError.productNotFound
        }
        
        isLoading = true
        
        do {
            let transaction = try await purchase(product)
            
            if let transaction = transaction {
                // Award credits immediately
                await awardCredits(for: identifier, transaction: transaction)
            }
            
            isLoading = false
        } catch {
            purchaseError = error
            isLoading = false
            throw error
        }
    }
    
    func subscribeToMembership(_ identifier: ProductIdentifier) async throws {
        guard let product = products.first(where: { $0.id == identifier.rawValue }) else {
            throw PurchaseError.productNotFound
        }
        
        isLoading = true
        
        do {
            let transaction = try await purchase(product)
            
            if let transaction = transaction {
                // Activate subscription
                await activateSubscription(for: identifier, transaction: transaction)
            }
            
            isLoading = false
        } catch {
            purchaseError = error
            isLoading = false
            throw error
        }
    }
    
    func purchaseInsurance(_ identifier: ProductIdentifier) async throws {
        guard let product = products.first(where: { $0.id == identifier.rawValue }) else {
            throw PurchaseError.productNotFound
        }
        
        isLoading = true
        
        do {
            let transaction = try await purchase(product)
            
            if let transaction = transaction {
                // Activate insurance
                await activateInsurance(for: identifier, transaction: transaction)
            }
            
            isLoading = false
        } catch {
            purchaseError = error
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        isLoading = true
        
        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
            isLoading = false
        } catch {
            purchaseError = error
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    await self.updateCustomerProductStatus()
                    await self.handleTransaction(transaction)
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func handleTransaction(_ transaction: Transaction) async {
        guard let identifier = ProductIdentifier(rawValue: transaction.productID) else { return }
        
        switch identifier.productType {
        case .creditPackage:
            await awardCredits(for: identifier, transaction: transaction)
        case .subscription:
            await activateSubscription(for: identifier, transaction: transaction)
        case .insurance:
            await activateInsurance(for: identifier, transaction: transaction)
        }
    }
    
    // MARK: - Customer Product Status
    
    func updateCustomerProductStatus() async {
        var purchased: Set<ProductIdentifier> = []
        var subscriptions: [Product.SubscriptionInfo.Status] = []
        
        // Check all transactions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if let identifier = ProductIdentifier(rawValue: transaction.productID) {
                    switch transaction.productType {
                    case .consumable:
                        // Credit packages are consumable, track separately if needed
                        break
                        
                    case .autoRenewable:
                        purchased.insert(identifier)
                        
                        // Get subscription status
                        if let product = products.first(where: { $0.id == transaction.productID }),
                           let status = try await product.subscription?.status.first {
                            subscriptions.append(status)
                        }
                        
                    default:
                        break
                    }
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        self.purchasedProducts = purchased
        self.activeSubscriptions = subscriptions
    }
    
    // MARK: - Backend Sync
    
    private func syncPurchaseWithBackend(_ transaction: Transaction, product: Product) async {
        guard let identifier = ProductIdentifier(rawValue: product.id) else { return }
        
        let url = URL(string: "https://mcjqvdzdhtcvbrejvrtp.supabase.co/functions/v1/apple-pay-webhook")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get auth token
        if let token = try? await SupabaseManager.shared.client.auth.session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "transaction_id": transaction.id,
            "product_id": product.id,
            "product_type": identifier.productType == .creditPackage ? "credit_package" : 
                           identifier.productType == .subscription ? "subscription" : "insurance",
            "price": product.price.description,
            "currency": product.priceFormatStyle.currencyCode ?? "USD",
            "purchase_date": transaction.purchaseDate.timeIntervalSince1970,
            "app_account_token": transaction.appAccountToken?.uuidString ?? "",
            "metadata": ProductDetails.details(for: identifier)?.metadata ?? [:]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                print("Backend sync failed with status: \(httpResponse.statusCode)")
            }
        } catch {
            print("Failed to sync with backend: \(error)")
        }
    }
    
    // MARK: - Credit & Subscription Management
    
    private func awardCredits(for identifier: ProductIdentifier, transaction: Transaction) async {
        guard let details = ProductDetails.details(for: identifier) else { return }
        
        // Calculate seasonal bonus
        let seasonalBonus = getSeasonalBonus()
        let bonusCredits = Int(Double(details.credits) * seasonalBonus)
        let totalCredits = details.credits + bonusCredits
        
        // Award credits via backend
        await PricingService.shared.addCredits(totalCredits, source: "apple_pay", transactionId: String(transaction.id))
        
        // Show success notification
        await showPurchaseSuccess(credits: totalCredits, bonus: bonusCredits)
    }
    
    private func activateSubscription(for identifier: ProductIdentifier, transaction: Transaction) async {
        guard let details = ProductDetails.details(for: identifier) else { return }
        
        // Activate via backend
        await PricingService.shared.activateSubscription(
            planId: details.metadata["stripe_product_id"] ?? "",
            transactionId: String(transaction.id)
        )
        
        // Award initial credits
        await PricingService.shared.addCredits(details.credits, source: "subscription", transactionId: String(transaction.id))
    }
    
    private func activateInsurance(for identifier: ProductIdentifier, transaction: Transaction) async {
        guard let details = ProductDetails.details(for: identifier) else { return }
        
        // Activate insurance via backend
        await PricingService.shared.activateInsurance(
            planId: details.metadata["stripe_product_id"] ?? "",
            transactionId: String(transaction.id)
        )
    }
    
    // MARK: - Helper Functions
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    private func getSeasonalBonus() -> Double {
        let month = Calendar.current.component(.month, from: Date())
        // Winter bonus (Nov-Feb): 20% extra credits
        if month >= 11 || month <= 2 {
            return 0.2
        }
        return 0.0
    }
    
    private func showPurchaseSuccess(credits: Int, bonus: Int) async {
        // Trigger haptic feedback
        await MainActor.run {
            HapticFeedbackService.shared.playPaymentSuccess()
        }
        
        // Show notification
        let content = UNMutableNotificationContent()
        content.title = "Purchase Successful! 🎉"
        content.body = bonus > 0 ? 
            "You received \(credits) credits (\(credits - bonus) + \(bonus) bonus)!" :
            "You received \(credits) credits!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Subscription Management
    
    func cancelSubscription(_ identifier: ProductIdentifier) async throws {
        // This opens subscription management in Settings
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            try await AppStore.showManageSubscriptions(in: windowScene)
        }
    }
    
    func getSubscriptionStatus(for identifier: ProductIdentifier) async -> Product.SubscriptionInfo.Status? {
        guard let product = products.first(where: { $0.id == identifier.rawValue }) else {
            return nil
        }
        
        guard let statuses = try? await product.subscription?.status else {
            return nil
        }
        
        return statuses.first
    }
}

// MARK: - Purchase Errors

enum PurchaseError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case verificationFailed
    case pending
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        case .verificationFailed:
            return "Purchase verification failed"
        case .pending:
            return "Purchase is pending approval"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}