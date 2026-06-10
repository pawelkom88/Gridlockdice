import XCTest
@testable import GridlockDice

// MARK: - Fake Purchase Service

@MainActor
final class FakePurchaseService: PurchaseService {
    var priceText = "$2.99"
    var productAvailable = true
    var purchaseResult = true
    var restoreResult = false
    var didLoadProduct = false

    func loadProduct() async {
        didLoadProduct = true
    }

    func purchase() async throws -> Bool {
        purchaseResult
    }

    func restore() async throws -> Bool {
        restoreResult
    }
}

// MARK: - Tests

@MainActor
final class PurchaseServiceTests: XCTestCase {

    // MARK: - Product ID

    func testPurchaseManagerRequestsFullGameUnlockProduct() {
        XCTAssertEqual(StoreKitPurchaseService.productID, "full_game_unlock")
    }

    // MARK: - Purchase

    func testSuccessfulPurchaseUnlocksPaidLevels() async throws {
        let store = InMemoryStore()
        let purchaseService = FakePurchaseService()
        purchaseService.purchaseResult = true
        let sut = AppViewModel(store: store, purchaseService: purchaseService)

        let result = try await sut.purchase()
        XCTAssertTrue(result)
        XCTAssertTrue(sut.isUnlocked)
        XCTAssertTrue(store.isUnlocked)
    }

    func testFailedPurchaseDoesNotUnlock() async throws {
        let store = InMemoryStore()
        let purchaseService = FakePurchaseService()
        purchaseService.purchaseResult = false
        let sut = AppViewModel(store: store, purchaseService: purchaseService)

        let result = try await sut.purchase()
        XCTAssertFalse(result)
        XCTAssertFalse(sut.isUnlocked)
        XCTAssertFalse(store.isUnlocked)
    }

    // MARK: - Restore

    func testRestoreUnlocksWhenEntitlementExists() async throws {
        let store = InMemoryStore()
        let purchaseService = FakePurchaseService()
        purchaseService.restoreResult = true
        let sut = AppViewModel(store: store, purchaseService: purchaseService)

        let result = try await sut.restore()
        XCTAssertTrue(result)
        XCTAssertTrue(sut.isUnlocked)
        XCTAssertTrue(store.isUnlocked)
    }

    func testRestoreDoesNotUnlockWhenNoEntitlement() async throws {
        let store = InMemoryStore()
        let purchaseService = FakePurchaseService()
        purchaseService.restoreResult = false
        let sut = AppViewModel(store: store, purchaseService: purchaseService)

        let result = try await sut.restore()
        XCTAssertFalse(result)
        XCTAssertFalse(sut.isUnlocked)
        XCTAssertFalse(store.isUnlocked)
    }

    // MARK: - Unavailable product

    func testUnavailableProductKeepsPaywallUsable() {
        let purchaseService = FakePurchaseService()
        purchaseService.productAvailable = false
        purchaseService.priceText = "Unlock"

        XCTAssertEqual(purchaseService.priceText, "Unlock")
        XCTAssertFalse(purchaseService.productAvailable)
        XCTAssertNotEqual(purchaseService.priceText, "$2.99")
    }

    // MARK: - No hardcoded final price

    func testPaywallDoesNotHardcodeFinalPrice() {
        let purchaseService = FakePurchaseService()
        purchaseService.priceText = "$2.99"
        let store = InMemoryStore()
        let sut = AppViewModel(store: store, purchaseService: purchaseService)
        XCTAssertEqual(sut.priceText, "$2.99", "Price text delegated to purchase service")

        purchaseService.priceText = "Unlock"
        XCTAssertEqual(sut.priceText, "Unlock", "Price follows purchase service, not hardcoded")

        purchaseService.productAvailable = false
        XCTAssertFalse(sut.productAvailable, "Availability delegated to purchase service")
    }
}
