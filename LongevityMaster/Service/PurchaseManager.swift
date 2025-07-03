import Foundation
import StoreKit
import Dependencies

@Observable
@MainActor
class PurchaseManager {
    var isRemoveAdsPurchased: Bool = false
    var removeAdsProduct: Product?
    private let productID = "premium_user"

    nonisolated
    init() {}

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [productID])
            removeAdsProduct = products.first
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func checkPurchased() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == productID {
                isRemoveAdsPurchased = true
                return
            }
        }
        isRemoveAdsPurchased = false
    }

    func purchaseRemoveAds() async {
        guard let product = removeAdsProduct else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(_) = verification {
                    isRemoveAdsPurchased = true
                }
            default: break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == productID {
                isRemoveAdsPurchased = true
            }
        }
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
