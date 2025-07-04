import Foundation
import StoreKit
import Dependencies
import Sharing

@Observable
class PurchaseManager {
    @ObservationIgnored
    @Shared(.appStorage("isPremiumUserPurchased")) var isPremiumUserPurchased: Bool = false
            
    var premiumUserProduct: Product?
    private let productID = "premium_user"
    private var productsLoaded = false

    func loadProducts() async {
        guard !productsLoaded else { return }
        do {
            let products = try await Product.products(for: [productID])
            premiumUserProduct = products.first
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
                $isPremiumUserPurchased.withLock { $0 = true }
                return
            }
        }
        $isPremiumUserPurchased.withLock { $0 = false }
    }

    @MainActor
    func purchasePremiumUser() async -> Bool {
        guard let product = premiumUserProduct else { return false }
        do {
            let result = try await product.purchase()
            switch result {
            case let .success(.verified(transaction)):
                // Successful purchase
                await transaction.finish()
                await updatePurchasedProducts()
                return true
            case let .success(.unverified(_, error)):
                // Successful purchase but transaction/receipt can't be verified
                // Could be a jailbroken phone
                print("Purchase verification failed: \(error)")
                return false
            case .pending:
                // Transaction waiting on SCA (Strong Customer Authentication) or
                // approval from Ask to Buy
                print("Purchase pending - waiting for approval")
                return false
            case .userCancelled:
                print("Purchase cancelled by user")
                return false
            @unknown default:
                print("Unknown purchase result")
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }

    @MainActor
    func restorePurchases() async {
        await checkPurchased()
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
