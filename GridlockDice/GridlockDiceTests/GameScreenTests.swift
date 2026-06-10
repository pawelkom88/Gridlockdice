import XCTest
@testable import GridlockDice

@MainActor
final class GameScreenTests: XCTestCase {

    private var store: InMemoryStore!
    private var purchaseService: TestPurchaseService!
    private var appVM: AppViewModel!

    override func setUp() {
        store = InMemoryStore()
        purchaseService = TestPurchaseService()
        appVM = AppViewModel(store: store, purchaseService: purchaseService)
    }

    // MARK: - Header

    func testGameScreenShowsLevelTitle() {
        appVM.startLevel(1)
        guard let vm = appVM.gameVM else { XCTFail("No game VM"); return }
        let level1 = LevelCatalogue.all.first(where: { $0.id == 1 })
        XCTAssertEqual(vm.level.name, level1?.name ?? "")
        XCTAssertFalse(vm.level.name.isEmpty)
    }

    // MARK: - Progress

    func testProgressStartsAtZero() {
        appVM.startLevel(1)
        guard let vm = appVM.gameVM else { XCTFail("No game VM"); return }
        XCTAssertEqual(vm.filledCount, 0)
        XCTAssertGreaterThan(vm.totalPlayable, 0)
        XCTAssertEqual(vm.progress, 0)
    }

    func testProgressUpdatesAfterPlacement() {
        appVM.startLevel(1)
        guard let vm = appVM.gameVM else { XCTFail("No game VM"); return }
        guard let piece = vm.trayPieces.first else { XCTFail("No tray pieces"); return }
        let validRow = (0..<vm.level.rows).first(where: { r in
            (0..<vm.level.cols).contains(where: { c in vm.board.canPlace(shape: piece.shape, at: r, col: c) })
        })
        let validCol = (0..<vm.level.cols).first(where: { c in vm.board.canPlace(shape: piece.shape, at: validRow ?? 0, col: c) })
        guard let r = validRow, let c = validCol else { XCTFail("No valid placement"); return }
        vm.tryPlace(pieceID: piece.id, at: r, col: c)
        XCTAssertGreaterThan(vm.filledCount, 0)
        XCTAssertGreaterThan(vm.progress, 0)
    }

    func testProgressUpdatesAfterRemoval() {
        appVM.startLevel(1)
        guard let vm = appVM.gameVM else { XCTFail("No game VM"); return }
        guard let piece = vm.trayPieces.first else { XCTFail("No tray pieces"); return }
        let validRow = (0..<vm.level.rows).first(where: { r in
            (0..<vm.level.cols).contains(where: { c in vm.board.canPlace(shape: piece.shape, at: r, col: c) })
        })
        let validCol = (0..<vm.level.cols).first(where: { c in vm.board.canPlace(shape: piece.shape, at: validRow ?? 0, col: c) })
        guard let r = validRow, let c = validCol else { XCTFail("No valid placement"); return }
        vm.tryPlace(pieceID: piece.id, at: r, col: c)
        vm.removePiece(id: piece.id)
        XCTAssertEqual(vm.filledCount, 0)
        XCTAssertEqual(vm.progress, 0)
    }

    // MARK: - Reset

    func testResetRestoresInitialLevelState() {
        appVM.startLevel(1)
        guard let vm = appVM.gameVM else { XCTFail("No game VM"); return }
        let initialTrayCount = vm.trayPieces.count

        guard let piece = vm.trayPieces.first else { XCTFail("No tray pieces"); return }
        let validRow = (0..<vm.level.rows).first(where: { r in
            (0..<vm.level.cols).contains(where: { c in vm.board.canPlace(shape: piece.shape, at: r, col: c) })
        })
        let validCol = (0..<vm.level.cols).first(where: { c in vm.board.canPlace(shape: piece.shape, at: validRow ?? 0, col: c) })
        if let r = validRow, let c = validCol {
            vm.tryPlace(pieceID: piece.id, at: r, col: c)
        }

        vm.reset()
        XCTAssertEqual(vm.trayPieces.count, initialTrayCount)
        XCTAssertEqual(vm.progress, 0)
    }

    // MARK: - Back

    func testBackReturnsToLevelSelect() {
        appVM.startLevel(1)
        guard case .game = appVM.screen else { XCTFail("Expected .game"); return }
        appVM.screen = .levelSelect
        guard case .levelSelect = appVM.screen else { XCTFail("Expected .levelSelect"); return }
    }
}
