import XCTest
@testable import GridlockDice

final class PuzzleSolverTests: XCTestCase {

    func testSolverReturnsTrueForKnownSolvableLevel() {
        let level = LevelDef(
            id: 0, name: "Test", subtitle: "",
            rows: 2, cols: 2,
            dice: [],
            pieces: [
                PieceDef(id: "p1", color: .red, rows: [[1, 1]]),
                PieceDef(id: "p2", color: .blue, rows: [[1, 1]]),
            ]
        )
        XCTAssertTrue(PuzzleSolver.isSolvable(level: level))
    }

    func testSolverReturnsFalseForKnownImpossibleLevel() {
        let level = LevelDef(
            id: 0, name: "Test", subtitle: "",
            rows: 3, cols: 3,
            dice: [DiceMarker(id: "D1", row: 1, col: 1, label: "B2")],
            pieces: [
                PieceDef(id: "p1", color: .red, rows: [[1, 1, 1], [0, 1, 0]]),
                PieceDef(id: "p2", color: .blue, rows: [[1, 1, 1]]),
            ]
        )
        XCTAssertFalse(PuzzleSolver.isSolvable(level: level))
    }

    func testAllCatalogueLevelsAreSolvable() {
        var unsolvable: [Int] = []
        for level in LevelCatalogue.all {
            if !PuzzleSolver.isSolvable(level: level) {
                unsolvable.append(level.id)
            }
        }
        XCTAssertEqual(unsolvable, [],
                       "Unsolvable levels: \(unsolvable)")
    }

    func testMultipleSolutionsAreAllowed() {
        let level = LevelDef(
            id: 0, name: "Test", subtitle: "",
            rows: 2, cols: 2,
            dice: [],
            pieces: [
                PieceDef(id: "p1", color: .red, rows: [[1, 1]]),
                PieceDef(id: "p2", color: .blue, rows: [[1, 1]]),
            ]
        )
        let count = PuzzleSolver.countSolutions(level: level, max: 5)
        XCTAssertGreaterThan(count, 1, "Should find more than one solution")
    }
}
