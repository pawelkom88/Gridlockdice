import XCTest
@testable import GridlockDice

final class ShapeRotationTests: XCTestCase {

    func testShapeRotatesClockwise() {
        let lShape: Shape = [
            [true, false],
            [true, false],
            [true, true],
        ]
        let rotated = lShape.rotatedCW()

        XCTAssertEqual(rotated.count, 2)
        XCTAssertEqual(rotated[0].count, 3)
        XCTAssertEqual(rotated, [
            [true, true, true],
            [true, false, false],
        ])
    }

    func testFourRotationsReturnOriginalShape() {
        let shape: Shape = [
            [true, true, false],
            [false, true, true],
        ]
        var current = shape
        for _ in 0..<4 {
            current = current.rotatedCW()
        }
        XCTAssertEqual(current, shape)
    }

    func testTrayPieceRotationDoesNotMutatePieceDefinition() {
        let def = PieceDef(id: "p1", color: .red, rows: [[1, 0], [1, 1]])
        var tray = TrayPiece(from: def)

        let originalDefShape = def.shape
        tray.rotateCW()

        XCTAssertEqual(def.shape, originalDefShape,
                       "PieceDef shape should not be mutated by tray rotation")
        XCTAssertNotEqual(tray.shape, def.shape,
                          "TrayPiece shape should differ after rotation")
    }

    func testRotatePiecelChangesTrayShapeOnly() {
        let def = PieceDef(id: "p2", color: .blue, rows: [[1, 1], [1, 0]])
        var tray = TrayPiece(from: def)

        XCTAssertEqual(tray.shape, def.shape,
                       "TrayPiece starts with same shape as definition")

        tray.rotateCW()

        XCTAssertNotEqual(tray.shape, def.shape,
                          "TrayPiece shape should change after rotation")
        XCTAssertEqual(tray.id, def.id,
                       "TrayPiece id should not change")
        XCTAssertEqual(tray.color, def.color,
                       "TrayPiece color should not change")
    }

    func testRotateSquareShapePreservesDimensions() {
        let square: Shape = [
            [true, true],
            [true, true],
        ]
        let rotated = square.rotatedCW()
        XCTAssertEqual(rotated.count, 2)
        XCTAssertEqual(rotated[0].count, 2)
        XCTAssertEqual(rotated, square)
    }
}
