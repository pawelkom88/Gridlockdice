import XCTest
@testable import GridlockDice

final class BoardStateTests: XCTestCase {

    // MARK: - Dice

    func testBoardStartsWithFixedDiceCells() {
        let dice = [
            DiceMarker(id: "A1", row: 0, col: 0, label: "A1"),
            DiceMarker(id: "C4", row: 2, col: 3, label: "C4"),
        ]
        let board = BoardState(rows: 4, cols: 4, dice: dice)

        guard case .dice(let label) = board[0, 0] else {
            XCTFail("Expected dice at (0,0)")
            return
        }
        XCTAssertEqual(label, "A1")

        guard case .dice(let label) = board[2, 3] else {
            XCTFail("Expected dice at (2,3)")
            return
        }
        XCTAssertEqual(label, "C4")

        guard case .empty = board[1, 1] else {
            XCTFail("Expected empty at (1,1)")
            return
        }
    }

    // MARK: - Valid placement

    func testCanPlacePieceInEmptyArea() {
        let shape: Shape = [[true, true], [true, false]]
        let board = BoardState(rows: 4, cols: 4, dice: [])

        XCTAssertTrue(board.canPlace(shape: shape, at: 0, col: 0))
        XCTAssertTrue(board.canPlace(shape: shape, at: 2, col: 2))
    }

    func testPlacementFillsCells() {
        let shape: Shape = [[true, true], [true, false]]
        var board = BoardState(rows: 4, cols: 4, dice: [])
        board.place(shape: shape, at: 0, col: 0, pieceID: "p1", color: .red)

        guard case .filled(let pid, _) = board[0, 0] else {
            XCTFail("Expected filled at (0,0)")
            return
        }
        XCTAssertEqual(pid, "p1")

        guard case .filled = board[0, 1] else {
            XCTFail("Expected filled at (0,1)")
            return
        }
        guard case .filled = board[1, 0] else {
            XCTFail("Expected filled at (1,0)")
            return
        }
        guard case .empty = board[1, 1] else {
            XCTFail("Expected empty at (1,1) since shape[1][1] is false")
            return
        }
    }

    // MARK: - Invalid placement: outside board

    func testCannotPlacePieceOutsideBoard() {
        let shape: Shape = [[true, true]]
        let board = BoardState(rows: 4, cols: 4, dice: [])

        XCTAssertFalse(board.canPlace(shape: shape, at: -1, col: 0))
        XCTAssertFalse(board.canPlace(shape: shape, at: 0, col: -1))
        XCTAssertFalse(board.canPlace(shape: shape, at: 4, col: 0))
        XCTAssertFalse(board.canPlace(shape: shape, at: 0, col: 3))
    }

    // MARK: - Invalid placement: over dice

    func testCannotPlacePieceOverDice() {
        let dice = [DiceMarker(id: "A1", row: 0, col: 0, label: "A1")]
        let board = BoardState(rows: 4, cols: 4, dice: dice)
        let shape: Shape = [[true]]
        XCTAssertFalse(board.canPlace(shape: shape, at: 0, col: 0))
    }

    func testCannotPlacePieceOverFilledCells() {
        let first: Shape = [[true]]
        var board = BoardState(rows: 4, cols: 4, dice: [])
        board.place(shape: first, at: 0, col: 0, pieceID: "p1", color: .red)

        let second: Shape = [[true]]
        XCTAssertFalse(board.canPlace(shape: second, at: 0, col: 0))
    }

    // MARK: - Removal

    func testRemovingPiecePreservesDice() {
        let dice = [
            DiceMarker(id: "A1", row: 0, col: 0, label: "A1"),
            DiceMarker(id: "B2", row: 1, col: 1, label: "B2"),
        ]
        var board = BoardState(rows: 3, cols: 3, dice: dice)
        board.place(shape: [[true]], at: 0, col: 1, pieceID: "p1", color: .red)
        board.place(shape: [[true]], at: 2, col: 2, pieceID: "p2", color: .blue)

        board.remove(pieceID: "p1")

        guard case .dice = board[0, 0] else {
            XCTFail("Dice at (0,0) should still be dice")
            return
        }
        guard case .dice = board[1, 1] else {
            XCTFail("Dice at (1,1) should still be dice")
            return
        }
        guard case .empty = board[0, 1] else {
            XCTFail("Removed piece cell should be empty")
            return
        }
        guard case .filled = board[2, 2] else {
            XCTFail("Unrelated piece should remain")
            return
        }
    }

    // MARK: - Solved

    func testBoardIsNotSolvedWhenEmptyCellsRemain() {
        let board = BoardState(rows: 2, cols: 2, dice: [])
        XCTAssertFalse(board.isSolved)
    }

    func testBoardIsSolvedWhenAllCellsFilled() {
        var board = BoardState(rows: 2, cols: 2, dice: [])
        board.place(shape: [[true, true]], at: 0, col: 0, pieceID: "p1", color: .red)
        board.place(shape: [[true, true]], at: 1, col: 0, pieceID: "p2", color: .blue)
        XCTAssertTrue(board.isSolved)
    }

    func testBoardIsSolvedWhenAllNonDiceCellsFilled() {
        let dice = [DiceMarker(id: "A1", row: 0, col: 0, label: "A1")]
        var board = BoardState(rows: 2, cols: 2, dice: dice)
        board.place(shape: [[true]], at: 0, col: 1, pieceID: "p1", color: .red)
        board.place(shape: [[true, true]], at: 1, col: 0, pieceID: "p2", color: .blue)
        XCTAssertTrue(board.isSolved)
    }

    // MARK: - Playable count

    func testPlayableCellCountExcludesDice() {
        let dice = [
            DiceMarker(id: "A1", row: 0, col: 0, label: "A1"),
            DiceMarker(id: "B2", row: 1, col: 1, label: "B2"),
        ]
        let board = BoardState(rows: 3, cols: 3, dice: dice)
        XCTAssertEqual(board.playableCellCount, 7)
    }
}
