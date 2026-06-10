import Foundation
import StoreKit

@MainActor
protocol PurchaseService: AnyObject {
    var priceText: String { get }
    var productAvailable: Bool { get }
    func loadProduct() async
    func purchase() async throws -> Bool
    func restore() async throws -> Bool
}

@MainActor
final class StoreKitPurchaseService: PurchaseService {
    static let productID = "full_game_unlock"

    private var product: Product?

    var priceText: String {
        product?.displayPrice ?? "Unlock"
    }

    var productAvailable: Bool {
        product != nil
    }

    func loadProduct() async {
        product = try? await Product.products(for: [Self.productID]).first
    }

    func purchase() async throws -> Bool {
        guard let product else { return false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                return true
            }
            return false
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async throws -> Bool {
        try? await AppStore.sync()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID {
                return true
            }
        }
        return false
    }
}
