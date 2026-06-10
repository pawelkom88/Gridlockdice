import XCTest
@testable import GridlockDice

@MainActor
final class CompletionFlowTests: XCTestCase {

    private var store: InMemoryStore!
    private var purchaseService: TestPurchaseService!
    private var appVM: AppViewModel!

    override func setUp() {
        store = InMemoryStore()
        purchaseService = TestPurchaseService()
        appVM = AppViewModel(store: store, purchaseService: purchaseService)
    }

    // MARK: - Solve routes to completion

    func testSolvingLevelRoutesToCompletion() {
        appVM.startLevel(1)
        guard let vm = appVM.gameVM else { XCTFail("No game VM"); return }

        let elapsed: TimeInterval = 12.5
        vm.onSolved?(elapsed)

        XCTAssertTrue(appVM.completedIDs.contains(1))
        XCTAssertTrue(store.completedLevels.contains(1))
    }

    func testCompletionCarriesLevelIDAndElapsed() {
        appVM.startLevel(1)
        guard let vm = appVM.gameVM else { XCTFail("No game VM"); return }

        let elapsed: TimeInterval = 45.0
        vm.onSolved?(elapsed)

        let exp = expectation(description: "completion screen shown")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard case .completion(let id, let e) = appVM.screen else {
                XCTFail("Expected .completion, got \(appVM.screen)")
                exp.fulfill()
                return
            }
            XCTAssertEqual(id, 1)
            XCTAssertEqual(e, 45.0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }

    // MARK: - Persistence

    func testCompletionPersistsSolvedLevel() {
        appVM.startLevel(1)
        guard let vm = appVM.gameVM else { XCTFail("No game VM"); return }

        vm.onSolved?(5.0)
        XCTAssertTrue(store.completedLevels.contains(1))

        let newVM = AppViewModel(store: store, purchaseService: TestPurchaseService())
        XCTAssertTrue(newVM.completedIDs.contains(1))
    }

    // MARK: - Continue / Next Level

    func testContinueStartsNextAvailableLevel() {
        appVM.startLevel(5)
        appVM.goToNextLevel(after: 5)

        guard case .game(let id) = appVM.screen else {
            XCTFail("Expected .game for level 6, got \(appVM.screen)")
            return
        }
        XCTAssertEqual(id, 6)
    }

    func testContinueAfterFreeBoundaryRoutesToPaywallWhenLocked() {
        purchaseService.productAvailable = false
        appVM.startLevel(15)
        appVM.goToNextLevel(after: 15)

        guard case .paywall = appVM.screen else {
            XCTFail("Expected .paywall for level 16 when locked, got \(appVM.screen)")
            return
        }
    }

    func testContinueAfterLastLevelReturnsToLevelSelect() {
        appVM.goToNextLevel(after: 50)
        guard case .levelSelect = appVM.screen else {
            XCTFail("Expected .levelSelect after level 50, got \(appVM.screen)")
            return
        }
    }

    func testContinueWithinFreeBandWorksWhenUnlocked() {
        appVM.isUnlocked = true
        appVM.startLevel(16)
        appVM.goToNextLevel(after: 16)
        guard case .game(let id) = appVM.screen else {
            XCTFail("Expected .game for level 17 after unlock, got \(appVM.screen)")
            return
        }
        XCTAssertEqual(id, 17)
    }
}
