import Foundation
import StoreKit
import Dependencies

@Observable
class PurchaseManager: NSObject {
    var isRemoveAdsPurchased: Bool = false
    var removeAdsProduct: Product?
    private let productID = "premium_user"
    private var productsLoaded = false
    private var updates: Task<Void, Never>?

    override init() {
        super.init()
        // Check purchase status on initialization
        Task { @MainActor in
            await checkPurchased()
        }
        // Start observing transaction updates
        updates = observeTransactionUpdates()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        self.updates?.cancel()
        SKPaymentQueue.default().remove(self)
    }

    func loadProducts() async {
        guard !productsLoaded else { return }
        do {
            let products = try await Product.products(for: [productID])
            removeAdsProduct = products.first
            productsLoaded = true
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    @MainActor
    func checkPurchased() async {
        await updatePurchasedProducts()
    }
    
    @MainActor
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else {
                continue
            }

            if transaction.productID == productID && transaction.revocationDate == nil {
                isRemoveAdsPurchased = true
                return
            }
        }
        isRemoveAdsPurchased = false
    }

    @MainActor
    func purchaseRemoveAds() async {
        guard let product = removeAdsProduct else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case let .success(.verified(transaction)):
                // Successful purchase
                await transaction.finish()
                await updatePurchasedProducts()
            case let .success(.unverified(_, error)):
                // Successful purchase but transaction/receipt can't be verified
                // Could be a jailbroken phone
                print("Purchase verification failed: \(error)")
                break
            case .pending:
                // Transaction waiting on SCA (Strong Customer Authentication) or
                // approval from Ask to Buy
                print("Purchase pending - waiting for approval")
                break
            case .userCancelled:
                print("Purchase cancelled by user")
                break
            @unknown default:
                print("Unknown purchase result")
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }

    @MainActor
    func restorePurchases() async {
        await checkPurchased()
    }
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                await self.updatePurchasedProducts()
            }
        }
    }
} 

// MARK: - SKPaymentTransactionObserver
extension PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        // Handle transaction updates if needed
        // The main logic is handled by Transaction.updates in observeTransactionUpdates()
    }

    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
}

// Dependency injection
extension DependencyValues {
    var purchaseManager: PurchaseManager {
        get { self[PurchaseManagerKey.self] }
        set { self[PurchaseManagerKey.self] = newValue }
    }
}

private enum PurchaseManagerKey: DependencyKey {
    static let liveValue = PurchaseManager()
}
