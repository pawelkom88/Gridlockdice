import XCTest
@testable import GridlockDice

@MainActor
final class GameSessionTests: XCTestCase {

    private var level: LevelDef!

    override func setUp() {
        level = LevelDef(
            id: 1, name: "Test", subtitle: "",
            rows: 3, cols: 3,
            dice: [DiceMarker(id: "D1", row: 1, col: 1, label: "B2")],
            pieces: [
                PieceDef(id: "p1", color: .red, rows: [[1]]),
                PieceDef(id: "p2", color: .blue, rows: [[1]]),
                PieceDef(id: "p3", color: .green, rows: [[1, 1]]),
                PieceDef(id: "p4", color: .yellow, rows: [[1, 1]]),
                PieceDef(id: "p5", color: .teal, rows: [[1, 1]]),
                PieceDef(id: "p6", color: .purple, rows: [[1, 1, 1]]),
            ]
        )
    }

    func testGameSessionStartsWithLevelBoardAndTrayPieces() {
        let vm = GameViewModel(level: level)

        guard case .dice = vm.board[1, 1] else {
            XCTFail("Board should have dice at (1,1)")
            return
        }
        XCTAssertEqual(vm.trayPieces.count, 6)
    }

    func testValidPlacementMovesPieceFromTrayToBoard() {
        let vm = GameViewModel(level: level)

        vm.tryPlace(pieceID: "p1", at: 0, col: 0)
        XCTAssertEqual(vm.trayPieces.count, 5)
        guard case .filled(let pid, _) = vm.board[0, 0] else {
            XCTFail("Cell (0,0) should be filled")
            return
        }
        XCTAssertEqual(pid, "p1")
        XCTAssertEqual(vm.placedIDs, ["p1"])
    }

    func testInvalidPlacementDoesNotChangeBoardOrTray() {
        let vm = GameViewModel(level: level)
        let initialTrayCount = vm.trayPieces.count
        let initialBoard = vm.board[0, 0]

        vm.tryPlace(pieceID: "p1", at: 1, col: 1)

        XCTAssertEqual(vm.trayPieces.count, initialTrayCount)
        XCTAssertEqual(vm.board[0, 0], initialBoard)
        XCTAssertEqual(vm.placedIDs, [])
    }

    func testRemovingPlacedPieceReturnsItToTray() {
        let vm = GameViewModel(level: level)

        vm.tryPlace(pieceID: "p1", at: 0, col: 0)
        XCTAssertEqual(vm.trayPieces.count, 5)

        vm.removePiece(id: "p1")
        XCTAssertEqual(vm.trayPieces.count, 6)
        guard case .empty = vm.board[0, 0] else {
            XCTFail("Cell (0,0) should be empty after removal")
            return
        }
        XCTAssertEqual(vm.placedIDs, [])
    }

    func testProgressReflectsFilledPlayableCells() {
        let vm = GameViewModel(level: level)
        XCTAssertEqual(vm.filledCount, 0)
        XCTAssertEqual(vm.totalPlayable, 8)

        vm.tryPlace(pieceID: "p1", at: 0, col: 0)
        XCTAssertEqual(vm.filledCount, 1)

        vm.tryPlace(pieceID: "p3", at: 0, col: 1)
        XCTAssertEqual(vm.filledCount, 3)

        vm.removePiece(id: "p1")
        XCTAssertEqual(vm.filledCount, 2)
    }

    func testResetRestoresInitialState() {
        let vm = GameViewModel(level: level)
        vm.tryPlace(pieceID: "p1", at: 0, col: 0)
        vm.tryPlace(pieceID: "p3", at: 2, col: 0)
        XCTAssertEqual(vm.trayPieces.count, 4)

        vm.reset()
        XCTAssertEqual(vm.trayPieces.count, 6)
        XCTAssertEqual(vm.placedIDs, [])
        guard case .empty = vm.board[0, 0] else {
            XCTFail("Board should be reset")
            return
        }
        guard case .dice = vm.board[1, 1] else {
            XCTFail("Dice should remain")
            return
        }
    }
}
