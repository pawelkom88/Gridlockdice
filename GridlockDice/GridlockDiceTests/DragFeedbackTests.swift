import XCTest
@testable import GridlockDice

@MainActor
final class DragFeedbackTests: XCTestCase {

    private var vm: GameViewModel!

    override func setUp() {
        let level = LevelDef(
            id: 1, name: "Test", subtitle: "",
            rows: 4, cols: 4,
            dice: [DiceMarker(id: "d1", row: 0, col: 0, label: "A1")],
            pieces: [
                PieceDef(id: "p1", color: .red, rows: [[1]]),
                PieceDef(id: "p2", color: .blue, rows: [[1,1]]),
            ]
        )
        vm = GameViewModel(level: level)
    }

    // MARK: - Hover cells

    func testHoverCellsEmptyWithoutDrag() {
        vm.dragState = nil
        vm.hoverRow = 0
        vm.hoverCol = 0
        XCTAssertTrue(vm.hoverCells.isEmpty)
    }

    func testHoverCellsEmptyWithoutHoverPosition() {
        guard let piece = vm.trayPieces.first else { XCTFail("No tray piece"); return }
        vm.dragState = DragState(piece: piece, location: .zero)
        vm.hoverRow = nil
        vm.hoverCol = nil
        XCTAssertTrue(vm.hoverCells.isEmpty)
    }

    func testHoverCellsForSingleCellPiece() {
        guard let piece = vm.trayPieces.first(where: { $0.color == .red }) else { XCTFail("No red piece"); return }
        vm.dragState = DragState(piece: piece, location: .zero)
        vm.hoverRow = 1
        vm.hoverCol = 2
        XCTAssertEqual(vm.hoverCells, ["1,2"])
    }

    func testHoverCellsForMultiCellPiece() {
        guard let piece = vm.trayPieces.first(where: { $0.color == .blue }) else { XCTFail("No blue piece"); return }
        vm.dragState = DragState(piece: piece, location: .zero)
        vm.hoverRow = 1
        vm.hoverCol = 1
        XCTAssertEqual(vm.hoverCells, ["1,1", "1,2"])
    }

    // MARK: - Hover validity

    func testHoverIsValidForEmptyCells() {
        guard let piece = vm.trayPieces.first(where: { $0.color == .red }) else { XCTFail("No piece"); return }
        vm.dragState = DragState(piece: piece, location: .zero)
        vm.hoverRow = 1
        vm.hoverCol = 1
        XCTAssertTrue(vm.hoverIsValid)
    }

    func testHoverIsInvalidOverDice() {
        guard let piece = vm.trayPieces.first(where: { $0.color == .red }) else { XCTFail("No piece"); return }
        vm.dragState = DragState(piece: piece, location: .zero)
        vm.hoverRow = 0
        vm.hoverCol = 0
        XCTAssertFalse(vm.hoverIsValid)
    }

    func testHoverIsInvalidWithoutDrag() {
        vm.hoverRow = 1
        vm.hoverCol = 1
        XCTAssertFalse(vm.hoverIsValid)
    }

    // MARK: - Drop feedback

    func testValidDropSetsSnapFeedback() {
        guard let pieceID = vm.trayPieces.first(where: { $0.color == .red })?.id else { XCTFail("No piece"); return }
        vm.tryPlace(pieceID: pieceID, at: 1, col: 1)
        XCTAssertEqual(vm.snappingPieceID, pieceID)
    }

    func testInvalidDropSetsShakeFeedback() {
        guard let pieceID = vm.trayPieces.first(where: { $0.color == .red })?.id else { XCTFail("No piece"); return }
        vm.tryPlace(pieceID: pieceID, at: 0, col: 0)
        XCTAssertEqual(vm.shakingPieceID, pieceID)
    }

    func testDragStateCleanedUpOnInvalidDrop() {
        guard let piece = vm.trayPieces.first(where: { $0.color == .red }) else { XCTFail("No piece"); return }
        vm.dragState = DragState(piece: piece, location: .zero)
        vm.hoverRow = 0
        vm.hoverCol = 0
        vm.tryPlace(pieceID: piece.id, at: vm.hoverRow!, col: vm.hoverCol!)
        XCTAssertTrue(vm.trayPieces.contains(where: { $0.id == piece.id }), "Piece should still be in tray after rejected drop")
    }
}
