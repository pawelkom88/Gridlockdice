import XCTest
@testable import GridlockDice

final class LevelCatalogueTests: XCTestCase {

    func testCatalogueContainsExactlyFiftyOrderedLevels() {
        let catalogue = LevelCatalogue.all
        XCTAssertEqual(catalogue.count, 50)

        let ids = catalogue.map { $0.id }
        XCTAssertEqual(ids, Array(1...50), "Level IDs must be 1 through 50 with no gaps")
    }

    func testFirstFifteenLevelsAreFree() {
        let catalogue = LevelCatalogue.all
        for level in catalogue where level.id <= 15 {
            XCTAssertTrue(level.isFree, "Level \(level.id) should be free")
        }
    }

    func testPaidLevelsStartAtSixteen() {
        let catalogue = LevelCatalogue.all
        for level in catalogue where level.id >= 16 {
            XCTAssertFalse(level.isFree, "Level \(level.id) should be paid")
        }
    }

    func testBoardSizesAreWithinSupportedRange() {
        let catalogue = LevelCatalogue.all
        let allowedSizes: Set<Int> = [4, 5, 6]
        for level in catalogue {
            XCTAssertTrue(allowedSizes.contains(level.rows), "Level \(level.id) rows=\(level.rows) not in 4-6")
            XCTAssertTrue(allowedSizes.contains(level.cols), "Level \(level.id) cols=\(level.cols) not in 4-6")
            XCTAssertEqual(level.rows, level.cols, "Level \(level.id) must be square (rows == cols)")
        }
    }

    func testDiceLabelsMatchCoordinates() {
        let rowLetters = Array("ABCDEF")
        let catalogue = LevelCatalogue.all
        for level in catalogue {
            for dice in level.dice {
                let expectedLabel = "\(rowLetters[dice.row])\(dice.col + 1)"
                XCTAssertEqual(dice.label, expectedLabel,
                               "Level \(level.id) dice at (\(dice.row),\(dice.col)) label '\(dice.label)' should be '\(expectedLabel)'")
            }
        }
    }

    func testBeginnerLevelsDisallowRotation() {
        let catalogue = LevelCatalogue.all
        for level in catalogue where level.id <= 15 {
            XCTAssertFalse(level.allowsRotation,
                           "Level \(level.id) (beginner) should not allow rotation")
        }
    }

    func testLaterLevelsAllowRotation() {
        let catalogue = LevelCatalogue.all
        let rotationStart = 21
        for level in catalogue where level.id >= rotationStart {
            XCTAssertTrue(level.allowsRotation,
                          "Level \(level.id) should allow rotation")
        }
    }

    func testEveryLevelHasPiecesAndDice() {
        let catalogue = LevelCatalogue.all
        for level in catalogue {
            XCTAssertFalse(level.pieces.isEmpty, "Level \(level.id) has no pieces")
            XCTAssertFalse(level.dice.isEmpty, "Level \(level.id) has no dice")
        }
    }

    func testPieceAndDiceTotalCellsMatchBoardSize() {
        let catalogue = LevelCatalogue.all
        var failLevel: String = ""
        for level in catalogue {
            let totalCells = level.rows * level.cols
            let diceCells = level.dice.count
            let pieceCells = level.pieces.reduce(0) { count, piece in
                count + piece.shape.flatMap { $0 }.filter { $0 }.count
            }
            if pieceCells + diceCells != totalCells {
                if failLevel.isEmpty {
                    failLevel = "Level \(level.id): \(pieceCells)pc + \(diceCells)dc = \(pieceCells+diceCells) vs \(totalCells)"
                }
            }
        }
        if !failLevel.isEmpty {
            XCTFail(failLevel)
        }
    }

    func testNoDuplicateLevelIDs() {
        let ids = LevelCatalogue.all.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate level IDs found")
    }
}
