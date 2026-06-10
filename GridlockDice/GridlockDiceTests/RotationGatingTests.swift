import XCTest
@testable import GridlockDice

@MainActor
final class RotationGatingTests: XCTestCase {

    func testBeginnerLevelDoesNotAllowRotation() {
        let level = LevelCatalogue.all[0] // Level 1
        XCTAssertFalse(level.allowsRotation)
    }

    func testRotatePieceDoesNothingWhenRotationLocked() {
        let level = LevelDef(
            id: 1, name: "Test", subtitle: "",
            rows: 4, cols: 4, dice: [],
            pieces: [PieceDef(id: "p1", color: .red, rows: [[1, 0], [1, 1]])]
        )
        let vm = GameViewModel(level: level)
        let originalShape = vm.trayPieces[0].shape

        vm.rotatePiece(id: "p1")
        XCTAssertEqual(vm.trayPieces[0].shape, originalShape,
                       "Shape should not change when rotation is locked")
    }

    func testRotatePieceChangesShapeWhenRotationAllowed() {
        let level = LevelDef(
            id: 21, name: "Test", subtitle: "",
            rows: 4, cols: 4, dice: [],
            pieces: [PieceDef(id: "p1", color: .red, rows: [[1, 0], [1, 1]])]
        )
        let vm = GameViewModel(level: level)
        let originalShape = vm.trayPieces[0].shape

        vm.rotatePiece(id: "p1")
        XCTAssertNotEqual(vm.trayPieces[0].shape, originalShape,
                          "Shape should change when rotation is allowed")
    }

    func testRotatedShapeCanBePlacedWhereOriginalCannot() {
        let dice = [
            DiceMarker(id: "D1", row: 0, col: 0, label: "A1"),
        ]
        let level = LevelDef(
            id: 21, name: "Test", subtitle: "",
            rows: 3, cols: 3, dice: dice,
            pieces: [PieceDef(id: "p1", color: .red, rows: [[1, 0], [1, 1]])]
        )
        let vm = GameViewModel(level: level)
        let originalShape = vm.trayPieces[0].shape

        // Original L-shape [[1,0],[1,1]] at (0,1): cells (0,1)(1,1)(1,2) - should work
        // But it can't be placed at (0,0) because of the dice
        XCTAssertFalse(vm.board.canPlace(shape: originalShape, at: 0, col: 0),
                       "Original shape overlaps dice at (0,0)")

        vm.rotatePiece(id: "p1")
        let rotated = vm.trayPieces[0].shape
        // After rotation CW: [[1,1],[0,1]] - can be placed at (0,1)
        // Cells: (0,1)(0,2)(1,2) - none overlap dice at (0,0)
        XCTAssertTrue(vm.board.canPlace(shape: rotated, at: 0, col: 1),
                      "Rotated shape should fit where original cannot")
    }
}
