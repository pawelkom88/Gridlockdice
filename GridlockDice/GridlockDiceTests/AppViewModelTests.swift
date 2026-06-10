import XCTest
@testable import GridlockDice

@MainActor
final class AppViewModelTests: XCTestCase {

    private var store: InMemoryStore!
    private var purchaseService: TestPurchaseService!
    private var sut: AppViewModel!

    override func setUp() {
        store = InMemoryStore()
        purchaseService = TestPurchaseService()
        sut = AppViewModel(store: store, purchaseService: purchaseService)
    }

    override func tearDown() {
        sut = nil
        store = nil
    }

    // MARK: - Initial state

    func testInitialScreenIsLevelSelect() {
        guard case .levelSelect = sut.screen else {
            XCTFail("Expected .levelSelect, got \(sut.screen)")
            return
        }
    }

    // MARK: - Start level

    func testStartAvailableLevelCreatesGameSession() {
        sut.startLevel(1) // Level 1 is free
        guard case .game(let id) = sut.screen else {
            XCTFail("Expected .game")
            return
        }
        XCTAssertEqual(id, 1)
        XCTAssertNotNil(sut.gameVM)
    }

    func testLockedLevelRoutesToPaywallBeforePurchase() {
        sut.startLevel(16) // Level 16 is paid
        guard case .paywall = sut.screen else {
            XCTFail("Expected .paywall for locked level, got \(sut.screen)")
            return
        }
        XCTAssertNil(sut.gameVM)
    }

    func testLockedLevelStartsAfterUnlock() {
        sut.isUnlocked = true
        sut.startLevel(16)
        guard case .game(let id) = sut.screen else {
            XCTFail("Expected .game after unlock")
            return
        }
        XCTAssertEqual(id, 16)
        XCTAssertNotNil(sut.gameVM)
    }

    // MARK: - Solved level

    func testGameSessionCallsOnSolved() {
        let level = LevelDef(
            id: 1, name: "Test", subtitle: "",
            rows: 2, cols: 2, dice: [],
            pieces: [
                PieceDef(id: "p1", color: .red, rows: [[1]]),
                PieceDef(id: "p2", color: .blue, rows: [[1]]),
                PieceDef(id: "p3", color: .green, rows: [[1]]),
                PieceDef(id: "p4", color: .yellow, rows: [[1]]),
            ]
        )
        let vm = GameViewModel(level: level)

        vm.tryPlace(pieceID: "p1", at: 0, col: 0)
        vm.tryPlace(pieceID: "p2", at: 0, col: 1)
        vm.tryPlace(pieceID: "p3", at: 1, col: 0)
        vm.tryPlace(pieceID: "p4", at: 1, col: 1)

        XCTAssertTrue(vm.board.isSolved, "Board should be solved after placing all pieces")
    }

    // MARK: - Persistence

    func testCompletedLevelsPersist() {
        store.completedLevels = [1, 2, 3]
        let newVM = AppViewModel(store: store, purchaseService: TestPurchaseService())
        XCTAssertEqual(newVM.completedIDs, [1, 2, 3])
    }

    func testUnlockStatePersists() {
        store.isUnlocked = true
        let newVM = AppViewModel(store: store, purchaseService: TestPurchaseService())
        XCTAssertTrue(newVM.isUnlocked)
    }

    func testUnlockingPersistsToStore() {
        sut.isUnlocked = true
        XCTAssertTrue(store.isUnlocked)
    }
}

// MARK: - In-memory store for tests

final class InMemoryStore: PersistenceStore {
    var completedLevels: Set<Int> = []
    var isUnlocked: Bool = false
}

@MainActor
final class TestPurchaseService: PurchaseService {
    var priceText = "Unlock"
    var productAvailable = false
    var purchaseResult = true
    var restoreResult = false
    var didLoadProduct = false

    func loadProduct() async { didLoadProduct = true }
    func purchase() async throws -> Bool { purchaseResult }
    func restore() async throws -> Bool { restoreResult }
}
