import Foundation
import StoreKit
import Dependencies
import Sharing

// MARK: - Purchase Manager
@Observable
final class PurchaseManager {
    
    // MARK: - Properties
    @ObservationIgnored
    @Shared(.appStorage("isPremiumUserPurchased")) var isPremiumUserPurchased: Bool = false
    
    private let productID = "premium_user"
    var premiumProduct: Product?
    
    // MARK: - Public Interface
    
    /// Loads the premium product from the App Store
    @MainActor
    func loadPremiumProduct() async {
        guard premiumProduct == nil else { return }
        
        do {
            let products = try await Product.products(for: [productID])
            premiumProduct = products.first
        } catch {
            print("❌ Failed to load product: \(error.localizedDescription)")
        }
    }
    
    /// Checks if the user has purchased premium access
    @MainActor
    func checkPurchaseStatus() async {
        await updatePurchaseStatus()
    }
    
    /// Purchases the premium product
    @MainActor
    func purchasePremium() async -> PurchaseResult {
        guard let premiumProduct else {
            return .failure(.productNotLoaded)
        }
        
        do {
            let result = try await premiumProduct.purchase()
            return await handlePurchaseResult(result)
        } catch {
            print("❌ Purchase failed: \(error.localizedDescription)")
            return .failure(.purchaseFailed(error))
        }
    }
    
    /// Restores previous purchases
    @MainActor
    func restorePurchases() async {
        await checkPurchaseStatus()
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func updatePurchaseStatus() async {
        var hasValidPurchase = false
        
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else {
                continue
            }
            
            if transaction.productID == productID && transaction.revocationDate == nil {
                hasValidPurchase = true
                break
            }
        }
        
        $isPremiumUserPurchased.withLock { $0 = hasValidPurchase }
    }
    
    @MainActor
    private func handlePurchaseResult(_ result: Product.PurchaseResult) async -> PurchaseResult {
        switch result {
        case let .success(.verified(transaction)):
            // ✅ Successful purchase
            await transaction.finish()
            await updatePurchaseStatus()
            return .success
            
        case let .success(.unverified(_, error)):
            // ⚠️ Purchase successful but verification failed
            print("⚠️ Purchase verification failed: \(error.localizedDescription)")
            return .failure(.verificationFailed(error))
            
        case .pending:
            // ⏳ Waiting for approval (SCA, Ask to Buy, etc.)
            print("⏳ Purchase pending - waiting for approval")
            return .failure(.pending)
            
        case .userCancelled:
            // ❌ User cancelled the purchase
            print("❌ Purchase cancelled by user")
            return .failure(.userCancelled)
            
        @unknown default:
            // ❓ Unknown result
            print("❓ Unknown purchase result")
            return .failure(.unknown)
        }
    }
}

// MARK: - Purchase Result
enum PurchaseResult {
    case success
    case failure(PurchaseError)
}

// MARK: - Purchase Error
enum PurchaseError: LocalizedError {
    case productNotLoaded
    case purchaseFailed(Error)
    case verificationFailed(Error)
    case pending
    case userCancelled
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotLoaded:
            return "Product not loaded"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .verificationFailed(let error):
            return "Verification failed: \(error.localizedDescription)"
        case .pending:
            return "Purchase is pending approval"
        case .userCancelled:
            return "Purchase was cancelled"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

// MARK: - Dependency Injection
extension DependencyValues {
    var purchaseManager: PurchaseManager {
        get { self[PurchaseManagerKey.self] }
        set { self[PurchaseManagerKey.self] = newValue }
    }
}

private enum PurchaseManagerKey: DependencyKey {
    static let liveValue = PurchaseManager()
}
